import 'dart:async';
import 'dart:convert';

import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/engine_io/client/engine_io_error.dart';
import 'package:engine_io_client/src/engine_io/client/transport.dart';
import 'package:engine_io_client/src/engine_io/client/transports/polling.dart';
import 'package:engine_io_client/src/engine_io/client/transports/web_socket.dart';
import 'package:engine_io_client/src/engine_io/client/transports/xhr/polling_xhr.dart';
import 'package:engine_io_client/src/engine_io/parser/parser.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/handshake_data.dart';
import 'package:engine_io_client/src/models/packet.dart';
import 'package:engine_io_client/src/models/socket_event.dart';
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:engine_io_client/src/models/socket_state.dart';
import 'package:engine_io_client/src/models/transport_event.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/parse_qs/parse_qs.dart';

class Socket extends Emitter {
  static final Log log = Log('EngineIo.Socket');
  static const String PROBE_ERROR = 'probe error';

  SocketOptions _options;

  String id;
  bool _priorWebSocketSuccess = false;
  bool upgrading = false;

  String readyState;
  Transport transport;
  List<String> upgrades;

  int _pingInterval;
  int _pingTimeout;

  Timer pingTimeoutTimer;
  Timer pingIntervalTimer;

  int _prevBufferLen;
  List<Packet> writeBuffer = <Packet>[];

  Listener onHeartbeatAsListener;

  Socket(this._options) {
    if (_options.host != null) {
      String hostname = _options.host;
      final bool ipv6 = _options.host.split(':').length > 2;
      if (ipv6) {
        final int start = hostname.indexOf('[');
        if (start != -1) hostname = hostname.substring(start + 1);
        final int end = hostname.lastIndexOf(']');
        if (end != -1) hostname = hostname.substring(0, end);
      }
      _options = _options.copyWith(hostname: hostname);
    }

    if (_options.port == -1) {
      // if no port is specified manually, use the protocol default
      _options = _options.copyWith(port: _options.secure ? 443 : 80);
    }

    _options = _options.copyWith(
      query: _options.rawQuery != null ? ParseQS.decode(_options.rawQuery) : <String, String>{},
      path: '${_options.path.replaceAll('/\$', '')}/',
      policyPort: _options.policyPort != 0 ? _options.policyPort : 843,
    );

    onHeartbeatAsListener = (List<dynamic> args) async => _onHeartbeat(args as int ?? -1);
  }

  SocketOptions get options => _options;

  void open() async {
    String transportName;
    if (_options?.rememberUpgrade ?? true && _priorWebSocketSuccess && _options.transports.contains(WebSocket.NAME)) {
      transportName = WebSocket.NAME;
    } else if (_options.transports.isEmpty) {
      await emit(SocketEvent.error, <Error>[EngineIOError('No transports available', null)]);
      return;
    } else {
      transportName = _options.transports[0];
    }
    readyState = SocketState.opening;
    final Transport transport = await _createTransport(transportName);
    _setTransport(transport);
    transport.open();
  }

  Future<Transport> _createTransport(String name) async {
    log.d('creating transport "$name"');

    final Map<String, String> query = Map<String, String>.from(_options.query);
    query['EIO'] = Parser.PROTOCOL.toString();
    query['transport'] = name;
    if (id != null) query['sid'] = id;

    // per-transport options
    final TransportOptions options = _options.transportOptions[name];

    final TransportOptions opts = TransportOptions(
      query: query,
      socket: this,
      hostname: options != null ? options.hostname : _options.hostname,
      port: options != null ? options.port : _options.port,
      secure: options != null ? options.secure : _options.secure,
      path: options != null ? options.path : _options.path,
      timestampRequests: options != null ? options.timestampRequests : _options?.timestampRequests ?? false,
      timestampParam: options != null ? options.timestampParam : _options.timestampParam,
      policyPort: options != null ? options.policyPort : _options.policyPort,
      onRequestHeaders: options != null ? options.onRequestHeaders : _options.onRequestHeaders,
      onResponseHeaders: options != null ? options.onResponseHeaders : _options.onResponseHeaders,
      securityContext: options != null ? options.securityContext : _options.securityContext,
    );

    Transport transport;
    if (name == WebSocket.NAME) {
      transport = WebSocket(opts);
    } else if (name == Polling.NAME) {
      transport = PollingXhr(opts);
    } else {
      throw Exception();
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
      ..on(TransportEvent.packet, (List<dynamic> args) async => await _onPacket(args.isNotEmpty ? args[0] as Packet : null))
      ..on(TransportEvent.error, (List<dynamic> args) async => await _onError(args.isNotEmpty ? args[0] as Error : null))
      ..on(TransportEvent.close, (List<dynamic> args) async => await _onClose('transport close'));
  }

  Future<void> _probe(String name) async {
    log.d('probing transport $name');

    Transport transport = await _createTransport(name);
    bool failed = false;
    _priorWebSocketSuccess = false;

    Function cleanup;

    Future<void> onTransportOpen() async {
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
              final Packet packet = Packet(PacketType.upgrade);
              await transport.send(<Packet>[packet]);
              await emit(SocketEvent.upgrade, <Transport>[transport]);
              //transport = null;
              upgrading = false;
              await _flush();
            });
          }
        } else {
          log.d('probe transport "$name" failed');

          await emit(SocketEvent.upgradeError, <Error>[EngineIOError(transport.name, PROBE_ERROR)]);
        }
      });
      await transport.send(<Packet>[Packet(PacketType.ping, 'probe')]);
    }

    Future<void> freezeTransport() async {
      if (failed) return;
      failed = true;
      cleanup();
      await transport.close();
      transport = null;
    }

    // Handle any error that happens while probing
    Future<void> onError(List<Error> err) async {
      EngineIOError error;
      if (err is Error || err is Exception) {
        error = EngineIOError(transport?.name ?? 'unknown transport', PROBE_ERROR + err.toString());
      } else if (err is String) {
        error = EngineIOError(transport?.name ?? 'unknown transport', 'probe error: $err');
      } else {
        error = EngineIOError(transport?.name ?? 'unknown transport', PROBE_ERROR);
      }

      await freezeTransport();

      log.d('probe transport "$name" failed because of error: "$err"');

      await emit(SocketEvent.upgradeError, <Error>[error]);
    }

    Future<void> onTransportClose() async => await onError(<Error>[StateError('transport closed')]);

    // When the socket is upgraded while we're probing
    Future<void> onUpgrade(Transport to) async {
      if (transport != null && to.name != transport.name) {
        log.d('"${to.name}" works - aborting "${transport.name}"');
        await freezeTransport();
      }
    }

    cleanup = () {
      transport.off(TransportEvent.open, (List<dynamic> args) => onTransportOpen());
      transport.off(TransportEvent.error, (List<dynamic> error) => onError(error as List<Error>));
      transport.off(TransportEvent.close, (List<dynamic> args) => onTransportClose());
      // When the socket is closed while we're probing
      off(SocketEvent.close, (List<dynamic> args) => onError(<Error>[StateError('transport closed')]));
      off(SocketEvent.drain, (List<dynamic> args) => onUpgrade(args[0] as Transport));
    };

    transport.once(TransportEvent.open, (List<dynamic> args) async => await onTransportOpen());
    transport.once(TransportEvent.error, (List<dynamic> error) async => await onError(error as List<Error>));
    transport.once(TransportEvent.close, (List<dynamic> args) async => await onTransportClose());

    // When the socket is closed while we're probing
    once(SocketEvent.close, (List<dynamic> args) async => await onError(<Error>[StateError('transport closed')]));
    once(SocketEvent.upgrading, (List<dynamic> args) async => await onUpgrade(args[0] as Transport));

    await transport.open();
  }

  Future<void> _onOpen() async {
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

  Future<void> _onPacket(Packet packet) async {
    if (readyState == SocketState.opening || readyState == SocketState.open || readyState == SocketState.closing) {
      log.d('socket received: type "${packet.type}", data "${packet.data}"');

      await emit(SocketEvent.packet, <Packet>[packet]);
      await emit(SocketEvent.heartbeat);

      if (packet.type == PacketType.open) {
        await _onHandshake(HandshakeData.fromJson(jsonDecode(packet.data as String) as Map<String, dynamic>));
      } else if (packet.type == PacketType.pong) {
        _setPing();
        await emit(SocketEvent.pong);
      } else if (packet.type == PacketType.error) {
        await _onError(EngineIOError('server error', packet.data));
      } else if (packet.type == PacketType.message) {
        log.d('packet.data ${packet.data}');
        await emit(SocketEvent.message, <dynamic>[packet.data]);
        await emit(SocketEvent.data, <dynamic>[packet.data]);
      }
    } else {
      log.d('packet received with socket readyState "$readyState"');
    }
  }

  Future<void> _onHandshake(HandshakeData data) async {
    await emit(SocketEvent.handshake, <HandshakeData>[data]);
    id = data.sessionId;
    transport.options.updateQuery('sid', data.sessionId);
    upgrades = List<String>.from(data.upgrades.takeWhile((String upgrade) => _options.transports.contains(upgrade)));

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

    pingTimeoutTimer = Timer(Duration(milliseconds: timeout), () async {
      if (readyState != SocketState.closed) await _onClose('ping timeout');
    });
  }

  void _setPing() {
    pingIntervalTimer?.cancel();

    pingIntervalTimer = Timer(Duration(milliseconds: _pingInterval), () async {
      log.d('writing ping packet - expecting pong within $_pingTimeout');
      await _ping();
      _onHeartbeat(_pingTimeout);
    });
  }

  Future<void> _ping() async {
    return await _sendPacket(Packet(PacketType.ping), () async => await emit(SocketEvent.ping));
  }

  Future<void> _onDrain() async {
    writeBuffer.take(_prevBufferLen).toList().forEach(writeBuffer.remove);

    _prevBufferLen = 0;
    if (writeBuffer.isEmpty) {
      await emit(SocketEvent.drain);
    } else {
      await _flush();
    }
  }

  Future<void> _flush() async {
    log.d('flushing ${writeBuffer.length} packets in socket');
    if (readyState != SocketState.closed && transport.writable && !upgrading && writeBuffer.isNotEmpty) {
      log.d('flushing ${writeBuffer.length} packets in socket');

      _prevBufferLen = writeBuffer.length;
      await transport.send(writeBuffer.toList());
      await emit(SocketEvent.flush);
    }
  }

  Future<void> write(dynamic message, [void callback()]) async => await send(message, callback);

  Future<void> send(dynamic message, [void callback()]) async {
    await _sendPacket(Packet(PacketType.message, message), callback);
  }

  Future<void> _sendPacket(Packet packet, void callback()) async {
    log.d('sendPacket: $packet');
    if (readyState == SocketState.closing || readyState == SocketState.closed) return;

    await emit(SocketEvent.packetCreate, <Packet>[packet]);
    writeBuffer.add(packet);
    if (callback != null) once(SocketEvent.flush, (List<dynamic> args) async => callback());
    await _flush();
  }

  void close() async {
    if (readyState == SocketState.opening || readyState == SocketState.open) {
      readyState = SocketState.closing;

      Future<void> close() async {
        await _onClose('forced close');
        log.d('socket closing - telling transport to close');
        await transport.close();
      }

      Future<void> cleanupAndClose() async {
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
  }

  Future<void> _onError(Error error) async {
    log.d('socket error $error');
    _priorWebSocketSuccess = false;
    await emit(SocketEvent.error, <Error>[error]);
    await _onClose('transport error', error);
  }

  Future<void> _onClose(String reason, [dynamic desc]) async {
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
