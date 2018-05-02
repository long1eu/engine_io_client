import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/engine_io/client/transport.dart';
import 'package:engine_io_client/src/engine_io/parser/parser.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/packet.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/parse_qs/parse_qs.dart';
import 'package:engine_io_client/src/yeast/yeast.dart';
import 'package:rxdart/rxdart.dart';

abstract class Polling extends Transport {
  static const String NAME = 'polling';
  static final Log log = new Log('EngineIo.Polling');

  static const String eventPoll = 'poll';
  static const String eventPollComplete = 'pollComplete';

  Polling(TransportOptions options) : super(options, NAME);

  bool polling;

  @override
  Observable<Event> get doOpen$ => poll$;

  Observable<Event> get poll$;

  Observable<Event> doWrite$(dynamic data);

  @override
  Observable<Event> get canClose$ {
    final Observable<Event> canClose$ = new Observable<Event>.just(new Event(Transport.eventCanClose));

    final Observable<Event> ifPolling$ = new Observable<String>.just('')
        .where((String _) => polling)
        .doOnData((String _) => log.d('we are currently polling - waiting to pause'))
        .flatMap((String _) => once(Polling.eventPollComplete));

    final Observable<Event> ifNotWritable$ = new Observable<String>.just('')
        .where((String _) => !writable)
        .doOnData((String _) => log.d('we are currently writing - waiting to pause'))
        .flatMap((String _) => once(Transport.eventDrain));

    return polling || !writable
        ? new Observable<Event>.concatEager(<Observable<Event>>[ifPolling$, ifNotWritable$])
            .where((Event event) => event.name == Polling.eventPollComplete || event.name == Transport.eventDrain)
            .flatMap((Event event) => canClose$)
        : canClose$;
  }

  Observable<Event> get pause$ => new Observable<String>.just('')
      .doOnData((String _) => readyState = Transport.statePaused)
      .flatMap((String _) => canClose$)
      .doOnData((Event _) => log.d('paused'))
      .doOnData((Event _) => readyState = Transport.statePaused)
      .map((Event _) => new Event(Transport.statePaused));

  @override
  Observable<Event> get doClose$ {
    final Observable<Event> close$ = new Observable<String>.just('')
        .doOnData((String _) => log.d('writing close packet'))
        .flatMap((String _) => write(<Packet<dynamic>>[new Packet<dynamic>(Packet.close)]));

    return readyState == Transport.stateOpen
        ? new Observable<String>.just('').doOnData((String _) => log.d('transport open - closing')).flatMap((String _) => close$)
        : new Observable<String>.just('')
            .doOnData((String _) => log.d('transport not open - deferring close'))
            .flatMap((String _) => once(Transport.eventOpen))
            .flatMap((Event _) => close$);
  }

  @override
  Observable<Event> onData(dynamic data) {
    return new Observable<dynamic>.just(data)
        .map((dynamic data) => data is String ? Parser.decodePayload(data) : Parser.decodeBinaryPayload(data))
        .flatMap<Event>((List<Packet<dynamic>> packets) {
      final Observable<Event> connection$ = new Observable<String>.just('')
          .where((String _) => readyState != Transport.stateClosed)
          .doOnData((String _) => polling = false)
          .doOnData((String _) => emit(Polling.eventPollComplete))
          .where((String _) => readyState == Transport.stateOpen)
          .flatMap((String _) => poll$);

      final Observable<Event> onOpening$ = new Observable<String>.just('').flatMap(
          (String _) => readyState == Transport.stateOpening ? onOpen$.flatMap((Event event) => connection$) : connection$);

      final Observable<Event> onClosePacket$ = new Observable<Packet<dynamic>>.fromIterable(packets)
          .where((Packet<dynamic> packet) => packet.type == Packet.close)
          .flatMap((Packet<dynamic> packet) => close$);

      final Observable<Event> onPacketReceived$ =
          new Observable<Packet<dynamic>>.fromIterable(packets).flatMap((Packet<dynamic> packet) => onPacket$(packet));

      return new Observable<Event>.merge(<Observable<Event>>[onOpening$, onClosePacket$, onPacketReceived$]);
    });
  }

  @override
  Observable<Event> write(List<Packet<dynamic>> packets) => new Observable<String>.just('')
      .flatMap((String _) => new Observable<List<Packet<dynamic>>>.just(packets))
      .map<dynamic>((List<Packet<dynamic>> packets) => Parser.encodePayload(packets))
      .flatMap((dynamic encoded) => doWrite$(encoded));

  String get uri {
    final Map<String, String> query = options?.query ?? <String, String>{};
    final String schema = options.secure ? 'https' : 'http';

    String port = '';
    if (options.port > 0 && ((schema == 'https' && options.port != 443) || (schema == 'http' && options.port != 80))) {
      port = ':${options.port}';
    }

    if (options.timestampRequests) query[options.timestampParam] = Yeast.yeast();

    String derivedQuery = ParseQS.encode(query);
    if (derivedQuery.isNotEmpty) {
      derivedQuery = '?$derivedQuery';
    }

    final String hostname = options.hostname.contains(':') ? '[${options.hostname}]' : options.hostname;
    return '$schema://$hostname$port${options.path}$derivedQuery';
  }
}
