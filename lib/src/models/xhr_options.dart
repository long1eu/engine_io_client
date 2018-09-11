import 'dart:io';

class XhrOptions {
  XhrOptions(this.uri, this.method, this.client, this.data);

  factory XhrOptions.get(String uri, dynamic data, HttpClient client) => XhrOptions(uri, 'GET', client, data);

  factory XhrOptions.post(String uri, dynamic data, HttpClient client) => XhrOptions(uri, 'POST', client, data);

  final String uri;

  final String method;

  final HttpClient client;

  final Object data;
}
