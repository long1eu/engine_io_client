import 'dart:io';

class XhrOptions {
  XhrOptions({this.uri, this.method = 'GET', this.client, this.data});

  final String uri;
  final String method;
  final HttpClient client;
  final Object data;

  XhrOptions copyWith(String uri, String method, HttpClient client, Object data) {
    return new XhrOptions(
      uri: uri ?? this.uri,
      method: method ?? this.method,
      client: client ?? this.client,
      data: data ?? this.data,
    );
  }
}
