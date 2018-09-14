import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/engine_io/custom/websocket_impl.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/xhr_event.dart';
import 'package:engine_io_client/src/models/xhr_options.dart';
import 'package:http/http.dart';

const String BINARY_CONTENT_TYPE = 'application/octet-stream';
const String TEXT_CONTENT_TYPE = 'text/plain; charset=UTF-8';

class RequestXhr extends Emitter {
  static final Log log = Log('EngineIo.RequestXhr');

  RequestXhr(this.options, this.onResponseHeaders, this.onRequestHeaders);

  StreamedResponse response;

  final XhrOptions options;
  final OnRequestHeaders onRequestHeaders;
  final OnResponseHeaders onResponseHeaders;

  Future<void> create() async {
    log.d('xhr open ${options.method}: ${options.uri}');
    Map<String, String> headers = <String, String>{};

    if (options.method == 'POST') {
      if (options.data is List<int>) {
        headers['content-type'] = BINARY_CONTENT_TYPE;
      } else {
        headers['content-type'] = TEXT_CONTENT_TYPE;
      }
    }

    headers['Accept'] = '*/*';
    log.d('onRequestHeaders: $onRequestHeaders');
    headers = onRequestHeaders?.call(headers) ?? headers;

    await Future<void>.delayed(const Duration(milliseconds: 100));

    log.d('sending xhr with url ${options.uri} | data ${options.data}');

    final Request request = Request(options.method, Uri.parse(options.uri));

    request.headers.addAll(headers);

    if (options.data is String) {
      request.body = options.data as String;
    } else if (options.data is List<int>) {
      request.bodyBytes = options.data as List<int>;
    }

    try {
      final ByteStream stream = request.finalize();

      final HttpClientRequest httpClientRequest = await options.client.openUrl(options.method, Uri.parse(options.uri));

      headers.forEach(httpClientRequest.headers.set);

      httpClientRequest
        ..followRedirects = true
        ..maxRedirects = 5
        ..contentLength = request.contentLength == null ? -1 : request.contentLength
        ..persistentConnection = true;

      final HttpClientResponse rawResponse = await stream.pipe(DelegatingStreamConsumer.typed(httpClientRequest));

      final Map<String, String> h = <String, String>{};
      rawResponse.headers.forEach((String key, List<String> values) => h[key] = values.join(','));

      response = StreamedResponse(
        DelegatingStream.typed<List<int>>(rawResponse),
        rawResponse.statusCode,
        contentLength: rawResponse.contentLength == -1 ? null : rawResponse.contentLength,
        request: request,
        headers: h,
        isRedirect: rawResponse.isRedirect,
        persistentConnection: rawResponse.persistentConnection,
        reasonPhrase: rawResponse.reasonPhrase,
      );

      onResponseHeaders?.call(response.headers);
      print(response.statusCode);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await onLoad();
      } else {
        onError(<Error>[StateError(response.statusCode.toString())]);
      }
    } catch (e) {
      log.e(e);
      onError(<dynamic>[e]);
    }
  }

  Future<void> onSuccess() async {
    await emit(XhrEvent.success);
  }

  /// Can be [String] or [List<int>]
  Future<void> onData(dynamic data) async {
    await emit(XhrEvent.data, <dynamic>[data]);
    await onSuccess();
  }

  Future<void> onError(List<dynamic> error) async {
    await emit(XhrEvent.error, error);
  }

  Future<void> onLoad() async {
    final String contentType = response.headers['content-type'].split(';')[0];
    try {
      if (contentType.toLowerCase() == BINARY_CONTENT_TYPE) {
        final Uint8List bytes = await response.stream.toBytes();
        await onData(bytes);
      } else {
        final String body = await response.stream.bytesToString();
        await onData(body);
      }
    } on Error catch (e) {
      await onError(<Error>[e]);
    }
  }
}
