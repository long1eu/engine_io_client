import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/engine_io/client/engine_io_error.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/xhr_options.dart';
import 'package:engine_io_client/src/transformers/on_error_resume_next_stream_transformer2.dart';
import 'package:http/http.dart';
import 'package:rxdart/rxdart.dart';

const String BINARY_TYPE = 'application/octet-stream';
const String TEXT_CONTENT_TYPE = 'text/plain; charset=UTF-8';

class RequestXhr extends Emitter {
  static final Log log = new Log('EngineIo.RequestXhr');

  static const String eventSuccess = 'success';
  static const String eventData = 'data';
  static const String eventError = 'error';
  static const String eventRequestHeaders = 'requestHeaders';
  static const String eventResponseHeaders = 'responseHeaders';

  RequestXhr(this.options);

  final XhrOptions options;

  Observable<Event> get create$ => new Observable<Map<String, List<String>>>.just(<String, List<String>>{})
      .doOnData((Map<String, List<String>> _) => log.d('xhr open ${options.method}: ${options.uri}'))
      .doOnData((Map<String, List<String>> h) => emit(RequestXhr.eventRequestHeaders, <Map<String, List<String>>>[h]))
      .delay(const Duration(milliseconds: 100))
      .map((Map<String, List<String>> headers) {
        if (options.method == 'POST') {
          if (options.data is List<int>) {
            headers['content-type'] = <String>[BINARY_TYPE];
          } else {
            headers['content-type'] = <String>[TEXT_CONTENT_TYPE];
          }
        }
        headers['Accept'] = <String>['*/*'];
        return headers;
      })
      .doOnData((Map<String, List<String>> headers) => log.d('sending xhr with url ${options.uri} | data ${options.data}'))
      .map((Map<String, List<String>> h) =>
          h.map((String key, List<String> value) => new MapEntry<String, String>(key, value.first)))
      .asyncMap((Map<String, String> headers) => options.method == 'GET'
          ? new IOClient(options.client).get(options.uri, headers: headers)
          : new IOClient(options.client).post(options.uri, headers: headers, body: options.data))
      .doOnData((Response response) {
        emit(RequestXhr.eventResponseHeaders, <Map<String, List<String>>>[
          response.headers.map((String key, String value) => new MapEntry<String, List<String>>(key, <String>[value]))
        ]);
      })
      .doOnData((Response response) => log.d('response: $response'))
      .where((Response response) => response.statusCode >= 200 && response.statusCode < 300)
      .flatMap((Response res) {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          return new Observable<String>.just(res.headers['content-type'])
              .map((String contentType) => contentType.split(';')[0].toLowerCase())
              .map((String contentType) => contentType.toLowerCase() == BINARY_TYPE ? res.bodyBytes : res.body)
              .flatMap((dynamic data) => onData(data));
          //.map((dynamic data) => new Event(RequestXhr.eventData, <dynamic>[data]));
        } else
          throw new EngineIOError(log.tag, res.statusCode);
      })
      .transform(new OnErrorResumeNextStreamTransformer2<Event>((dynamic e) => onError(<dynamic>[e])));

  Observable<Event> onData(dynamic data) => new Observable<String>.just('')
      .doOnData((String _) => emitAll(<Event>[
            new Event(RequestXhr.eventData, <dynamic>[data]),
            new Event(RequestXhr.eventSuccess)
          ]))
      .flatMap((String _) => new Observable<Event>.fromIterable(<Event>[
            new Event(RequestXhr.eventData, <dynamic>[data]),
            new Event(RequestXhr.eventSuccess)
          ]));

  Observable<Event> onError(List<dynamic> error) => new Observable<String>.just('')
      .doOnData((String _) => emit(RequestXhr.eventError, error))
      .map((String _) => new Event(RequestXhr.eventError, error));
}
