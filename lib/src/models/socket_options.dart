import 'dart:io' show SecurityContext;

import 'package:engine_io_client/src/engine_io/client/socket.dart';
import 'package:engine_io_client/src/engine_io/client/transports/polling.dart';
import 'package:engine_io_client/src/engine_io/client/transports/web_socket.dart';
import 'package:engine_io_client/src/engine_io/custom/websocket_impl.dart';
import 'package:engine_io_client/src/models/transport_options.dart';

class SocketOptions extends TransportOptions {
  const SocketOptions({
    this.host,
    this.rawQuery,
    List<String> transports,
    bool upgrade,
    bool rememberUpgrade,
    Map<String, TransportOptions> transportOptions,
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
  })  : upgrade = upgrade ?? true,
        rememberUpgrade = rememberUpgrade ?? false,
        transportOptions = transportOptions ?? const <String, TransportOptions>{},
        transports = transports ?? const <String>[Polling.NAME, WebSocket.NAME],
        super(
          hostname: hostname ?? 'localhost',
          path: path ?? '/engine.io',
          timestampParam: timestampParam ?? 't',
          secure: secure ?? false,
          timestampRequests: timestampRequests ?? false,
          port: port ?? -1,
          policyPort: policyPort ?? -1,
          query: query,
          onRequestHeaders: onRequestHeaders,
          onResponseHeaders: onResponseHeaders,
          socket: socket,
          securityContext: securityContext,
        );

  factory SocketOptions.fromUri(Uri uri, [SocketOptions options]) {
    return (options ??= const SocketOptions()).copyWith(
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
  SocketOptions copyWith({
    String host,
    String rawQuery,
    List<String> transports,
    bool upgrade,
    bool rememberUpgrade,
    Map<String, TransportOptions> transportOptions,
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
  }) {
    return SocketOptions(
      host: host ?? this.host,
      rawQuery: rawQuery ?? this.rawQuery,
      upgrade: upgrade ?? this.upgrade,
      rememberUpgrade: rememberUpgrade ?? this.rememberUpgrade,
      transportOptions: transportOptions ?? this.transportOptions,
      transports: transports ?? this.transports,
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
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'transports': transports,
      'upgrade': upgrade,
      'rememberUpgrade': rememberUpgrade,
      'host': host,
      'rawQuery': rawQuery,
      'transportOptions': transportOptions,
    }..addAll(super.toJson());
  }
}
