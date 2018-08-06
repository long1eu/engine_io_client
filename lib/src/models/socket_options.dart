import 'dart:io' show SecurityContext;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:engine_io_client/src/engine_io/client/socket.dart';
import 'package:engine_io_client/src/engine_io/client/transport.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/transport_options.dart';

class SocketOptions extends TransportOptions {
  const SocketOptions({
    List<String> transports,
    bool upgrade,
    bool rememberUpgrade,
    this.host,
    this.rawQuery,
    Map<String, TransportOptions> transportOptions,
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
  })  : transports = transports ?? const <String>[Polling.NAME, WebSocket.NAME],
        upgrade = upgrade ?? true,
        rememberUpgrade = rememberUpgrade ?? false,
        transportOptions = transportOptions ?? const <String, TransportOptions>{},
        super(
          hostname: hostname ?? 'localhost',
          path: path ?? '/engine.io',
          timestampParam: timestampParam ?? 't',
          secure: secure ?? false,
          timestampRequests: timestampRequests ?? false,
          port: port ?? -1,
          policyPort: policyPort ?? -1,
          query: query,
          headers: headers,
          socket: socket,
          securityContext: securityContext,
          cookieJar: cookieJar,
        );

  factory SocketOptions.fromUri(Uri uri, [SocketOptions options]) {
    return (options ?? const SocketOptions()).copyWith(
      host: uri.host ?? 'localhost',
      secure: uri.scheme == 'https' || uri.scheme == 'wss',
      port: uri.port == null || uri.port == 0 ? -1 : uri.port,
      rawQuery: uri.query.isNotEmpty ? uri.query : options?.rawQuery,
    );
  }

  final List<String> transports;

  final bool upgrade;

  final bool rememberUpgrade;

  final String host;

  final String rawQuery;

  final Map<String, TransportOptions> transportOptions;

  @override
  TransportOptions copyWith({
    List<String> transports,
    bool upgrade,
    bool rememberUpgrade,
    String host,
    String rawQuery,
    Map<String, TransportOptions> transportOptions,
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
    return new SocketOptions(
      transports: transports ?? this.transports,
      upgrade: upgrade ?? this.upgrade,
      rememberUpgrade: rememberUpgrade ?? this.rememberUpgrade,
      host: host ?? this.host,
      rawQuery: rawQuery ?? this.rawQuery,
      transportOptions: transportOptions ?? this.transportOptions,
      hostname: hostname ?? this.hostname,
      path: path ?? this.path,
      timestampParam: timestampParam ?? this.timestampParam,
      secure: secure ?? this.secure ?? false,
      timestampRequests: timestampRequests ?? this.timestampRequests ?? false,
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
    return (new ToStringHelper('SocketOptions')
          ..add('transports', '$transports')
          ..add('upgrade', '$upgrade')
          ..add('rememberUpgrade', '$rememberUpgrade')
          ..add('host', '$host')
          ..add('rawQuery', '$rawQuery')
          ..add('transportOptions', '$transportOptions')
          ..add('TransportOptions', '${super.toString()}'))
        .toString();
  }
}
