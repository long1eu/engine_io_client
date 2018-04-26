import 'dart:async';

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
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/parse_qs/parse_qs.dart';

class Socket extends Emitter {
  static final Log log = new Log('EngineIo.Socket');
  static const String PROBE_ERROR = 'probe error';

  static const String eventOpen = 'open';
  static const String eventClose = 'close';
  static const String eventMessage = 'message';
  static const String eventError = 'error';
  static const String eventUpgradeError = 'upgradeError';
  static const String eventFlush = 'flush';
  static const String eventDrain = 'drain';
  static const String eventHandshake = 'handshake';
  static const String eventUpgrading = 'upgrading';
  static const String eventUpgrade = 'upgrade';
  static const String eventPacket = 'packet';
  static const String eventPacketCreate = 'packetCreate';
  static const String eventHeartbeat = 'heartbeat';
  static const String eventData = 'data';
  static const String eventPing = 'ping';
  static const String eventPong = 'pong';
  static const String eventTransport = 'transport';

  static const String stateOpening = 'opening';
  static const String stateOpen = 'open';
  static const String stateClosing = 'closing';
  static const String stateClosed = 'closed';

  SocketOptions _options;

  String id;
  bool _priorWebSocketSuccess = false;
  bool _upgrading = false;

  String readyState;
  Transport transport;
  List<String> upgrades;

  int _pingInterval;
  int _pingTimeout;

  Timer pingTimeoutTimer;
  Timer pingIntervalTimer;

  int _prevBufferLen;
  List<Packet<dynamic>> writeBuffer = <Packet<dynamic>>[];

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

    _options = _options.copyWith(
        port: _options.port != -1 ? _options.port : _options.secure ? 443 : 80,
        query: _options.rawQuery != null ? ParseQS.decode(_options.rawQuery) : <String, String>{},
        path: '${_options.path.replaceAll('/\$', '')}/',
        policyPort: _options.policyPort != 0 ? _options.policyPort : 843);

    onHeartbeatAsListener = (List<dynamic> args) async => _onHeartbeat(args ?? -1);
  }

  SocketOptions get options => _options;

  Future<Null> open() async {
    String transportName;
    if (_options?.rememberUpgrade ?? true && _priorWebSocketSuccess && _options.transports.contains(WebSocket.NAME)) {
      transportName = WebSocket.NAME;
    } else if (_options.transports.isEmpty) {
      await emit(eventError, <Error>[new EngineIOError('No transports available', null)]);
      return this;
    } else {
      transportName = _options.transports[0];
    }
    readyState = stateOpening;
    final Transport transport = await _createTransport(transportName);
    _setTransport(transport);
    await transport.open();
  }

  Future<Transport> _createTransport(String name) async {
    log.d('creating transport "$name"');

    final Map<String, String> query = _options.query;
    query['EIO'] = Parser.PROTOCOL.toString();
    query['transport'] = name;
    if (id != null) query['sid'] = id;

    // per-transport options
    final TransportOptions options = _options.transportOptions[name];

    final TransportOptions opts = new TransportOptions(
      query: query,
      socket: this,
      hostname: options != null ? options.hostname : _options.hostname,
      port: options != null ? options.port : _options.port,
      secure: options != null ? options.secure : _options.secure,
      path: options != null ? options.path : _options.path,
      timestampRequests: options != null ? options.timestampRequests : _options?.timestampRequests ?? false,
      timestampParam: options != null ? options.timestampParam : _options.timestampParam,
      policyPort: options != null ? options.policyPort : _options.policyPort,
      securityContext: options != null ? options.securityContext : _options.securityContext,
    );

    Transport transport;
    if (name == WebSocket.NAME) {
      transport = new WebSocket(opts);
    } else if (name == Polling.NAME) {
      transport = new PollingXhr(opts);
    } else {
      throw new Exception();
    }

    await emit(eventTransport, <Transport>[transport]);
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
      ..on(Transport.eventDrain, (List<dynamic> args) async => await _onDrain())
      ..on(Transport.eventPacket, (List<dynamic> args) async => await _onPacket(args.isNotEmpty ? args[0] : null))
      ..on(Transport.eventError, (List<dynamic> args) async => await _onError(args.isNotEmpty ? args[0] : null))
      ..on(Transport.eventClose, (List<dynamic> args) async => await _onClose('transport close'));
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

      transport.once(Transport.eventPacket, (List<dynamic> args) async {
        if (failed) return;
        final Packet<dynamic> message = args[0];
        if (message.type == Packet.pong && message.data == 'probe') {
          log.d('probe transport \'$name\' pong');
          _upgrading = true;
          await emit(eventUpgrading, <Transport>[transport]);
          if (transport == null) return;
          _priorWebSocketSuccess = transport.name == WebSocket.NAME;

          log.d('pausing current transport "${this.transport.name}"');

          if (this.transport is Polling) {
            // ignore: avoid_as
            await (this.transport as Polling).pause(() async {
              if (failed) return;
              if (readyState == stateClosed) return;

              log.d('changing transport and sending upgrade packet');

              cleanup();

              _setTransport(transport);
              final Packet<Null> packet = new Packet<Null>(Packet.upgrade);
              await transport.send(<Packet<Null>>[packet]);
              await emit(eventUpgrade, <Transport>[transport]);
              //transport = null;
              _upgrading = false;
              await _flush();
            });
          }
        } else {
          log.d('probe transport "$name" failed');

          await emit(eventUpgradeError, <Error>[new EngineIOError(transport.name, PROBE_ERROR)]);
        }
      });
      await transport.send(<Packet<String>>[new Packet<String>(Packet.ping, 'probe')]);
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
      EngineIOError error;
      if (err is Exception) {
        error = new EngineIOError(transport?.name ?? 'unknown transport', PROBE_ERROR + err.toString());
      } else if (err is String) {
        error = new EngineIOError(transport?.name ?? 'unknown transport', 'probe error: $err');
      } else {
        error = new EngineIOError(transport?.name ?? 'unknown transport', PROBE_ERROR);
      }

      await freezeTransport();

      log.d('probe transport "$name" failed because of error: "$err"');

      await emit(eventUpgradeError, <Error>[error]);
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
      transport.off(Transport.eventOpen, (List<dynamic> args) => onTransportOpen());
      transport.off(Transport.eventError, (List<dynamic> error) => onError(error));
      transport.off(Transport.eventClose, (List<dynamic> args) => onTransportClose());
      // When the socket is closed while we're probing
      off(eventClose, (List<dynamic> args) => onError(<Error>[new StateError('transport closed')]));
      off(eventDrain, (List<dynamic> args) => onUpgrade(args[0]));
    };

    transport.once(Transport.eventOpen, (List<dynamic> args) async => await onTransportOpen());
    transport.once(Transport.eventError, (List<dynamic> error) async => await onError(error));
    transport.once(Transport.eventClose, (List<dynamic> args) async => await onTransportClose());

    // When the socket is closed while we're probing
    once(eventClose, (List<dynamic> args) async => await onError(<Error>[new StateError('transport closed')]));
    once(eventUpgrading, (List<dynamic> args) async => await onUpgrade(args[0]));

    await transport.open();
  }

  Future<Null> _onOpen() async {
    log.d('socket open');
    readyState = stateOpen;
    _priorWebSocketSuccess = transport.name == WebSocket.NAME;
    await emit(eventOpen);
    await _flush();

    if (readyState == stateOpen && _options.upgrade && transport is Polling) {
      log.d('starting upgrade probes: $upgrades');
      // ignore: prefer_foreach
      for (String upgrade in upgrades) {
        await _probe(upgrade);
      }
    }
  }

  Future<Null> _onPacket(Packet<dynamic> packet) async {
    if (readyState == stateOpening || readyState == stateOpen || readyState == stateClosing) {
      log.d('socket received: type "${packet.type}", data "${packet.data}"');

      await emit(eventPacket, <Packet<dynamic>>[packet]);
      await emit(eventHeartbeat);

      if (packet.type == Packet.open) {
        await _onHandshake(new HandshakeData.fromJson(packet.data));
      } else if (packet.type == Packet.pong) {
        _setPing();
        await emit(eventPong);
      } else if (packet.type == Packet.error) {
        await _onError(new EngineIOError('server error', packet.data));
      } else if (packet.type == Packet.message) {
        log.d('packet.data ${packet.data}');
        await emit(eventMessage, <dynamic>[packet.data]);
        await emit(eventData, <dynamic>[packet.data]);
      }
    } else {
      log.d('packet received with socket readyState "$readyState"');
    }
  }

  Future<Null> _onHandshake(HandshakeData data) async {
    await emit(eventHandshake, <HandshakeData>[data]);
    id = data.sessionId;

    transport.options.query['sid'] = data.sessionId;

    upgrades = data.upgrades.takeWhile((String upgrade) => _options.transports.contains(upgrade)).toList();

    _pingInterval = data.pingInterval;
    _pingTimeout = data.pingTimeout;
    await _onOpen();

    // In case open handler closes socket
    if (readyState == stateClosed) return;
    _setPing();

    off(eventHeartbeat, onHeartbeatAsListener);
    on(eventHeartbeat, onHeartbeatAsListener);
  }

  void _onHeartbeat(int timeout) {
    pingTimeoutTimer?.cancel();
    if (timeout <= 0) timeout = _pingInterval + _pingTimeout;

    pingTimeoutTimer = new Timer(new Duration(milliseconds: timeout), () async {
      if (readyState != stateClosed) await _onClose('ping timeout');
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
    return await _sendPacket(new Packet<dynamic>(Packet.ping), () async => await emit(eventPing));
  }

  Future<Null> _onDrain() async {
    writeBuffer.take(_prevBufferLen).toList().forEach(writeBuffer.remove);

    _prevBufferLen = 0;
    if (writeBuffer.isEmpty) {
      await emit(eventDrain);
    } else {
      await _flush();
    }
  }

  Future<Null> _flush() async {
    log.d('flushing ${writeBuffer.length} packets in socket');
    if (readyState != stateClosed && transport.writable && !_upgrading && writeBuffer.isNotEmpty) {
      log.d('flushing ${writeBuffer.length} packets in socket');

      _prevBufferLen = writeBuffer.length;
      await transport.send(writeBuffer.toList());
      await emit(eventFlush);
    }
  }

  Future<Null> write(dynamic message, [void callback()]) async => await send(message, callback);

  Future<Null> send(dynamic message, [void callback()]) async {
    await _sendPacket(new Packet<dynamic>(Packet.message, message), callback);
  }

  Future<Null> _sendPacket(Packet<dynamic> packet, void callback()) async {
    log.d('sendPacket: $packet');
    if (readyState == stateClosing || readyState == stateClosed) return;

    await emit(eventPacketCreate, <Packet<dynamic>>[packet]);
    writeBuffer.add(packet);
    if (callback != null) once(eventFlush, (List<dynamic> args) async => callback());
    await _flush();
  }

  Future<Socket> close() async {
    if (readyState == stateOpening || readyState == stateOpen) {
      readyState = stateClosing;

      Future<Null> close() async {
        await _onClose('forced close');
        log.d('socket closing - telling transport to close');
        await transport.close();
      }

      Future<Null> cleanupAndClose() async {
        off(eventUpgrade, (List<dynamic> args) async => await cleanupAndClose());
        off(eventUpgradeError, (List<dynamic> args) async => await cleanupAndClose());
        await close();
      }

      void waitForUpgrade() {
        // wait for update to finish since we can't send packets while pausing a transport
        once(eventUpgrade, (List<dynamic> args) async => await cleanupAndClose());
        once(eventUpgradeError, (List<dynamic> args) async => await cleanupAndClose());
      }

      if (writeBuffer.isNotEmpty) {
        once(eventDrain, (List<dynamic> args) async {
          if (_upgrading) {
            waitForUpgrade();
          } else {
            await close();
          }
        });
      } else if (_upgrading) {
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
    await emit(eventError, <Error>[error]);
    await _onClose('transport error', error);
  }

  Future<Null> _onClose(String reason, [dynamic desc]) async {
    if (readyState == stateOpening || readyState == stateOpen || readyState == stateClosing) {
      log.d('socket close with reason: $reason');

      // clear timers
      pingIntervalTimer?.cancel();
      pingTimeoutTimer?.cancel();

      // stop event from firing again for transport
      transport.off(eventClose);

      // ensure transport won't stay open
      await transport.close();

      // ignore further transport communication
      transport.off();

      // set ready state
      readyState = stateClosed;

      // clear session id
      id = null;

      // emit close events
      await emit(eventClose, <dynamic>[reason, desc]);

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
        ' upgrading: $_upgrading,\n'
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
