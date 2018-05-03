import 'dart:io';

import 'package:engine_io_client/src/logger.dart';

class XhrOptions {
  XhrOptions({this.uri, this.method = 'GET', this.headers, this.client, this.data});

  final String uri;
  final String method;
  final Map<String, List<String>> headers;
  final HttpClient client;
  final Object data;

  XhrOptions copyWith(String uri, String method, Map<String, List<String>> headers, HttpClient client, Object data) {
    return new XhrOptions(
      uri: uri ?? this.uri,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      client: client ?? this.client,
      data: data ?? this.data,
    );
  }

  @override
  String toString() {
    return (new ToStringHelper('HandshakeData')
          ..add('uri', '$uri')
          ..add('method', '$method')
          ..add('headers', '$headers')
          ..add('data', '$data'))
        .toString();
  }
}
