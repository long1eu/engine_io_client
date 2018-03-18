import 'dart:async';
import 'dart:typed_data';

import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/xhr_event.dart';
import 'package:engine_io_client/src/models/xhr_options.dart';
import 'package:http/http.dart';

const String BINARY_CONTENT_TYPE = 'application/octet-stream';
const String TEXT_CONTENT_TYPE = 'text/plain; charset=UTF-8';

class RequestXhr extends Emitter {
  static final Log log = new Log('EngineIo.RequestXhr');

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

    onRequestHeaders(headers).then((_) async {
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

        await onResponseHeaders(response.headers.map((String key, String value) {
          return new MapEntry<String, List<String>>(key, <String>[value]);
        }));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          await onLoad();
        } else {
          onError(<Error>[new StateError(response.statusCode.toString())]);
        }
      } on Error catch (e) {
        onError(<Error>[e]);
      }
      print('result is $headers');
    });
  }

  Future<Null> onSuccess() async {
    await emit(XhrEvent.success);
  }

  /// Can be [String] or [List<int>]
  Future<Null> onData(dynamic data) async {
    await emit(XhrEvent.data, <dynamic>[data]);
    await onSuccess();
  }

  Future<Null> onError(List<Error> error) async {
    await emit(XhrEvent.error, error);
  }

  Future<Null> onRequestHeaders(Map<String, List<String>> headers) async {
    return await emit(XhrEvent.requestHeaders, <Map<String, List<String>>>[headers]);
  }

  Future<Null> onResponseHeaders(Map<String, List<String>> headers) async {
    await emit(XhrEvent.responseHeaders, <Map<String, List<String>>>[headers]);
  }

  Future<Null> onLoad() async {
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
