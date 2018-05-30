part of '../../transport.dart';

class PollingXhr extends Polling {
  static final Log log = new Log('EngineIo.PollingXhr');

  PollingXhr(TransportOptions options) : super(options);

  RequestXhr request([XhrOptions options]) {
    options = options ??
        new XhrOptions(
            uri: uri,
            client: new HttpClient(context: this.options.securityContext),
            headers: options?.headers ?? this.options.headers);
    final RequestXhr requestXhr = new RequestXhr(options);
    requestXhr
        .on(RequestXhr.eventResponseHeaders)
        .doOnData((Event event) => emit(Transport.eventResponseHeaders, event.args))
        .listen(null);

    return requestXhr;
  }

  @override
  Observable<Event> _doWrite$(dynamic data) {
    final XhrOptions xhrOptions =
        new XhrOptions(method: 'POST', data: data, client: new HttpClient(context: options.securityContext), uri: uri);
    final RequestXhr requestXhr = request(xhrOptions);

    requestXhr.on(RequestXhr.eventError).listen((Event event) => onError('xhr post error', event.args));
    requestXhr.create();

    return requestXhr.on(RequestXhr.eventSuccess);
  }

  @override
  void _poll(String caller) {
    final RequestXhr requestXhr = request();
    log.d('xhr poll $caller');
    polling = true;

    requestXhr.on(RequestXhr.eventData).listen((Event event) => _onData(event.args.isNotEmpty ? event.args[0] : null));
    requestXhr.on(RequestXhr.eventError).listen((Event event) => onError('xhr poll error', event.args));

    requestXhr.create();
  }
}
