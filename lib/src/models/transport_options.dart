import 'dart:io' show SecurityContext;

import 'package:engine_io_client/src/engine_io/client/socket.dart';

class TransportOptions {
  TransportOptions({
    this.hostname,
    this.path,
    this.timestampParam,
    this.secure = false,
    this.timestampRequests,
    this.port = -1,
    this.policyPort = -1,
    this.query,
    this.socket,
    this.securityContext,
  });

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

  TransportOptions copyWith(
      {String hostname,
      String path,
      String timestampParam,
      bool secure,
      bool timestampRequests,
      int port,
      int policyPort,
      Map<String, String> query,
      Socket socket,
      SecurityContext securityContext}) {
    return new TransportOptions(
        hostname: hostname ?? this.hostname,
        path: path ?? this.path,
        timestampParam: timestampParam ?? this.timestampParam,
        secure: secure ?? this.secure,
        timestampRequests: timestampRequests ?? this.timestampRequests,
        port: port ?? this.port,
        policyPort: policyPort ?? this.policyPort,
        query: query ?? this.query,
        socket: socket ?? this.socket,
        securityContext: securityContext ?? this.securityContext);
  }

  @override
  String toString() {
    return 'TransportOptions{\n'
        '\thostname: $hostname, \n'
        '\tpath: $path, \n'
        '\ttimestampParam: $timestampParam, \n'
        '\tsecure: $secure, \n'
        '\ttimestampRequests: $timestampRequests, \n'
        '\tport: $port, \n'
        '\tpolicyPort: $policyPort, \n'
        '\tquery: $query, \n'
        '\tsocket: $socket, \n'
        '\tsecurityContext: $securityContext\n'
        '\t}\n';
  }
}
