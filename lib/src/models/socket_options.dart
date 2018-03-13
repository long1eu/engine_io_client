library socket_options;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:socket_io/src/engine_io/client/transports/polling.dart';
import 'package:socket_io/src/engine_io/client/transports/web_socket.dart';
import 'package:socket_io/src/models/transport_options.dart';

part 'socket_options.g.dart';

abstract class SocketOptions implements Built<SocketOptions, SocketOptionsBuilder> {
  factory SocketOptions([SocketOptionsBuilder updates(SocketOptionsBuilder b)]) {
    return new _$SocketOptions((SocketOptionsBuilder b) {
      return b
        ..path = '/engine.io'
        ..hostname = 'localhost'
        ..port = -1
        ..policyPort = -1
        ..secure = false
        ..upgrade = true
        ..timestampParam = 't'
        ..timestampRequests = false
        ..rememberUpgrade = false
        ..transportOptions = new MapBuilder<String, TransportOptions>()
        ..transports = new ListBuilder<String>(<String>[Polling.NAME, WebSocket.NAME])
        ..update(updates);
    });
  }

  factory SocketOptions.fromUri(Uri uri, SocketOptions options) {
    final SocketOptionsBuilder builder = options?.toBuilder() ?? new SocketOptionsBuilder();

    builder
      ..host = uri.host
      ..secure = uri.scheme == 'https' || uri.scheme == 'wss'
      ..port = uri.port
      ..rawQuery = uri.query.isNotEmpty ? uri.query : options.rawQuery;

    return builder.build();
  }

  SocketOptions._();

  BuiltList<String> get transports;

  bool get upgrade;

  bool get rememberUpgrade;

  @nullable
  String get host;

  @nullable
  String get rawQuery;

  BuiltMap<String, TransportOptions> get transportOptions;

  String get hostname;

  String get path;

  String get timestampParam;

  bool get secure;

  bool get timestampRequests;

  int get port;

  int get policyPort;

  BuiltMap<String, String> get query;

  static Serializer<SocketOptions> get serializer => _$socketOptionsSerializer;
}