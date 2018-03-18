import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/engine_io/client/engine_io_exception.dart';
import 'package:engine_io_client/src/engine_io/client/transport.dart';
import 'package:engine_io_client/src/engine_io/client/transports/polling.dart';
import 'package:engine_io_client/src/engine_io/client/transports/web_socket.dart';
import 'package:engine_io_client/src/engine_io/client/transports/xhr/polling_xhr.dart';
import 'package:engine_io_client/src/engine_io/parser/parser.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/handshake_data.dart';
import 'package:engine_io_client/src/models/packet.dart';
import 'package:engine_io_client/src/models/packet_type.dart';
import 'package:engine_io_client/src/models/socket_event.dart';
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:engine_io_client/src/models/socket_state.dart';
import 'package:engine_io_client/src/models/transport_event.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/parse_qs/parse_qs.dart';

class Socket extends Emitter {
  static final Log log = new Log('EngineIo.Socket');
  static const String PROBE_ERROR = 'probe error';

  SocketOptions _options;

  String id;
  bool _priorWebSocketSuccess = false;
  bool upgrading = false;

  SocketState readyState;
  Transport transport;
  BuiltList<String> upgrades;

  int _pingInterval;
  int _pingTimeout;

  Timer pingTimeoutTimer;
  Timer pingIntervalTimer;

  int _prevBufferLen;
  List<Packet> writeBuffer = <Packet>[];

  Listener onHeartbeatAsListener;

  Socket(this._options) {
    final SocketOptionsBuilder builder = _options.toBuilder();
    if (_options.host != null) {
      String hostname = _options.host;
      final bool ipv6 = _options.host.split(':').length > 2;
      if (ipv6) {
        final int start = hostname.indexOf('[');
        if (start != -1) hostname = hostname.substring(start + 1);
        final int end = hostname.lastIndexOf(']');
        if (end != -1) hostname = hostname.substring(0, end);
      }
      builder.hostname = hostname;
    }

    if (_options.port == -1) {
      // if no port is specified manually, use the protocol default
      builder.port = _options.secure ? 443 : 80;
    }

    builder.query = _options.rawQuery != null ? ParseQS.decode(_options.rawQuery) : new MapBuilder<String, String>();
    builder.path = '${_options.path.replaceAll('/\$', '')}/';
    builder.policyPort = _options.policyPort != 0 ? _options.policyPort : 843;
    _options = builder.build();

    onHeartbeatAsListener = (List<dynamic> args) => onHeartbeat(args ?? -1);
  }

  SocketOptions get options => _options;

  Future<Socket> open() async {
    String transportName;
    if (_options?.rememberUpgrade ?? true && _priorWebSocketSuccess && _options.transports.contains(WebSocket.NAME)) {
      transportName = WebSocket.NAME;
    } else if (_options.transports.isEmpty) {
      emit(SocketEvent.error.name, <Error>[new EngineIOException('No transports available', null)]);
      return this;
    } else {
      transportName = _options.transports[0];
    }
    readyState = SocketState.opening;
    final Transport transport = createTransport(transportName);
    setTransport(transport);
    await transport.open();

    return this;
  }

  Transport createTransport(String name) {
    log.d('creating transport "$name"');

    final MapBuilder<String, String> query = _options.query.toBuilder();
    query['EIO'] = Parser.PROTOCOL.toString();
    query['transport'] = name;
    if (id != null) query['sid'] = id;

    // per-transport options
    final TransportOptions options = _options.transportOptions[name];

    final TransportOptions opts = new TransportOptions((TransportOptionsBuilder b) {
      b
        ..query = query
        ..socket = this
        ..hostname = options != null ? options.hostname : _options.hostname
        ..port = options != null ? options.port : _options.port
        ..secure = options != null ? options.secure : _options.secure
        ..path = options != null ? options.path : _options.path
        ..timestampRequests = options != null ? options.timestampRequests : _options?.timestampRequests ?? false
        ..timestampParam = options != null ? options.timestampParam : _options.timestampParam
        ..policyPort = options != null ? options.policyPort : _options.policyPort;
    });

    Transport transport;
    if (name == WebSocket.NAME) {
      transport = new WebSocket(opts);
    } else if (name == Polling.NAME) {
      transport = new PollingXhr(opts);
    } else {
      throw new Exception();
    }

    emit(SocketEvent.transport.name, <Transport>[transport]);
    return transport;
  }

  void setTransport(Transport transport) {
    log.d('setting transport ${transport.name}');

    if (this.transport != null) {
      log.d('clearing existing transport ${transport.name}');

      this.transport.off();
    }

    this.transport = transport;

    transport
      ..on(TransportEvent.drain.name, (List<dynamic> args) => onDrain())
      ..on(TransportEvent.packet.name, (List<dynamic> args) => onPacket(args.isNotEmpty ? args[0] : null))
      ..on(TransportEvent.error.name, (List<dynamic> args) => onError(args.isNotEmpty ? args[0] : null))
      ..on(TransportEvent.close.name, (List<dynamic> args) => onClose('transport close'));
  }

  Future<Null> probe(String name) async {
    log.d('probing transport $name');

    Transport transport = createTransport(name);
    bool failed = false;
    _priorWebSocketSuccess = false;

    Function cleanup;

    void onTransportOpen() {
      if (failed) return;
      log.d('probe transport "$name" opened');

      transport.send(<Packet>[new Packet.values(PacketType.ping, 'probe')]);
      transport.once(TransportEvent.packet.name, (List<dynamic> args) async {
        if (failed) return;
        final Packet message = args[0];
        if (message.type == PacketType.pong && message.data == 'probe') {
          upgrading = true;
          emit(SocketEvent.upgrading.name, <Transport>[transport]);
          if (transport == null) return;
          _priorWebSocketSuccess = transport.name == WebSocket.NAME;

          log.d('pausing current transport "${this.transport.name}"');

          if (this.transport is Polling) {
            // ignore: avoid_as
            await (this.transport as Polling).pause(() async {
              if (failed) return;
              if (readyState == SocketState.closed) return;

              log.d('changing transport and sending upgrade packet');

              cleanup();

              setTransport(transport);
              final Packet packet = new Packet.values(PacketType.upgrade);
              transport.send(<Packet>[packet]);
              emit(SocketEvent.upgrade.name, <Transport>[transport]);
              transport = null;
              upgrading = false;
              await flush();
            });
          }
        } else {
          log.d('probe transport "$name" failed');

          emit(SocketEvent.upgradeError.name, <Error>[new EngineIOException(transport.name, PROBE_ERROR)]);
        }
      });
    }

    void freezeTransport() {
      if (failed) return;
      failed = true;
      cleanup();
      transport.close();
      transport = null;
    }

    // Handle any error that happens while probing
    void onError(List<Error> err) {
      EngineIOException error;
      if (err is Exception) {
        error = new EngineIOException(transport.name, PROBE_ERROR + err.toString());
      } else if (err is String) {
        error = new EngineIOException(transport.name, 'probe error: $err');
      } else {
        error = new EngineIOException(transport.name, PROBE_ERROR);
      }

      freezeTransport();

      log.d('probe transport "$name" failed because of error: "$err"');

      emit(SocketEvent.upgradeError.name, <Error>[error]);
    }

    void onTransportClose() => onError(<Error>[new StateError('transport closed')]);

    // When the socket is upgraded while we're probing
    void onUpgrade(Transport to) {
      if (transport != null && to.name != transport.name) {
        log.d('"${to.name}" works - aborting "${transport.name}"');
        freezeTransport();
      }
    }

    cleanup = () {
      transport.off(TransportEvent.open.name, (List<dynamic> args) => onTransportOpen());
      transport.off(TransportEvent.error.name, (List<dynamic> error) => onError(error));
      transport.off(TransportEvent.close.name, (List<dynamic> args) => onTransportClose());
      // When the socket is closed while we're probing
      off(SocketEvent.close.name, (List<dynamic> args) => onError(<Error>[new StateError('transport closed')]));
      off(SocketEvent.drain.name, (List<dynamic> args) => onUpgrade(args[0]));
    };

    transport.once(TransportEvent.open.name, (List<dynamic> args) => onTransportOpen());
    transport.once(TransportEvent.error.name, (List<dynamic> error) => onError(error));
    transport.once(TransportEvent.close.name, (List<dynamic> args) => onTransportClose());

    // When the socket is closed while we're probing
    once(SocketEvent.close.name, (List<dynamic> args) => onError(<Error>[new StateError('transport closed')]));
    once(SocketEvent.upgrading.name, (List<dynamic> args) => onUpgrade(args[0]));

    await transport.open();
  }

  Future<Null> onOpen() async {
    log.d('socket open');
    readyState = SocketState.open;
    _priorWebSocketSuccess = transport.name == WebSocket.NAME;
    emit(SocketEvent.open.name);
    await flush();

    if (readyState == SocketState.open && _options.upgrade && transport is Polling) {
      log.d('starting upgrade probes: $upgrades');
      // ignore: prefer_foreach
      for (String upgrade in upgrades) {
        probe(upgrade);
      }
    }
  }

  void onPacket(Packet packet) {
    if (readyState == SocketState.opening || readyState == SocketState.open || readyState == SocketState.closing) {
      log.d('socket received: type "${packet.type}", data "${packet.data}"');

      emit(SocketEvent.packet.name, <Packet>[packet]);
      emit(SocketEvent.heartbeat.name);

      if (packet.type == PacketType.open) {
        onHandshake(new HandshakeData.fromJson(packet.data));
      } else if (packet.type == PacketType.pong) {
        setPing();
        emit(SocketEvent.pong.name);
      } else if (packet.type == PacketType.error) {
        onError(new EngineIOException('server error', packet.data));
      } else if (packet.type == PacketType.message) {
        log.d('packet.data ${packet.data}');
        emit(SocketEvent.message.name, <dynamic>[packet.data]);
        emit(SocketEvent.data.name, <dynamic>[packet.data]);
      }
    } else {
      log.d('packet received with socket readyState "$readyState"');
    }
  }

  void onHandshake(HandshakeData data) {
    emit(SocketEvent.handshake.name, <HandshakeData>[data]);
    id = data.sessionId;
    transport.options = (transport.options.toBuilder()..query['sid'] = data.sessionId).build();

    upgrades = new BuiltList<String>(data.upgrades.takeWhile((String upgrade) => _options.transports.contains(upgrade)));

    _pingInterval = data.pingInterval;
    _pingTimeout = data.pingTimeout;
    onOpen();

    // In case open handler closes socket
    if (readyState == SocketState.closed) return;
    setPing();

    off(SocketEvent.heartbeat.name, onHeartbeatAsListener);
    on(SocketEvent.heartbeat.name, onHeartbeatAsListener);
  }

  void onHeartbeat(int timeout) {
    pingTimeoutTimer?.cancel();
    if (timeout <= 0) timeout = _pingInterval + _pingTimeout;

    pingTimeoutTimer = new Timer(new Duration(milliseconds: timeout), () {
      if (readyState != SocketState.closed) onClose('ping timeout');
    });
  }

  void setPing() {
    pingIntervalTimer?.cancel();

    pingIntervalTimer = new Timer(new Duration(milliseconds: _pingInterval), () {
      log.d('writing ping packet - expecting pong within $_pingTimeout');
      ping();
      onHeartbeat(_pingTimeout);
    });
  }

  void ping() => sendPacket(new Packet.values(PacketType.ping), () => emit(SocketEvent.ping.name));

  Future<Null> onDrain() async {
    writeBuffer.take(_prevBufferLen).toList().forEach(writeBuffer.remove);

    _prevBufferLen = 0;
    if (writeBuffer.isEmpty) {
      emit(SocketEvent.drain.name);
    } else {
      await flush();
    }
  }

  Future<Null> flush() async {
    log.d('flushing ${writeBuffer.length} packets in socket');
    if (readyState != SocketState.closed && transport.writable && !upgrading && writeBuffer.isNotEmpty) {
      log.d('flushing ${writeBuffer.length} packets in socket');

      _prevBufferLen = writeBuffer.length;
      await transport.send(writeBuffer.toList());
      emit(SocketEvent.flush.name);
    }
  }

  Future<Null> write(dynamic message, [void callback()]) async => send(message, callback);

  Future<Null> send(dynamic message, [void callback()]) async {
    await sendPacket(new Packet.values(PacketType.message, message), callback);
  }

  Future<Null> sendPacket(Packet packet, void callback()) async {
    log.d('sendPacket: $packet');
    if (readyState == SocketState.closing || readyState == SocketState.closed) return;

    emit(SocketEvent.packetCreate.name, <Packet>[packet]);
    writeBuffer.add(packet);
    if (callback != null) once(SocketEvent.flush.name, (List<dynamic> args) => callback());
    await flush();
  }

  Future<Socket> close() async {
    if (readyState == SocketState.opening || readyState == SocketState.open) {
      readyState = SocketState.closing;

      void close() {
        onClose('forced close');
        log.d('socket closing - telling transport to close');
        transport.close();
      }

      void cleanupAndClose() {
        off(SocketEvent.upgrade.name, (List<dynamic> args) => cleanupAndClose());
        off(SocketEvent.upgradeError.name, (List<dynamic> args) => cleanupAndClose());
        close();
      }

      void waitForUpgrade() {
        // wait for update to finish since we can't send packets while pausing a transport
        once(SocketEvent.upgrade.name, (List<dynamic> args) => cleanupAndClose());
        once(SocketEvent.upgradeError.name, (List<dynamic> args) => cleanupAndClose());
      }

      if (writeBuffer.isNotEmpty) {
        once(SocketEvent.drain.name, (List<dynamic> args) {
          if (upgrading) {
            waitForUpgrade();
          } else {
            close();
          }
        });
      } else if (upgrading) {
        waitForUpgrade();
      } else {
        close();
      }
    }

    return this;
  }

  void onError(Error error) {
    log.d('socket error $error');
    _priorWebSocketSuccess = false;
    emit(SocketEvent.error.name, <Error>[error]);
    onClose('transport error', error);
  }

  Future<Null> onClose(String reason, [dynamic desc]) async {
    if (readyState == SocketState.opening || readyState == SocketState.open || readyState == SocketState.closing) {
      log.d('socket close with reason: $reason');

      // clear timers
      pingIntervalTimer?.cancel();
      pingTimeoutTimer?.cancel();

      // stop event from firing again for transport
      transport.off(SocketEvent.close.name);

      // ensure transport won't stay open
      await transport.close();

      // ignore further transport communication
      transport.off();

      // set ready state
      readyState = SocketState.closed;

      // clear session id
      id = null;

      // emit close events
      emit(SocketEvent.close.name, <dynamic>[reason, desc]);

      // clear buffers after, so users can still
      // grab the buffers on `close` event

      writeBuffer.clear();
      _prevBufferLen = 0;
    }
  }

  BuiltList<String> filterUpgrades(BuiltList<String> upgrades) {
    final ListBuilder<String> filteredUpgrades = new ListBuilder<String>();
    for (String upgrade in upgrades) {
      if (_options.transports.contains(upgrade)) {
        filteredUpgrades.add(upgrade);
      }
    }

    return filteredUpgrades.build();
  }

  @override
  String toString() {
    return 'Socket{_options: $_options,'
        ' id: $id, _priorWebSocketSuccess: $_priorWebSocketSuccess,\n'
        ' upgrading: $upgrading,\n'
        ' _readyState: $readyState,\n'
        ' transport: $transport,\n'
        ' upgrades: $upgrades,\n'
        ' _pingInterval: $_pingInterval,\n'
        ' _pingTimeout: $_pingTimeout,\n'
        ' pingTimeoutTimer: $pingTimeoutTimer,\n'
        ' pingIntervalTimer: $pingIntervalTimer,\n'
        ' _prevBufferLen: $_prevBufferLen,\n'
        ' writeBuffer: $writeBuffer,\n'
        ' onHeartbeatAsListener: $onHeartbeatAsListener}\n';
  }
}
