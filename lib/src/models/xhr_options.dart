import 'dart:convert';
import 'dart:io';

class XhrOptions {
  XhrOptions(this.uri, this.method, this.client, this.data);

  factory XhrOptions.get(String uri, dynamic data, HttpClient client) => XhrOptions(uri, 'GET', client, data);

  factory XhrOptions.post(String uri, dynamic data, HttpClient client) => XhrOptions(uri, 'POST', client, data);

  final String uri;

  final String method;

  final HttpClient client;

  final Object data;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'uri': uri,
      'method': method,
      'data': data,
    };
  }

  @override
  String toString() => jsonEncode(toJson(), toEncodable: (Object it) => it.toString());
}
