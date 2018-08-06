import 'dart:io' show SecurityContext;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:engine_io_client/src/engine_io/client/socket.dart';
import 'package:engine_io_client/src/logger.dart';

class TransportOptions {
  const TransportOptions({
    this.hostname,
    this.path,
    this.timestampParam,
    this.secure = false,
    this.timestampRequests = false,
    this.port = -1,
    this.policyPort = -1,
    this.query,
    this.headers,
    this.socket,
    this.securityContext,
    this.cookieJar,
  });

  final String hostname;

  final String path;

  final String timestampParam;

  final bool secure;

  final bool timestampRequests;

  final int port;

  final int policyPort;

  final Map<String, String> query;

  final Map<String, List<String>> headers;

  final Socket socket;

  final SecurityContext securityContext;

  final PersistCookieJar cookieJar;

  TransportOptions copyWith({
    String hostname,
    String path,
    String timestampParam,
    bool secure,
    bool timestampRequests,
    int port,
    int policyPort,
    Map<String, String> query,
    Map<String, List<String>> headers,
    Socket socket,
    SecurityContext securityContext,
    PersistCookieJar cookieJar,
  }) {
    return new TransportOptions(
      hostname: hostname ?? this.hostname,
      path: path ?? this.path,
      timestampParam: timestampParam ?? this.timestampParam,
      secure: secure ?? this.secure,
      timestampRequests: timestampRequests ?? this.timestampRequests,
      port: port ?? this.port,
      policyPort: policyPort ?? this.policyPort,
      query: query ?? this.query,
      headers: headers ?? this.headers,
      socket: socket ?? this.socket,
      securityContext: securityContext ?? this.securityContext,
      cookieJar: cookieJar ?? this.cookieJar,
    );
  }

  @override
  String toString() {
    return (new ToStringHelper('TransportOptions')
          ..add('hostname', '$hostname')
          ..add('path', '$path')
          ..add('timestampParam', '$timestampParam')
          ..add('secure', '$secure')
          ..add('timestampRequests', '$timestampRequests')
          ..add('port', '$port')
          ..add('policyPort', '$policyPort')
          ..add('query', '$query')
          ..add('headers', '$headers')
          ..add('securityContext', '$securityContext')
          ..add('cookieJar', '$cookieJar'))
        .toString();
  }
}
