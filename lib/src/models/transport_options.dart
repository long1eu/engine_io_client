import 'dart:convert';
import 'dart:io' show SecurityContext;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:engine_io_client/src/engine_io/client/socket.dart';
import 'package:engine_io_client/src/engine_io/custom/websocket_impl.dart';

// Note to self: When adding new filed make sure to add the to the [_createTransport] method in socket.dart
class TransportOptions {
  const TransportOptions({
    this.hostname,
    this.path,
    this.timestampParam,
    bool secure,
    bool timestampRequests,
    int port,
    int policyPort,
    this.query,
    this.onRequestHeaders,
    this.onResponseHeaders,
    this.socket,
    this.securityContext,
    this.cookieJar,
  })  : secure = secure ?? false,
        timestampRequests = timestampRequests ?? false,
        port = port ?? -1,
        policyPort = policyPort ?? -1;

  final String hostname;

  final String path;

  final String timestampParam;

  final bool secure;

  final bool timestampRequests;

  final int port;

  final int policyPort;

  final Map<String, String> query;

  final OnRequestHeaders onRequestHeaders;

  final OnResponseHeaders onResponseHeaders;

  final Socket socket;

  final SecurityContext securityContext;

  final CookieJar cookieJar;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cookieJar': cookieJar,
      'hostname': hostname,
      'path': path,
      'timestampParam': timestampParam,
      'secure': secure,
      'timestampRequests': timestampRequests,
      'port': port,
      'policyPort': policyPort,
      'query': query,
      'socket': socket,
    };
  }

  void updateQuery(String key, String value) => query[key] = value;

  void setQuery(Map<String, String> values) {
    query.clear();
    query.addAll(values);
  }

  TransportOptions copyWith({
    String hostname,
    String path,
    String timestampParam,
    bool secure,
    bool timestampRequests,
    int port,
    int policyPort,
    Map<String, String> query,
    OnRequestHeaders onRequestHeaders,
    OnResponseHeaders onResponseHeaders,
    Socket socket,
    SecurityContext securityContext,
    CookieJar cookieJar,
  }) {
    return TransportOptions(
      hostname: hostname ?? this.hostname,
      path: path ?? this.path,
      timestampParam: timestampParam ?? this.timestampParam,
      secure: secure ?? this.secure,
      timestampRequests: timestampRequests ?? this.timestampRequests,
      port: port ?? this.port,
      policyPort: policyPort ?? this.policyPort,
      query: query ?? this.query,
      onRequestHeaders: onRequestHeaders ?? this.onRequestHeaders,
      onResponseHeaders: onResponseHeaders ?? this.onResponseHeaders,
      socket: socket ?? this.socket,
      securityContext: securityContext ?? this.securityContext,
      cookieJar: cookieJar ?? this.cookieJar,
    );
  }

  @override
  String toString() => jsonEncode(toJson(), toEncodable: (Object it) => it.toString());
}
