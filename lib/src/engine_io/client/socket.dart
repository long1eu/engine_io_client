import 'dart:async';

import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/engine_io/client/engine_io_error.dart';
import 'package:engine_io_client/src/engine_io/client/transport.dart';
import 'package:engine_io_client/src/engine_io/parser/parser.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/handshake_data.dart';
import 'package:engine_io_client/src/models/packet.dart';
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/parse_qs/parse_qs.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

class Socket extends Emitter {
  static final Log log = new Log('EngineIo.Socket');
  static const String PROBE_ERROR = 'probe error: ';

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

  @visibleForTesting
  SocketOptions options;

  String id;
  Transport transport;

  String readyState;
  List<String> _upgrades;
  bool _priorWebSocketSuccess = false;
  bool _upgrading = false;
  int _pingInterval;
  int _pingTimeout;

  final StreamController<List<Packet>> _writeBuffer = new StreamController<List<Packet>>();
  StreamSubscription<Event> _flushSubscription;

  Socket(this.options) {
    String hostname = options.host;
    if (options.host != null) {
      final bool ipv6 = options.host.split(':').length > 2;
      if (ipv6) {
        final int start = hostname.indexOf('[');
        if (start != -1) hostname = hostname.substring(start + 1);
        final int end = hostname.lastIndexOf(']');
        if (end != -1) hostname = hostname.substring(0, end);
      }
    }

    options = options.copyWith(
      hostname: hostname,
      port: options.port != -1 ? options.port : options.secure ? 443 : 80,
      query: options.rawQuery != null ? ParseQS.decode(options.rawQuery) : <String, String>{},
      path: '${options.path.replaceAll('/\$', '')}/',
      policyPort: options.policyPort != 0 ? options.policyPort : 843,
    );
  }

  Observable<Event> get _flush$ => new Observable<List<Packet>>(_writeBuffer.stream)
      .doOnData((List<Packet> _) => log.d('flushing packets in socket ${transport.name} $_'))
      .bufferTest((_) => transport.writable && transport.readyState != Transport.stateClosed && !_upgrading)
      .expand((List<List<Packet>> items) => items)
      .flatMap((List<Packet> packets) => transport.send(packets))
      .doOnData((Event _) => emit(Socket.eventDrain))
      .doOnData((Event _) => emit(Socket.eventFlush));

  void open() {
    String transportName;
    if (options?.rememberUpgrade ?? true && _priorWebSocketSuccess && options.transports.contains(WebSocket.NAME)) {
      transportName = WebSocket.NAME;
    } else if (options.transports.isEmpty) {
      emit(eventError, <Error>[new EngineIOError('No transports available', null)]);
    } else {
      transportName = options.transports[0];
    }

    readyState = Socket.stateOpening;
    final Transport transport = _createTransport(transportName);
    _setTransport(transport);
    transport.open();
  }

  Transport _createTransport(String name) {
    assert(name == WebSocket.NAME || name == Polling.NAME);
    log.d('creating transport "$name"');

    final Map<String, String> query = new Map<String, dynamic>.from(options.query);
    query['EIO'] = Parser.PROTOCOL.toString();
    query['transport'] = name;
    if (id != null) query['sid'] = id;

    final TransportOptions tops = options.transportOptions[name];
    final TransportOptions transportOptions = options.copyWith(
      query: query,
      socket: this,
      hostname: tops?.hostname,
      port: tops?.port,
      secure: tops?.secure,
      path: tops?.path,
      timestampRequests: tops?.timestampRequests,
      timestampParam: tops?.timestampParam,
      policyPort: tops?.policyPort,
      securityContext: tops?.securityContext,
    );

    final Transport transport = name == WebSocket.NAME ? new WebSocket(transportOptions) : new PollingXhr(transportOptions);
    emit(eventTransport, <Transport>[transport]);
    return transport;
  }

  void _setTransport(Transport transport) {
    log.d('setting transport ${transport.name}');

    if (this.transport != null) {
      log.d('clearing existing transport ${transport.name}');

      this.transport.off();
    }

    this.transport = transport;

    transport.on(Transport.eventPacket).listen((Event e) => _onPacket(e.args.isNotEmpty ? e.args[0] : null));
    transport.on(Transport.eventError).listen((Event e) => _onError(e.args.isNotEmpty ? e.args[0] : null));
    transport.on(Transport.eventClose).listen((Event e) => _onClose('transport close because of $e'));
  }

  void _probe$(String name) {
    log.d('probing transport $name');
    Transport transport = _createTransport(name);
    _priorWebSocketSuccess = false;
    bool failed = false;

    void cleanup() {
      transport.off(Transport.eventOpen);
      transport.off(Transport.eventError);
      transport.off(Transport.eventClose);
    }

    void onTransportOpen() {
      if (failed) return;
      log.d('probe transport "$name" opened');

      transport.once(Transport.eventPacket).listen((Event event) {
        log.d('probe transport $event');
        if (failed) return;
        final Packet packet = event.args[0];

        if (packet.type == Packet.pong || packet.data == 'probe') {
          log.d('probe transport "$name" pong');
          _upgrading = true;
          emit(eventUpgrading, <Transport>[transport]);
          if (transport == null) return;
          _priorWebSocketSuccess = transport.name == WebSocket.NAME;
          log.d('pausing current transport "${this.transport.name}"');

          this.transport.once(Transport.eventPaused).listen((Event event) {
            if (failed || readyState == Socket.stateClosed) return;
            log.d('changing transport and sending upgrade packet');
            cleanup();
            _setTransport(transport);
            transport.send(<Packet>[const Packet(Packet.upgrade)]).listen((Event event) {
              _upgrading = false;
              emit(eventUpgrade, <Transport>[transport]);
            });
          });

          // ignore: avoid_as
          (this.transport as Polling).pause();
        } else {
          log.d('probe transport "$name" failed');
          emit(eventUpgradeError, <Error>[new EngineIOError(transport.name, PROBE_ERROR)]);
        }
      });
    }

    void freezeTransport() {
      if (failed) return;
      failed = true;
      cleanup();

      transport.once(Transport.eventClose).listen((Event event) => transport = null);
      transport.close('freezeTransport');
    }

    // Handle any error that happens while probing
    void onError(Error err) {
      log.w('probe err: $err');
      EngineIOError error;
      if (err is Error) {
        error = new EngineIOError(transport?.name ?? 'unknown transport', PROBE_ERROR + err.toString());
      } else if (err is String) {
        error = new EngineIOError(transport?.name ?? 'unknown transport', 'probe error: $err');
      } else {
        error = new EngineIOError(transport?.name ?? 'unknown transport', PROBE_ERROR);
      }

      freezeTransport();
      log.d('probe transport "$name" failed because of error: "$err"');
      emit(eventUpgradeError, <Error>[error]);
    }

    // When the socket is upgraded while we're probing
    void onUpgrade(Transport to) {
      if (transport != null && to.name != transport.name) {
        log.d('"${to.name}" works - aborting "${transport.name}"');
        freezeTransport();
      }
    }

    transport.once(Transport.eventError).listen((Event event) => onError(event.args[0]));
    transport.once(Transport.eventClose).listen((Event _) => onError(new StateError('transport closed')));

    // When the socket is closed while we're probing
    once(Socket.eventClose).listen((Event _) => onError(new StateError('socket closed')));
    once(Socket.eventUpgrading).listen((Event event) => onUpgrade(event.args[0]));

    transport.on(Transport.eventOpen).flatMap((Event event) {
      log.e('event probe $event');
      onTransportOpen();
      return transport.send(<Packet>[const Packet(Packet.ping, 'probe')]);
    }).listen(null);

    transport.open();
  }

  void _onOpen() {
    log.d('socket open');
    readyState = stateOpen;
    _priorWebSocketSuccess = transport.name == WebSocket.NAME;
    _flushSubscription ??= _flush$.listen(null);
    emit(Socket.eventOpen);

    if (readyState == stateOpen && options.upgrade && transport is Polling) {
      log.d('starting upgrade probes: $_upgrades');
      _upgrades.forEach(_probe$);
    }
  }

  void _onPacket(Packet packet) {
    if (readyState == stateOpening || readyState == stateOpen || readyState == stateClosing) {
      emit(Socket.eventPacket);
      emit(Socket.eventHeartbeat);

      if (packet.type == Packet.open) {
        _onHandshake(new HandshakeData.fromJson(packet.data));
      } else if (packet.type == Packet.pong) {
        _setPing();
        emit(Socket.eventPong);
      } else if (packet.type == Packet.error) {
        _onError(new EngineIOError('server error', packet.data));
      } else if (packet.type == Packet.message) {
        log.d('packet.data ${packet.data}');
        emit(eventMessage, <dynamic>[packet.data]);
        emit(eventData, <dynamic>[packet.data]);
      }
    } else {
      log.w('packet received with socket readyState "$readyState"');
    }
  }

  void _onHandshake(HandshakeData data) {
    emit(Socket.eventHandshake, <HandshakeData>[data]);
    id = data.sessionId;
    transport.options.query['sid'] = data.sessionId;
    _upgrades = data.upgrades.takeWhile((String upgrade) => options.transports.contains(upgrade)).toList();
    _pingInterval = data.pingInterval;
    _pingTimeout = data.pingTimeout;

    _onOpen();
    if (readyState != Socket.stateClosed) {
      _setPing();
      on(Socket.eventHeartbeat).listen((Event event) => _onHeartbeat(event.args ?? -1));
    }
  }

  void _onHeartbeat(int timeout) {
    new Observable<dynamic>.race(<Observable<dynamic>>[
      once(Socket.eventPong),
      new Observable<int>.timer(timeout, new Duration(milliseconds: timeout <= 0 ? _pingInterval + _pingTimeout : timeout))
          .doOnData((int _) => _onClose('ping timeout')),
    ]).listen(null);
  }

  void _setPing() {
    new Observable<int>.timer(_pingTimeout, new Duration(milliseconds: _pingInterval))
        .doOnData((int pingTimeout) => log.d('writing ping packet - expecting pong within $pingTimeout'))
        .listen((int _) {
      _ping();
      _onHeartbeat(_pingTimeout);
    });
  }

  void _ping() {
    _sendPacket$(const Packet(Packet.ping)).listen((Event event) => emit(Socket.eventPing));
  }

  void send(dynamic message) => _sendPacket$(new Packet(Packet.message, message)).listen(null);

  Observable<Event> write$(dynamic message) => _sendPacket$(new Packet(Packet.message, message));

  Observable<Event> _sendPacket$(Packet packet) {
    log.d('sendPacket: $packet');
    if (readyState != stateClosing && readyState != stateClosed) {
      emit(eventPacketCreate, <Packet>[packet]);
      _writeBuffer.add(<Packet>[packet]);

      return once(Socket.eventFlush);
    }
    return new Observable<Event>.empty();
  }

  void close() {
    if (readyState == Socket.stateOpening || readyState == Socket.stateOpen) {
      readyState = Socket.stateClosing;

      transport.on(Transport.eventCanClose).listen((Event event) {
        log.d('We can close. Check upgrading: $_upgrading');

        if (_upgrading) {
          log.d('Waiting for transport to upgrade.');
          new Observable<Event>.race(<Observable<Event>>[once(Socket.eventUpgrade), once(Socket.eventUpgradeError)])
              .listen((Event event) {
            offAll(<String>[Socket.eventUpgrade, Socket.eventUpgradeError]);
            _onClose('forced close');
            log.d('socket closing - telling transport to close');
            transport.close('close, _upgrading');
          });
        } else {
          log.d('Transport is not upgrading. We can really close.');
          _onClose('forced close');
          log.d('socket closing - telling transport to close');
          transport.close('close, !_upgrading');
        }
      });

      transport.canClose();
    }
  }

  void _onError(Error error) {
    log.d('socket error $error');
    _priorWebSocketSuccess = false;
    _onClose('transport error', error);
    emit(eventError, <Error>[error]);
  }

  void _onClose(String reason, [dynamic desc]) {
    if (readyState == stateOpening || readyState == stateOpen || readyState == stateClosing) {
      log.d('socket close with reason: $reason');
      transport.off(Socket.eventClose);
      transport.close('_onClose');
      transport.off();
      readyState = Socket.stateClosed;
      id = null;
      _flushSubscription?.cancel();
      _flushSubscription = null;
      log.w('emitting event close');
      emit(Socket.eventClose, <dynamic>[reason, desc]);
      emit('cacamaca', <dynamic>[reason, desc]);
      log.w('emitting event close');
    }
  }

  @override
  String toString() {
    return (new ToStringHelper('Socket')
          ..add('options', '$options')
          ..add('id', '$id')
          ..add('_priorWebSocketSuccess', '$_priorWebSocketSuccess')
          ..add('_upgrading', '$_upgrading')
          ..add('readyState', '$readyState')
          ..add('transport', '$transport')
          ..add('upgrades', '$_upgrades')
          ..add('_pingInterval', '$_pingInterval')
          ..add('_pingTimeout', '$_pingTimeout'))
        .toString();
  }
}
