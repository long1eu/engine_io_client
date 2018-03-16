import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/xhr_event.dart';
import 'package:engine_io_client/src/models/xhr_options.dart';

const String BINARY_CONTENT_TYPE = 'application/octet-stream';
const String TEXT_CONTENT_TYPE = 'text/plain; charset=UTF-8';

class RequestXhr extends Emitter {
  static final Log log = new Log('RequestXhr');

  RequestXhr(this.options);

  StreamedResponse response;

  final XhrOptions options;

  Future<Null> create() async {
    log.d('xhr open ${options.method}: ${options.uri}');
    final Map<String, List<String>> headers = <String, List<String>>{};

    if (options.method == 'POST') {
      if (options.data is List<int>) {
        headers['content-type'] = <String>[BINARY_CONTENT_TYPE];
      } else {
        headers['content-type'] = <String>[TEXT_CONTENT_TYPE];
      }
    }

    headers['Accept'] = <String>['*/*'];

    onRequestHeaders(headers);

    log.d('sending xhr with url ${options.uri} | data ${options.data}');

    final Request request = new Request(options.method, Uri.parse(options.uri));
    request.headers.addAll(headers.map((String key, List<String> value) => new MapEntry<String, String>(key, value.first)));

    if (options.data is String) {
      request.body = options.data;
    } else if (options.data is List<int>) {
      request.bodyBytes = options.data;
    }

    try {
      response = await options.client.send(request);

      onResponseHeaders(response.headers.map((String key, String value) {
        return new MapEntry<String, List<String>>(key, <String>[value]);
      }));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await onLoad();
      } else {
        onError(new Exception((response.statusCode)));
      }
    } catch (e) {
      onError(e);
    }
  }

  void onSuccess() {
    emit(XhrEvent.success.name);
  }

  void onData(dynamic data) {
    emit(XhrEvent.data.name, data);
    onSuccess();
  }

  void onError(dynamic error) {
    emit(XhrEvent.error.name, error);
  }

  void onRequestHeaders(Map<String, List<String>> headers) {
    emit(XhrEvent.requestHeaders.name, headers);
  }

  void onResponseHeaders(Map<String, List<String>> headers) {
    emit(XhrEvent.responseHeaders.name, headers);
  }

  Future<Null> onLoad() async {
    final String contentType = response.headers['content-type'].split(';')[0];
    try {
      if (contentType.toLowerCase() == BINARY_CONTENT_TYPE) {
        final Uint8List bytes = await response.stream.toBytes();
        onData(bytes);
      } else {
        final String body = await response.stream.bytesToString();
        onData(body);
      }
    } catch (e) {
      onError(e);
    }
  }
}
