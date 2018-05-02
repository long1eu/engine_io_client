import 'dart:async';

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
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/parse_qs/parse_qs.dart';
import 'package:rxdart/rxdart.dart';

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

  SocketOptions options;

  String id;
  bool _priorWebSocketSuccess = false;
  bool _upgrading = false;

  String readyState;
  Transport transport;
  List<String> upgrades;

  int _pingInterval;
  int _pingTimeout;

  int _prevBufferLen;
  StreamController<List<Packet<dynamic>>> writeBuffer = new StreamController<List<Packet<dynamic>>>();
  StreamSubscription<Event> flushSubscription;

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

    // flushSubscription = flush$.listen(print);
  }

  Observable<Event> get flush$ => new Observable<List<Packet<dynamic>>>(writeBuffer.stream)
      .doOnData((List<Packet<dynamic>> _) => log.d('flushing packets in socket $_'))
      .bufferTest((_) => transport.writable && transport.readyState != Transport.stateClosed && !_upgrading)
      .expand((List<List<Packet<dynamic>>> items) => items)
      .flatMap((List<Packet<dynamic>> packets) => packets.isEmpty
          ? new Observable<Event>.just(new Event(Socket.eventDrain)).doOnData((Event event) => emit(Socket.eventDrain))
          : transport
              .send(packets)
              .doOnData((Event _) => emit(Socket.eventFlush))
              .map((Event _) => new Event(Socket.eventFlush)));

  Observable<Event> get open$ {
    String transportName;
    if (options?.rememberUpgrade ?? true && _priorWebSocketSuccess && options.transports.contains(WebSocket.NAME)) {
      transportName = WebSocket.NAME;
    } else if (options.transports.isEmpty) {
      emit(eventError, <Error>[new EngineIOError('No transports available', null)]);
    } else {
      transportName = options.transports[0];
    }

    return new Observable<String>.just(transportName)
        .doOnData((String _) => readyState = stateOpening)
        .flatMap((String name) => _createTransport$(name))
        .doOnData((Transport transport) => log.e(transport.name))
        .doOnData((Transport transport) => _setTransport(transport))
        .flatMap((Transport transport) => transport.open$)
        .where((Event event) => event.name == Transport.eventPacket)
        .where((Event event) => event.args[0].type == Transport.stateOpen);
  }

  Observable<Transport> _createTransport$(String name) => new Observable<String>.just(name)
      .where((String name) => name == WebSocket.NAME || name == Polling.NAME)
      .doOnData((String name) => log.d('creating transport "$name"'))
      .flatMap((String _) => new Observable<Map<String, String>>.just(options.query))
      .map((Map<String, String> query) {
        query['EIO'] = Parser.PROTOCOL.toString();
        query['transport'] = name;
        if (id != null) query['sid'] = id;
        return query;
      })
      .flatMap((Map<String, String> query) => new Observable<TransportOptions>.just(options.transportOptions[name])
          .map((TransportOptions transportOptions) => options.copyWith(
                query: query,
                socket: this,
                hostname: transportOptions?.hostname,
                port: transportOptions?.port,
                secure: transportOptions?.secure,
                path: transportOptions?.path,
                timestampRequests: transportOptions?.timestampRequests,
                timestampParam: transportOptions?.timestampParam,
                policyPort: transportOptions?.policyPort,
                securityContext: transportOptions?.securityContext,
              )))
      .map((TransportOptions options) => name == WebSocket.NAME ? new WebSocket(options) : new PollingXhr(options))
      .doOnData((Transport transport) => emit(eventTransport, <Transport>[transport]));

  void _setTransport(Transport transport) {
    log.d('setting transport ${transport.name}');

    if (this.transport != null) {
      log.d('clearing existing transport ${transport.name}');

      this.transport.off();
    }

    this.transport = transport;

    transport
        .on(Transport.eventPacket)
        .flatMap((Event e) => _onPacket(e.args.isNotEmpty ? e.args[0] : null))
        .listen(log.addTag('Transport.eventPacket').d);
    transport
        .on(Transport.eventError)
        .flatMap((Event e) => _onError$(e.args.isNotEmpty ? e.args[0] : null))
        .listen(log.addTag('Transport.eventError').d);
    transport
        .on(Transport.eventClose)
        .flatMap((Event e) => _onClose$('transport close because of $e'))
        .listen(log.addTag('Transport.eventClose').d);
  }

  Observable<Event> _probe$(String name) => new Observable<String>.just(name)
          .doOnData((String name) => log.d('probing transport $name'))
          .flatMap((String name) => _createTransport$(name))
          .doOnData((Transport transport) => _priorWebSocketSuccess = false)
          .flatMap((Transport transport) {
        bool failed = false;

        void cleanup() {
          transport.off(Transport.eventOpen);
          transport.off(Transport.eventError);
          transport.off(Transport.eventClose);

          off(eventClose);
          off(eventDrain);
        }

        final Observable<Event> onTransportOpen$ = new Observable<String>.just('')
            .where((String _) => !failed)
            .doOnData((String _) => log.d('probe transport "$name" opened'))
            .flatMap((String _) => transport.once(Transport.eventPacket))
            .doOnData((Event _) => log.d('probe transport $_'))
            .where((Event _) => !failed)
            .map<Packet<dynamic>>((Event event) => event.args[0])
            .flatMap((Packet<dynamic> packet) => packet.type != Packet.pong || packet.data != 'probe'
                ? new Observable<String>.just('')
                    .doOnData((String _) => log.d('probe transport "$name" failed'))
                    .doOnData((String _) => emit(eventUpgradeError, <Error>[new EngineIOError(transport.name, PROBE_ERROR)]))
                    .map((String _) => new Event(eventUpgradeError, <Error>[new EngineIOError(transport.name, PROBE_ERROR)]))
                : new Observable<String>.just('')
                    .doOnData((String _) => log.d('probe transport \'$name\' pong'))
                    .doOnData((String _) => _upgrading = true)
                    .doOnData((String _) => emit(eventUpgrading, <Transport>[transport]))
                    .where((String _) => transport != null)
                    .doOnData((String _) => _priorWebSocketSuccess = transport.name == WebSocket.NAME)
                    .doOnData((String _) => log.d('pausing current transport "${this.transport.name}"'))
                    .map((String _) => transport)
                    .flatMap((Transport _) => (this.transport as Polling).pause$)
                    .where((Event _) => !failed)
                    .where((Event _) => readyState != Socket.stateClosed)
                    .doOnData((Event _) => log.d('changing transport and sending upgrade packet'))
                    .map((Event _) => cleanup())
                    .map((dynamic _) => _setTransport(transport))
                    .flatMap((dynamic _) => transport.send(<Packet<Null>>[new Packet<Null>(Packet.upgrade)]))
                    .doOnData((Event _) => _upgrading = false)

                    .doOnData((Event _) => emit(eventUpgrade, <Transport>[transport]))
                    .map((Event _) => new Event(eventUpgrade, <Transport>[transport])));

        final Observable<Event> freezeTransport$ = new Observable<String>.just('')
            .where((String _) => !failed)
            .doOnData((String _) => failed = true)
            .map((String _) => cleanup())
            .flatMap((dynamic _) => transport.close$)
            .doOnData((Event _) => transport = null);

        // Handle any error that happens while probing
        Observable<Event> onError$(List<Error> err) {
          log.w('probe err: $err');
          EngineIOError error;
          if (err is Exception) {
            error = new EngineIOError(transport?.name ?? 'unknown transport', PROBE_ERROR + err.toString());
          } else if (err is String) {
            error = new EngineIOError(transport?.name ?? 'unknown transport', 'probe error: $err');
          } else {
            error = new EngineIOError(transport?.name ?? 'unknown transport', PROBE_ERROR);
          }

          return freezeTransport$
              .doOnData((Event _) => log.d('probe transport "$name" failed because of error: "$err"'))
              .doOnData((Event _) => emit(eventUpgradeError, <Error>[error]))
              .doOnData((Event _) => new Event(eventUpgradeError, <Error>[error]));
        }

        // When the socket is upgraded while we're probing
        Observable<Event> onUpgrade$(Transport to) => new Observable<String>.just('')
            .where((String _) => transport != null && to.name != transport.name)
            .doOnData((String _) => log.d('"${to.name}" works - aborting "${transport.name}"'))
            .flatMap((String _) => freezeTransport$);

        final Observable<Event> status$ = new Observable<Event>.merge(<Observable<Event>>[
          transport.once(Transport.eventError).flatMap((Event event) => onError$(event.args)),
          transport.once(Transport.eventClose).flatMap((Event _) => onError$(<Error>[new StateError('transport closed')])),
          // When the socket is closed while we're probing
          once(Socket.eventClose).flatMap((Event _) => onError$(<Error>[new StateError('transport closed')])),
          once(Socket.eventUpgrading).flatMap((Event event) => onUpgrade$(event.args[0])),
        ]).doOnData((Event event) => log.e('status\$ event $event'));

        return new Observable<Event>.merge(<Observable<Event>>[
          status$.doOnData((Event e)=> log.w(e)),
          transport.open$
              .doOnData((Event t) => log.e('event probe $t'))
              .where((Event event) => event.name == Transport.eventOpen)
              .flatMap((Event _) => transport.send(<Packet<String>>[new Packet<String>(Packet.ping, 'probe')]))
              .flatMap((Event _) => onTransportOpen$)
        ]).doOnData((Event event) => log.e('probe event $event lll'));
      });

  Observable<Event> get _onOpen$ {
    final Observable<String> flush = new Observable<String>.just('')
        .where((String _) => flushSubscription == null)
        .doOnData((String _) => flushSubscription = flush$.listen(null));

    return new Observable<String>.just('')
        .doOnData((String _) => log.d('socket open'))
        .doOnData((String _) => readyState = stateOpen)
        .doOnData((String _) => _priorWebSocketSuccess = transport.name == WebSocket.NAME)
        .doOnData((String _) => emit(Socket.eventOpen))
        .flatMap((String _) => new Observable<Event>.concat(<Observable<Event>>[
              new Observable<Event>.just(new Event(Socket.eventOpen)),
              (readyState == stateOpen && options.upgrade && transport is Polling)
                  ? new Observable<String>.just('')
                      .doOnData((String _) => log.d('starting upgrade probes: $upgrades'))
                      .expand((String _) => upgrades)
                      .flatMap((String upgrade) => _probe$(upgrade))
                      .flatMap((Event event) => flush.map((String _) => event))
                  : flush.map((_) => new Event(Socket.eventOpen)),
            ]));
  }

  Observable<Event> _onPacket(Packet<dynamic> packet) => new Observable<String>.just(readyState)
      .doOnData((String readyState) => log.d('packet received with socket readyState "$readyState"'))
      .where((String readyState) => readyState == stateOpening || readyState == stateOpen || readyState == stateClosing)
      .map((String _) => packet)
      .doOnData((Packet<dynamic> packet) => log.d('socket received: type "${packet.type}", data "${packet.data}"'))
      .doOnData((Packet<dynamic> packet) => emit(eventPacket, <Packet<dynamic>>[packet]))
      .doOnData((Packet<dynamic> packet) => emit(eventHeartbeat))
      .flatMap((Packet<dynamic> packet) => new Observable<Event>.merge(<Observable<Event>>[
            new Observable<String>.just(packet.type)
                .where((String type) => type == Packet.open)
                .flatMap((String _) => _onHandshake(new HandshakeData.fromJson(packet.data))),
            new Observable<String>.just(packet.type)
                .where((String type) => type == Packet.pong)
                .flatMap((String _) => _setPing$)
                .doOnData((Event _) => emit(eventPong)),
            new Observable<String>.just(packet.type)
                .where((String type) => type == Packet.error)
                .flatMap((String _) => _onError$(new EngineIOError('server error', packet.data))),
            new Observable<String>.just(packet.type)
                .where((String type) => type == Packet.message)
                .doOnData((String _) => log.d('packet.data ${packet.data}'))
                .doOnData((String _) => emit(eventMessage, <dynamic>[packet.data]))
                .doOnData((String _) => emit(eventData, <dynamic>[packet.data]))
                .flatMap((String _) => new Observable<Event>.fromIterable(<Event>[
                      new Event(eventMessage, <dynamic>[packet.data]),
                      new Event(eventMessage, <dynamic>[packet.data])
                    ]))
          ]));

  Observable<Event> _onHandshake(HandshakeData data) => new Observable<HandshakeData>.just(data)
      .doOnData((HandshakeData data) => emit(Socket.eventHandshake, <HandshakeData>[data]))
      .doOnData((HandshakeData data) => id = data.sessionId)
      .doOnData((HandshakeData data) => transport.options.query['sid'] = data.sessionId)
      .doOnData((HandshakeData data) =>
          upgrades = data.upgrades.takeWhile((String upgrade) => options.transports.contains(upgrade)).toList())
      .doOnData((HandshakeData data) => _pingInterval = data.pingInterval)
      .doOnData((HandshakeData data) => _pingTimeout = data.pingTimeout)
      .flatMap((HandshakeData data) => _onOpen$)
      .where((Event _) => readyState != stateClosed)
      .flatMap((Event _) => _setPing$)
      .flatMap((Event data) => on(Socket.eventHeartbeat))
      .flatMap(
          (Event event) => _onHeartbeat$(event.args ?? -1)); //.doOnData((Event event) => transport.emit(Transport.stateOpen));

  Observable<Event> _onHeartbeat$(int timeout) =>
      new Observable<int>.timer(timeout, new Duration(milliseconds: timeout <= 0 ? _pingInterval + _pingTimeout : timeout))
          .flatMap((int timeout) => new Observable<Event>.race(<Observable<Event>>[
                on(Socket.eventPong),
                readyState != Socket.stateClosed
                    ? _onClose$('ping timeout')
                    : new Observable<Event>.just(new Event(Socket.stateClosed))
              ]));

  Observable<Event> get _setPing$ => new Observable<int>.timer(_pingTimeout, new Duration(milliseconds: _pingInterval))
      .doOnData((int pingTimeout) => log.d('writing ping packet - expecting pong within $pingTimeout'))
      .flatMap((int timeout) => _ping$)
      .flatMap((Event event) => _onHeartbeat$(_pingTimeout));

  Observable<Event> get _ping$ => _sendPacket$(new Packet<dynamic>(Packet.ping))
      .doOnData((Event event) => emit(Socket.eventPing))
      .map((Event event) => new Event(Socket.eventPing));

  Observable<Event> write$(dynamic message) => send$(message);

  Observable<Event> send$(dynamic message) => _sendPacket$(new Packet<dynamic>(Packet.message, message));

  Observable<Event> _sendPacket$(Packet<dynamic> packet) => new Observable<Packet<dynamic>>.just(packet)
      .doOnData((Packet<dynamic> _) => log.d('sendPacket: $packet'))
      .where((Packet<dynamic> _) => readyState != stateClosing && readyState != stateClosed)
      .doOnData((Packet<dynamic> _) => emit(eventPacketCreate, <Packet<dynamic>>[packet]))
      .where((Packet<dynamic> _) => readyState != stateClosing && readyState != stateClosed)
      .doOnData((Packet<dynamic> packet) => writeBuffer.add(<Packet<dynamic>>[packet]))
      .flatMap((Packet<dynamic> _) => once(Socket.eventFlush));

  Observable<Event> get close$ => new Observable<String>.just(readyState)
      .where((String readyState) => readyState == stateOpening || readyState == stateOpen)
      .doOnData((String _) => readyState = stateClosing)
      .flatMap((String _) => transport.canClose$)
      .doOnData((Event _) => log.e('we can close $_upgrading'))
      .flatMap((Event event) => _upgrading
          ? new Observable<Event>.race(<Observable<Event>>[once(Socket.eventUpgrade), once(Socket.eventUpgradeError)])
              .doOnData((Event _) => offAll(<String>[Socket.eventUpgrade, Socket.eventUpgradeError]))
              .flatMap((Event _) => _onClose$('forced close'))
          : _onClose$('forced close'))
      .doOnData((Event _) => log.d('socket closing - telling transport to close'))
      .flatMap((Event event) => transport.close$);

  Observable<Event> _onError$(Error error) => new Observable<Error>.just(error)
      .doOnData((Error error) => log.d('socket error $error'))
      .doOnData((Error _) => _priorWebSocketSuccess = false)
      .flatMap((Error _) => _onClose$('transport error', error))
      .doOnData((Event _) => emit(eventError, <Error>[error]))
      .map((Event _) => new Event(eventError, <Error>[error]));

  Observable<Event> _onClose$(String reason, [dynamic desc]) => new Observable<String>.just(readyState)
      .where((String readyState) => readyState == stateOpening || readyState == stateOpen || readyState == stateClosing)
      .doOnData((String _) => log.d('socket close with reason: $reason'))
      .doOnData((String _) => transport.off(eventClose))
      .flatMap((String _) => transport.close$)
      .doOnData((Event _) => transport.off())
      .doOnData((Event _) => readyState = Socket.stateClosed)
      .doOnData((Event _) => id = null)
      .doOnData((Event _) => emit(eventClose, <dynamic>[reason, desc]))
      .doOnData((Event _) => flushSubscription?.cancel())
      .doOnData((Event _) => flushSubscription = null)
      .doOnData((Event _) => _prevBufferLen = 0);

  @override
  String toString() => 'Socket{\n'
      '\toptions: $options, \n'
      '\tid: $id, \n'
      '\t_priorWebSocketSuccess: $_priorWebSocketSuccess, \n'
      '\t_upgrading: $_upgrading, \n'
      '\treadyState: $readyState, \n'
      '\t_pingInterval: $_pingInterval, \n'
      '\t_pingTimeout: $_pingTimeout, \n'
      '\t_prevBufferLen: $_prevBufferLen\n'
      '\t}';
}
