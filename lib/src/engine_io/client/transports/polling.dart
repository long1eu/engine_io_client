part of '../transport.dart';

abstract class Polling extends Transport {
  static const String NAME = 'polling';
  static final Log log = new Log('EngineIo.Polling');

  static const String eventPoll = 'poll';
  static const String eventPollComplete = 'pollComplete';

  Polling(TransportOptions options) : super(options, NAME) {
    on(Polling.eventPollComplete)
        .doOnData((Event e) => log.d(readyState == Transport.stateOpen && options.socket.id != null
            ? 'transport is open, polling'
            : 'ignoring poll - transport state $readyState'))
        .bufferTest((Event event) => readyState == Transport.stateOpen && options.socket.id != null)
        .where((List<Event> _) => readyState == Transport.stateOpen)
        .listen((_) => _poll('constructor $readyState'));
  }

  bool polling;

  @override
  void _doOpen() => _poll('_doOpen');

  void _poll(String caller);

  Observable<Event> _doWrite$(dynamic data);

  @override
  void canClose() {
    if (polling) {
      log.d('we are currently polling - waiting to pause');
      once(Polling.eventPollComplete).listen((Event event) => emit(Transport.eventCanClose));
    } else if (!writable) {
      log.d('we are currently writing - waiting to pause');
      once(Transport.eventDrain).listen((Event event) => emit(Transport.eventCanClose));
    } else {
      emit(Transport.eventCanClose);
    }
  }

  void pause() {
    readyState = Transport.statePaused;

    on(Transport.eventCanClose).listen((Event event) {
      log.d('paused');
      readyState = Transport.statePaused;
      emit(Transport.eventPaused);
    });

    canClose();
  }

  @override
  Observable<Event> _doClose() {
    if (readyState == Transport.stateOpen) {
      log.d('writing close packet');
      return _write(<Packet>[const Packet(Packet.close)]);
    } else {
      log.d('transport not open - deferring close');
      return once(Transport.eventOpen).flatMap((Event event) => _write(<Packet>[const Packet(Packet.close)]));
    }
  }

  @override
  void _onData(dynamic data) {
    if (readyState == Transport.stateOpening) {
      _onOpen();
    }

    final List<Packet> packets = data is String ? Parser.decodePayload(data) : Parser.decodeBinaryPayload(data);

    for (Packet packet in packets) {
      if (packet.type == Packet.close) {
        _onClose();
      } else {
        _onPacket(packet);
      }
    }

    if (readyState != Transport.stateClosed) {
      polling = false;
      emit(Polling.eventPollComplete);
    }
  }

  @override
  Observable<Event> _write(List<Packet> packets) {
    final dynamic encoded = Parser.encodePayload(packets);
    return _doWrite$(encoded);
  }

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
