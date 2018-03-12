import 'dart:convert';

import 'package:flutter_logger/flutter_logger.dart';
import 'package:http/http.dart';
import 'package:socket_io/src/emitter/emitter.dart';
import 'package:socket_io/src/models/xhr_event.dart';
import 'package:socket_io/src/models/xhr_options.dart';

const String BINARY_CONTENT_TYPE = 'application/octet-stream';
const String TEXT_CONTENT_TYPE = 'text/plain;charset=UTF-8';

class XhrRequest extends Emitter {
  static final Log log = new Log('XhrRequest');

  XhrRequest(this.options);

  StreamedResponse response;

  final XhrOptions<dynamic> options;

  void create() async {
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

    options.client.send(request);

    try {
      response = await request.send();
      onResponseHeaders(response.headers.map((String key, String value) {
        return new MapEntry<String, List<String>>(key, <String>[value]);
      }));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        onLoad();
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

  void onError(Exception error) {
    emit(XhrEvent.error.name, error);
  }

  void onRequestHeaders(Map<String, List<String>> headers) {
    emit(XhrEvent.requestHeaders.name, headers);
  }

  void onResponseHeaders(Map<String, List<String>> headers) {
    emit(XhrEvent.responseHeaders.name, headers);
  }

  void onLoad() async {
    final String contentType = response.headers['content-type'];

    try {
      if (contentType.toLowerCase() == BINARY_CONTENT_TYPE) {
        onData(response.stream.toBytes());
      } else {
        final String body = await utf8.decodeStream(response.stream);
        onData(body);
      }
    } catch (e) {
      onError(e);
    }
  }
}
