import 'dart:convert';
import 'dart:io' show SecurityContext;

import 'package:engine_io_client/src/engine_io/client/socket.dart';

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
    this.socket,
    this.securityContext,
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

  final Socket socket;

  final SecurityContext securityContext;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
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

  TransportOptions copyWith({
    String hostname,
    String path,
    String timestampParam,
    bool secure,
    bool timestampRequests,
    int port,
    int policyPort,
    Map<String, String> query,
    Socket socket,
    SecurityContext securityContext,
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
      socket: socket ?? this.socket,
      securityContext: securityContext ?? this.securityContext,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
