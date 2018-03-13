import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:flutter_logger/flutter_logger.dart';
import 'package:socket_io/src/emitter/emitter.dart';
import 'package:socket_io/src/engine_io/client/engine_io_exception.dart';
import 'package:socket_io/src/engine_io/client/transport.dart';
import 'package:socket_io/src/engine_io/client/transports/polling.dart';
import 'package:socket_io/src/engine_io/client/transports/web_socket.dart';
import 'package:socket_io/src/engine_io/client/transports/xhr/polling_xhr.dart';
import 'package:socket_io/src/engine_io/parser/parser.dart';
import 'package:socket_io/src/models/handshake_data.dart';
import 'package:socket_io/src/models/packet.dart';
import 'package:socket_io/src/models/packet_type.dart';
import 'package:socket_io/src/models/socket_event.dart';
import 'package:socket_io/src/models/socket_options.dart';
import 'package:socket_io/src/models/socket_state.dart';
import 'package:socket_io/src/models/transport_event.dart';
import 'package:socket_io/src/models/transport_options.dart';
import 'package:socket_io/src/parse_qs/parse_qs.dart';

class Socket extends Emitter {
  static final Log log = new Log('Socket');
  static const String PROBE_ERROR = 'probe error';

  SocketOptions _options;

  String id;
  bool _priorWebSocketSuccess = false;
  bool upgrading = false;

  SocketState _readyState;
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

    onHeartbeatAsListener = (dynamic args) => onHeartbeat(args ?? -1);
  }

  Future<Socket> open() async {
    String transportName;
    if (_options?.rememberUpgrade ?? true && _priorWebSocketSuccess && _options.transports.contains(WebSocket.NAME)) {
      transportName = WebSocket.NAME;
    } else if (_options.transports.isEmpty) {
      emit(SocketEvent.error.name, new EngineIOException('No transports available', null));
      return this;
    } else {
      transportName = _options.transports[0];
    }
    _readyState = SocketState.opening;
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

    emit(SocketEvent.transport.name, transport);
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
        .on(TransportEvent.drain.name, (dynamic args) => onDrain())
        .on(TransportEvent.packet.name, (dynamic args) => onPacket(args))
        .on(TransportEvent.error.name, (dynamic args) => onError(args))
        .on(TransportEvent.close.name, (dynamic args) => onClose('transport close'));
  }

  Future<Null> probe(String name) async {
    log.d('probing transport $name');

    Transport transport = createTransport(name);
    bool failed = false;
    _priorWebSocketSuccess = false;

    Function cleanup;

    void onTransportOpen(dynamic args) {
      if (failed) return;
      log.d('probe transport "$name" opened');

      transport.send(<Packet>[new Packet.values(PacketType.ping, 'probe')]);
      transport.once(TransportEvent.packet.name, (dynamic args) {
        if (failed) return;
        final Packet message = args;
        if (message.type == PacketType.pong && message.data == 'probe') {
          upgrading = true;
          emit(SocketEvent.upgrading.name, transport);
          if (transport == null) return;
          _priorWebSocketSuccess = transport.name == WebSocket.NAME;

          log.d('pausing current transport "${this.transport.name}"');

          if (this.transport is Polling) {
            // ignore: avoid_as
            (this.transport as Polling).pause(() {
              if (failed) return;
              if (_readyState == SocketState.closed) return;

              log.d('changing transport and sending upgrade packet');

              cleanup();

              setTransport(transport);
              final Packet packet = new Packet.values(PacketType.upgrade);
              transport.send(<Packet>[packet]);
              emit(SocketEvent.upgrade.name, transport);
              transport = null;
              upgrading = false;
              flush();
            });
          }
        } else {
          log.d('probe transport "$name" failed');

          emit(SocketEvent.upgradeError.name, new EngineIOException(transport.name, PROBE_ERROR));
        }
      });
    }

    void freezeTransport(dynamic args) {
      if (failed) return;
      failed = true;
      cleanup();
      transport.close();
      transport = null;
    }

    // Handle any error that happens while probing
    void onError(dynamic err) {
      EngineIOException error;
      if (err is Exception) {
        error = new EngineIOException(transport.name, PROBE_ERROR + err.toString());
      } else if (err is String) {
        error = new EngineIOException(transport.name, 'probe error: $err');
      } else {
        error = new EngineIOException(transport.name, PROBE_ERROR);
      }

      freezeTransport(null);

      log.d('probe transport "$name" failed because of error: "$err"');

      emit(SocketEvent.upgradeError.name, error);
    }

    void onTransportClose(dynamic args) => onError.call('transport closed');

    // When the socket is closed while we're probing
    void onClose(dynamic args) => onError.call('socket closed');

    // When the socket is upgraded while we're probing
    void onUpgrade(dynamic to) {
      if (transport != null && to.name != transport.name) {
        log.d('"${to.name}" works - aborting "${transport.name}"');
        freezeTransport(null);
      }
    }

    cleanup = () {
      transport.off(TransportEvent.open.name, onTransportOpen);
      transport.off(TransportEvent.error.name, onError);
      transport.off(TransportEvent.close.name, onTransportClose);
      off(SocketEvent.close.name, onClose);
      off(SocketEvent.drain.name, onUpgrade);
    };

    transport.once(TransportEvent.open.name, onTransportOpen);
    transport.once(TransportEvent.error.name, onError);
    transport.once(TransportEvent.close.name, onTransportClose);

    once(SocketEvent.close.name, onClose);
    once(SocketEvent.upgrading.name, onUpgrade);

    await transport.open();
  }

  void onOpen() {
    log.d('socket open');
    _readyState = SocketState.open;
    _priorWebSocketSuccess = transport.name == WebSocket.NAME;
    emit(SocketEvent.open.name);
    flush();

    if (_readyState == SocketState.open && _options.upgrade && transport is Polling) {
      log.d('starting upgrade probes: $upgrades');
      // ignore: prefer_foreach
      for (String upgrade in upgrades) {
        probe(upgrade);
      }
    }
  }

  void onPacket(Packet packet) {
    if (_readyState == SocketState.opening || _readyState == SocketState.open || _readyState == SocketState.closing) {
      log.d('socket received: type "${packet.type}", data "${packet.data}"');

      emit(SocketEvent.packet.name, packet);
      emit(SocketEvent.heartbeat.name);

      if (packet.type == PacketType.open) {
        onHandshake(new HandshakeData.fromJson(packet.data));
      } else if (packet.type == PacketType.pong) {
        setPing();
        emit(SocketEvent.pong.name);
      } else if (packet.type == PacketType.error) {
        onError(new EngineIOException('server error', packet.data));
      } else if (packet.type == PacketType.message) {
        emit(SocketEvent.data.name, packet.data);
        emit(SocketEvent.message.name, packet.data);
      }
    } else {
      log.d('packet received with socket readyState "$_readyState"');
    }
  }

  void onHandshake(HandshakeData data) {
    emit(SocketEvent.handshake.name, data);
    id = data.socketId;
    transport.options = (transport.options.toBuilder()..query['sid'] = data.socketId).build();

    upgrades = new BuiltList<String>(data.upgrades.takeWhile((upgrade) => _options.transports.contains(upgrade)));

    _pingInterval = data.pingInterval;
    _pingTimeout = data.pingTimeout;
    onOpen();

    // In case open handler closes socket
    if (_readyState == SocketState.closed) return;
    setPing();

    off(SocketEvent.heartbeat.name, onHeartbeatAsListener);
    on(SocketEvent.heartbeat.name, onHeartbeatAsListener);
  }

  void onHeartbeat(int timeout) {
    pingTimeoutTimer?.cancel();
    if (timeout <= 0) timeout = _pingInterval + _pingTimeout;

    pingTimeoutTimer = new Timer(new Duration(milliseconds: timeout), () {
      if (_readyState != SocketState.closed) onClose('ping timeout');
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

  void onDrain() {
    writeBuffer.take(_prevBufferLen).toList().forEach(writeBuffer.remove);

    _prevBufferLen = 0;
    if (writeBuffer.isEmpty) {
      emit(SocketEvent.drain.name);
    } else {
      flush();
    }
  }

  void flush() {
    if (_readyState != SocketState.closed && transport.writable && !upgrading && writeBuffer.isNotEmpty) {
      log.d('flushing ${writeBuffer.length} packets in socket');

      _prevBufferLen = writeBuffer.length;
      transport.send(writeBuffer.toList());
      emit(SocketEvent.flush.name);
    }
  }

  void write(dynamic message, void callback()) => send(message, callback);

  void send(dynamic message, [void callback()]) => sendPacket(new Packet.values(PacketType.message, message), callback);

  void sendPacket(Packet packet, void callback()) {
    log.d('sendPacket: $packet');
    if (_readyState == SocketState.closing || _readyState == SocketState.closed) return;
    log.d('sendPacket: $packet');

    emit(SocketEvent.packetCreate.name, packet);
    writeBuffer.insert(0, packet);
    if (callback != null) once(SocketEvent.flush.name, (dynamic args) => callback());
    flush();
  }

  Future<Socket> close() async {
    if (_readyState == SocketState.opening || _readyState == SocketState.open) {
      _readyState = SocketState.closing;

      void close() {
        onClose('forced close');
        log.d('socket closing - telling transport to close');
        transport.close();
      }

      void cleanupAndClose(dynamic args) {
        off(SocketEvent.upgrade.name, cleanupAndClose);
        off(SocketEvent.upgradeError.name, cleanupAndClose);
        close();
      }

      void waitForUpgrade() {
        // wait for update to finish since we can't send packets while pausing a transport
        once(SocketEvent.upgrade.name, cleanupAndClose);
        once(SocketEvent.upgradeError.name, cleanupAndClose);
      }

      if (writeBuffer.isNotEmpty) {
        once(SocketEvent.drain.name, (dynamic args) {
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

  void onError(dynamic error) {
    log.d('socket error $error');
    _priorWebSocketSuccess = false;
    emit(SocketEvent.error.name, error);
    onClose('transport error', error);
  }

  Future<Null> onClose(String reason, [dynamic desc]) async {
    if (_readyState == SocketState.opening || _readyState == SocketState.open || _readyState == SocketState.closing) {
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
      _readyState = SocketState.closed;

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
    log.d('filterUpgrades: $upgrades');
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
        ' _readyState: $_readyState,\n'
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
