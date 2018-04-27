import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/engine_io/client/engine_io_error.dart';
import 'package:engine_io_client/src/engine_io/parser/parser.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/packet.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:rxdart/rxdart.dart';

abstract class Transport extends Emitter {
  static final Log log = new Log('EngineIo.Transport');

  static const String eventOpen = 'open';
  static const String eventClose = 'close';
  static const String eventPacket = 'packet';
  static const String eventDrain = 'drain';
  static const String eventError = 'error';
  static const String eventRequestHeaders = 'requestHeaders';
  static const String eventResponseHeaders = 'responseHeaders';
  static const String eventCanClose = 'canClose';

  static const String stateOpening = 'opening';
  static const String stateOpen = 'open';
  static const String stateClosed = 'closed';
  static const String statePaused = 'paused';

  Transport(this.options, this.name);

  final String name;

  TransportOptions options;
  String readyState;
  bool writable = false;

  Observable<Event> get canClose$ => !writable
      ? new Observable<String>.just('')
          .doOnData((String _) => log.d('we are currently writing - waiting to pause'))
          .flatMap((String _) => once(Transport.eventDrain))
          .where((Event event) => event.name == Transport.eventDrain)
          .map((Event event) => new Event(Transport.eventCanClose))
      : new Observable<Event>.just(new Event(Transport.eventCanClose));

  Observable<Event> get open$ => new Observable<String>.just('')
      .where((String _) => readyState == Transport.stateClosed || readyState == null)
      .doOnData((String _) => readyState = Transport.stateOpening)
      .flatMap((String _) => doOpen$);

  Observable<Event> get onOpen$ => new Observable<String>.just('')
      .doOnData((String _) => log.d('onOpen'))
      .doOnData((String _) => readyState = Transport.stateOpen)
      .doOnData((String _) => writable = true)
      .doOnData((String _) => emit(Transport.eventOpen))
      .map((String _) => new Event(Transport.eventOpen));

  Observable<Event> get close$ => new Observable<String>.just('')
      .where((String _) => readyState == Transport.stateOpening || readyState == Transport.stateOpen)
      .flatMap((String _) => doClose$)
      .flatMap((dynamic _) => onClose$);

  Observable<Event> get onClose$ => new Observable<String>.just('')
      .doOnData((String _) => log.d('onClose'))
      .doOnData((String _) => readyState = Transport.stateClosed)
      .doOnData((String _) => emit(Transport.eventClose))
      .map((String _) => new Event(Transport.eventClose));

  Observable<Event> onError(String message, dynamic desc) => new Observable<String>.just('')
      .doOnData((String _) => emit(Transport.eventError, <Error>[new EngineIOError(message, desc)]))
      .map((String _) => new Event(Transport.eventError, <Error>[new EngineIOError(message, desc)]));

  Observable<Event> send(List<Packet<dynamic>> packets) => new Observable<String>.just('').flatMap((String _) {
        if (readyState == Transport.stateOpen) {
          return new Observable<String>.just('')
              .doOnData((String _) => writable = false)
              .flatMap((String _) => write(packets))
              .doOnData((Event event) => writable = true)
              .doOnData((Event _) => emit(Transport.eventDrain))
              .map((Event _) => new Event(Transport.eventDrain));
        } else {
          throw new StateError('Transport not open');
        }
      });

  Observable<Event> onData(dynamic data) => new Observable<dynamic>.just(data)
      .map((dynamic data) => data is String ? Parser.decodePacket(data) : Parser.decodeBytePacket(data))
      .flatMap((Packet<dynamic> packet) => onPacket(packet));

  Observable<Event> onPacket(Packet<dynamic> packet) => new Observable<String>.just('')
      .doOnData((String _) => emit(Transport.eventPacket, <Packet<dynamic>>[packet]))
      .map((String _) => new Event(Transport.eventPacket, <Packet<dynamic>>[packet]));

  Observable<Event> write(List<Packet<dynamic>> packets);

  Observable<Event> get doOpen$;

  Observable<void> get doClose$;
}
