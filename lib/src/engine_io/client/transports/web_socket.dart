part of '../transport.dart';

class WebSocket extends Transport {
  static const String NAME = 'websocket';
  static final Log log = new Log('EngineIo.WebSocket');

  WebSocket(TransportOptions options) : super(options, NAME);

  io.WebSocket socket;

  @override
  void _doOpen() {
    final Map<String, List<String>> headers = options.headers ?? <String, List<String>>{};

    log.e(uri);
    new Observable<io.WebSocket>.fromFuture(
      WebSocketImpl.connect(
        uri,
        headers: headers,
        httpClient: new HttpClient(
          context: options.securityContext,
        )..badCertificateCallback = badCertificateCallback,
        cookieJar: options.cookieJar,
      ),
    )
        .doOnData((io.WebSocket socket) => log.w('response $socket'))
        .doOnData((io.WebSocket socket) => this.socket = socket)
        .doOnData((io.WebSocket _) => _onOpen())
        .flatMap<dynamic>((io.WebSocket socket) => socket)
        .where((dynamic data) => data != null)
        .doOnData((dynamic event) => log.d('onMessage: $event'))
        .listen(
          _onData,
          onError: (dynamic e) => onError('websocket error', e),
          onDone: () => _onClose(),
        );
  }

  @override
  Observable<Event> _doClose() => socket != null
      ? new Observable<void>.fromFuture(socket?.close(1000, ''))
          .doOnData((dynamic _) => socket = null)
          .map((dynamic _) => new Event(Transport.eventClose))
      : new Observable<Event>.just(new Event(Transport.eventClose));

  @override
  Observable<Event> _write(List<Packet> packets) => new Observable<Packet>.fromIterable(packets)
      .takeWhile((Packet _) => readyState == Transport.stateOpening || readyState == Transport.stateOpen)
      .map<dynamic>((Packet packet) => Parser.encodePacket(packet))
      .doOnData((dynamic encoded) => socket.add(encoded))
      .map((dynamic _) => null);

  String get uri {
    final Map<String, String> query = options?.query ?? <String, String>{};
    final String schema = options.secure ? 'wss' : 'ws';

    String port = '';

    if (options.port > 0 && ((schema == 'wss' && options.port != 443) || (schema == 'ws' && options.port != 80))) {
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

  bool badCertificateCallback(io.X509Certificate cert, String host, int port) {
    log.e('bad cert: ${base64Encode(cert.der)}');
    return true;
  }
}
