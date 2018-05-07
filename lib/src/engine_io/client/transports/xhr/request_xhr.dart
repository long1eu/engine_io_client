part of '../../transport.dart';

const String BINARY_TYPE = 'application/octet-stream';
const String TEXT_CONTENT_TYPE = 'text/plain;charset=UTF-8';

class RequestXhr extends Emitter {
  static final Log log = new Log('EngineIo.RequestXhr');

  static const String eventSuccess = 'success';
  static const String eventData = 'data';
  static const String eventError = 'error';

  static const String eventResponseHeaders = 'responseHeaders';

  RequestXhr(this.options);

  final XhrOptions options;

  void create() {
    log.d('xhr open ${options.method}: ${options.uri}');
    final Map<String, List<String>> headers = options.headers ?? <String, List<String>>{};

    if (options.method == 'POST') {
      if (options.data is List<int>) {
        headers['content-type'] = <String>[BINARY_TYPE];
      } else {
        headers['content-type'] = <String>[TEXT_CONTENT_TYPE];
      }
    }
    headers['Accept'] = <String>['*/*'];
    log.d('sending xhr with url ${options.uri} | data ${options.data} | headers $headers');
    final Map<String, String> h = headers.map((String key, List<String> value) => new MapEntry<String, String>(key, value.first));

    final Future<Response> connection = options.method == 'GET'
        ? new IOClient(options.client).get(options.uri, headers: h)
        : new IOClient(options.client).post(options.uri, headers: h, body: options.data);

    new Observable<Response>.fromFuture(connection)
        .doOnData((Response response) {
          emit(RequestXhr.eventResponseHeaders, <Map<String, List<String>>>[
            response.headers.map((String key, String value) => new MapEntry<String, List<String>>(key, <String>[value]))
          ]);
        })
        .doOnData((Response response) => log.e('response: ${response.body}'))
        .map((Response res) {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            final String contentType = res.headers['content-type'].split(';')[0].toLowerCase();
            return contentType == BINARY_TYPE ? res.bodyBytes : res.body;
          } else
            throw new EngineIOError(log.tag, res.statusCode);
        })
        .listen(onData, onError: (dynamic e) => onError(<dynamic>[e]));
  }

  void onData(dynamic data) => emitAll(<Event>[
        new Event(RequestXhr.eventData, <dynamic>[data]),
        new Event(RequestXhr.eventSuccess)
      ]);

  void onError(List<dynamic> error) => emit(RequestXhr.eventError, error);
}
