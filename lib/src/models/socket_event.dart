library socket_event;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'socket_event.g.dart';

class SocketEvent extends EnumClass {
  const SocketEvent._(String name) : super(name);

  static const SocketEvent open = _$open;
  static const SocketEvent close = _$close;
  static const SocketEvent message = _$message;
  static const SocketEvent error = _$error;
  static const SocketEvent upgradeError = _$upgradeError;
  static const SocketEvent flush = _$flush;
  static const SocketEvent drain = _$drain;
  static const SocketEvent handshake = _$handshake;
  static const SocketEvent upgrading = _$upgrading;
  static const SocketEvent upgrade = _$upgrade;
  static const SocketEvent packet = _$packet;
  static const SocketEvent packetCreate = _$packetCreate;
  static const SocketEvent heartbeat = _$heartbeat;
  static const SocketEvent data = _$data;
  static const SocketEvent ping = _$ping;
  static const SocketEvent pong = _$pong;
  static const SocketEvent transport = _$transport;

  static BuiltSet<SocketEvent> get values => _$SocketEventValues;

  static SocketEvent valueOf(String name) => _$SocketEventValueOf(name);

  static Serializer<SocketEvent> get serializer => _$socketEventSerializer;
}
