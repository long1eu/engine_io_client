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

  String readyState;
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

    onHeartbeatAsListener = (List<dynamic> args) async => _onHeartbeat(args ?? -1);
  }

  SocketOptions get options => _options;

  Future<Null> open() async {
    String transportName;
    if (_options?.rememberUpgrade ?? true && _priorWebSocketSuccess && _options.transports.contains(WebSocket.NAME)) {
      transportName = WebSocket.NAME;
    } else if (_options.transports.isEmpty) {
      await emit(SocketEvent.error, <Error>[new EngineIOException('No transports available', null)]);
      return this;
    } else {
      transportName = _options.transports[0];
    }
    readyState = SocketState.opening;
    final Transport transport = await _createTransport(transportName);
    _setTransport(transport);
    await transport.open();
  }

  Future<Transport> _createTransport(String name) async {
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
        ..policyPort = options != null ? options.policyPort : _options.policyPort
        ..securityContext = options != null ? options.securityContext : _options.securityContext;
    });

    Transport transport;
    if (name == WebSocket.NAME) {
      transport = new WebSocket(opts);
    } else if (name == Polling.NAME) {
      transport = new PollingXhr(opts);
    } else {
      throw new Exception();
    }

    await emit(SocketEvent.transport, <Transport>[transport]);
    return transport;
  }

  void _setTransport(Transport transport) {
    log.d('setting transport ${transport.name}');

    if (this.transport != null) {
      log.d('clearing existing transport ${transport.name}');

      this.transport.off();
    }

    this.transport = transport;

    transport
      ..on(TransportEvent.drain, (List<dynamic> args) async => await _onDrain())
      ..on(TransportEvent.packet, (List<dynamic> args) async => await _onPacket(args.isNotEmpty ? args[0] : null))
      ..on(TransportEvent.error, (List<dynamic> args) async => await _onError(args.isNotEmpty ? args[0] : null))
      ..on(TransportEvent.close, (List<dynamic> args) async => await _onClose('transport close'));
  }

  Future<Null> _probe(String name) async {
    log.d('probing transport $name');

    Transport transport = await _createTransport(name);
    bool failed = false;
    _priorWebSocketSuccess = false;

    Function cleanup;

    Future<Null> onTransportOpen() async {
      if (failed) return;
      log.d('probe transport "$name" opened');

      transport.once(TransportEvent.packet, (List<dynamic> args) async {
        if (failed) return;
        final Packet message = args[0];
        if (message.type == PacketType.pong && message.data == 'probe') {
          log.d('probe transport \'$name\' pong');
          upgrading = true;
          await emit(SocketEvent.upgrading, <Transport>[transport]);
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

              _setTransport(transport);
              final Packet packet = new Packet.values(PacketType.upgrade);
              await transport.send(<Packet>[packet]);
              await emit(SocketEvent.upgrade, <Transport>[transport]);
              //transport = null;
              upgrading = false;
              await _flush();
            });
          }
        } else {
          log.d('probe transport "$name" failed');

          await emit(SocketEvent.upgradeError, <Error>[new EngineIOException(transport.name, PROBE_ERROR)]);
        }
      });
      await transport.send(<Packet>[new Packet.values(PacketType.ping, 'probe')]);
    }

    Future<Null> freezeTransport() async {
      if (failed) return;
      failed = true;
      cleanup();
      await transport.close();
      transport = null;
    }

    // Handle any error that happens while probing
    Future<Null> onError(List<Error> err) async {
      EngineIOException error;
      if (err is Exception) {
        error = new EngineIOException(transport?.name ?? 'unknown transport', PROBE_ERROR + err.toString());
      } else if (err is String) {
        error = new EngineIOException(transport?.name ?? 'unknown transport', 'probe error: $err');
      } else {
        error = new EngineIOException(transport?.name ?? 'unknown transport', PROBE_ERROR);
      }

      await freezeTransport();

      log.d('probe transport "$name" failed because of error: "$err"');

      await emit(SocketEvent.upgradeError, <Error>[error]);
    }

    Future<Null> onTransportClose() async => await onError(<Error>[new StateError('transport closed')]);

    // When the socket is upgraded while we're probing
    Future<Null> onUpgrade(Transport to) async {
      if (transport != null && to.name != transport.name) {
        log.d('"${to.name}" works - aborting "${transport.name}"');
        await freezeTransport();
      }
    }

    cleanup = () {
      transport.off(TransportEvent.open, (List<dynamic> args) => onTransportOpen());
      transport.off(TransportEvent.error, (List<dynamic> error) => onError(error));
      transport.off(TransportEvent.close, (List<dynamic> args) => onTransportClose());
      // When the socket is closed while we're probing
      off(SocketEvent.close, (List<dynamic> args) => onError(<Error>[new StateError('transport closed')]));
      off(SocketEvent.drain, (List<dynamic> args) => onUpgrade(args[0]));
    };

    transport.once(TransportEvent.open, (List<dynamic> args) async => await onTransportOpen());
    transport.once(TransportEvent.error, (List<dynamic> error) async => await onError(error));
    transport.once(TransportEvent.close, (List<dynamic> args) async => await onTransportClose());

    // When the socket is closed while we're probing
    once(SocketEvent.close, (List<dynamic> args) async => await onError(<Error>[new StateError('transport closed')]));
    once(SocketEvent.upgrading, (List<dynamic> args) async => await onUpgrade(args[0]));

    await transport.open();
  }

  Future<Null> _onOpen() async {
    log.d('socket open');
    readyState = SocketState.open;
    _priorWebSocketSuccess = transport.name == WebSocket.NAME;
    await emit(SocketEvent.open);
    await _flush();

    if (readyState == SocketState.open && _options.upgrade && transport is Polling) {
      log.d('starting upgrade probes: $upgrades');
      // ignore: prefer_foreach
      for (String upgrade in upgrades) {
        await _probe(upgrade);
      }
    }
  }

  Future<Null> _onPacket(Packet packet) async {
    if (readyState == SocketState.opening || readyState == SocketState.open || readyState == SocketState.closing) {
      log.d('socket received: type "${packet.type}", data "${packet.data}"');

      await emit(SocketEvent.packet, <Packet>[packet]);
      await emit(SocketEvent.heartbeat);

      if (packet.type == PacketType.open) {
        await _onHandshake(new HandshakeData.fromJson(packet.data));
      } else if (packet.type == PacketType.pong) {
        _setPing();
        await emit(SocketEvent.pong);
      } else if (packet.type == PacketType.error) {
        await _onError(new EngineIOException('server error', packet.data));
      } else if (packet.type == PacketType.message) {
        log.d('packet.data ${packet.data}');
        await emit(SocketEvent.message, <dynamic>[packet.data]);
        await emit(SocketEvent.data, <dynamic>[packet.data]);
      }
    } else {
      log.d('packet received with socket readyState "$readyState"');
    }
  }

  Future<Null> _onHandshake(HandshakeData data) async {
    await emit(SocketEvent.handshake, <HandshakeData>[data]);
    id = data.sessionId;
    transport.options = (transport.options.toBuilder()..query['sid'] = data.sessionId).build();

    upgrades = new BuiltList<String>(data.upgrades.takeWhile((String upgrade) => _options.transports.contains(upgrade)));

    _pingInterval = data.pingInterval;
    _pingTimeout = data.pingTimeout;
    await _onOpen();

    // In case open handler closes socket
    if (readyState == SocketState.closed) return;
    _setPing();

    off(SocketEvent.heartbeat, onHeartbeatAsListener);
    on(SocketEvent.heartbeat, onHeartbeatAsListener);
  }

  void _onHeartbeat(int timeout) {
    pingTimeoutTimer?.cancel();
    if (timeout <= 0) timeout = _pingInterval + _pingTimeout;

    pingTimeoutTimer = new Timer(new Duration(milliseconds: timeout), () async {
      if (readyState != SocketState.closed) await _onClose('ping timeout');
    });
  }

  void _setPing() {
    pingIntervalTimer?.cancel();

    pingIntervalTimer = new Timer(new Duration(milliseconds: _pingInterval), () async {
      log.d('writing ping packet - expecting pong within $_pingTimeout');
      await _ping();
      _onHeartbeat(_pingTimeout);
    });
  }

  Future<Null> _ping() async {
    return await _sendPacket(new Packet.values(PacketType.ping), () async => await emit(SocketEvent.ping));
  }

  Future<Null> _onDrain() async {
    writeBuffer.take(_prevBufferLen).toList().forEach(writeBuffer.remove);

    _prevBufferLen = 0;
    if (writeBuffer.isEmpty) {
      await emit(SocketEvent.drain);
    } else {
      await _flush();
    }
  }

  Future<Null> _flush() async {
    log.d('flushing ${writeBuffer.length} packets in socket');
    if (readyState != SocketState.closed && transport.writable && !upgrading && writeBuffer.isNotEmpty) {
      log.d('flushing ${writeBuffer.length} packets in socket');

      _prevBufferLen = writeBuffer.length;
      await transport.send(writeBuffer.toList());
      await emit(SocketEvent.flush);
    }
  }

  Future<Null> write(dynamic message, [void callback()]) async => await send(message, callback);

  Future<Null> send(dynamic message, [void callback()]) async {
    await _sendPacket(new Packet.values(PacketType.message, message), callback);
  }

  Future<Null> _sendPacket(Packet packet, void callback()) async {
    log.d('sendPacket: $packet');
    if (readyState == SocketState.closing || readyState == SocketState.closed) return;

    await emit(SocketEvent.packetCreate, <Packet>[packet]);
    writeBuffer.add(packet);
    if (callback != null) once(SocketEvent.flush, (List<dynamic> args) async => callback());
    await _flush();
  }

  Future<Socket> close() async {
    if (readyState == SocketState.opening || readyState == SocketState.open) {
      readyState = SocketState.closing;

      Future<Null> close() async {
        await _onClose('forced close');
        log.d('socket closing - telling transport to close');
        await transport.close();
      }

      Future<Null> cleanupAndClose() async {
        off(SocketEvent.upgrade, (List<dynamic> args) async => await cleanupAndClose());
        off(SocketEvent.upgradeError, (List<dynamic> args) async => await cleanupAndClose());
        await close();
      }

      void waitForUpgrade() {
        // wait for update to finish since we can't send packets while pausing a transport
        once(SocketEvent.upgrade, (List<dynamic> args) async => await cleanupAndClose());
        once(SocketEvent.upgradeError, (List<dynamic> args) async => await cleanupAndClose());
      }

      if (writeBuffer.isNotEmpty) {
        once(SocketEvent.drain, (List<dynamic> args) async {
          if (upgrading) {
            waitForUpgrade();
          } else {
            await close();
          }
        });
      } else if (upgrading) {
        waitForUpgrade();
      } else {
        await close();
      }
    }

    return this;
  }

  Future<Null> _onError(Error error) async {
    log.d('socket error $error');
    _priorWebSocketSuccess = false;
    await emit(SocketEvent.error, <Error>[error]);
    await _onClose('transport error', error);
  }

  Future<Null> _onClose(String reason, [dynamic desc]) async {
    if (readyState == SocketState.opening || readyState == SocketState.open || readyState == SocketState.closing) {
      log.d('socket close with reason: $reason');

      // clear timers
      pingIntervalTimer?.cancel();
      pingTimeoutTimer?.cancel();

      // stop event from firing again for transport
      transport.off(SocketEvent.close);

      // ensure transport won't stay open
      await transport.close();

      // ignore further transport communication
      transport.off();

      // set ready state
      readyState = SocketState.closed;

      // clear session id
      id = null;

      // emit close events
      await emit(SocketEvent.close, <dynamic>[reason, desc]);

      // clear buffers after, so users can still
      // grab the buffers on `close` event

      writeBuffer.clear();
      _prevBufferLen = 0;
    }
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
