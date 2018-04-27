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
    final Observable<Event> data$ = new Observable<String>.just('')
        .doOnData((String _) => log.i('polling got data:${data.runtimeType} $data '))
        .map((String _) => data is String ? Parser.decodePayload(data) : Parser.decodeBinaryPayload(data))
        .expand((List<Packet<dynamic>> packets) => packets)
        .flatMap((Packet<dynamic> packet) => new Observable<Event>.merge(<Observable<Event>>[
              new Observable<String>.just(readyState)
                  .where((String readyState) => readyState == Transport.stateOpening)
                  .flatMap<Event>((String _) => onOpen$),
              new Observable<String>.just(packet.type)
                  .where((String type) => type == Packet.close)
                  .flatMap<Event>((String _) => onClose$),
              onPacket(packet),
            ]));

    final Observable<Event> connection$ = new Observable<String>.just(readyState)
        .where((String readyState) => readyState != Transport.stateClosed)
        .doOnData((String _) => polling = false)
        .doOnData((String _) => emit(Polling.eventPollComplete))
        .where((String readyState) => readyState == Transport.stateOpen)
        .doOnDone(() => log.i('ignoring poll - transport state "$readyState"'))
        .flatMap((String _) => poll$);

    return new Observable<Event>.merge(<Observable<Event>>[data$, connection$]);
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

/*
  Observable<Event> get pause$ {
    readyState = Transport.statePaused;

    final Observable<Event> pause$ = new Observable<String>.just('')
        .doOnData((String _) => log.d('paused'))
        .doOnData((String _) => readyState = Transport.statePaused)
        .map((String _) => new Event(Transport.statePaused));

    final Observable<Event> ifPolling$ = new Observable<String>.just('')
        .where((String _) => polling)
        .doOnData((String _) => log.d('we are currently polling - waiting to pause'))
        .flatMap((String _) => once(Polling.eventPollComplete))
        .flatMap((Event event) => pause$);

    final Observable<Event> ifNotWritable$ = new Observable<String>.just('')
        .where((String _) => !writable)
        .doOnData((String _) => log.d('we are currently writing - waiting to pause'))
        .flatMap((String _) => once(Transport.eventDrain))
        .flatMap((Event event) => pause$);

    return polling || !writable ? new Observable<Event>.concatEager(<Observable<Event>>[ifPolling$, ifNotWritable$]) : pause$;
  }
*/
