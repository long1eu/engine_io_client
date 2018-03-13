library socket_state;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'socket_state.g.dart';

class SocketState extends EnumClass {
  const SocketState._(String name) : super(name);

  static const SocketState opening = _$opening;
  static const SocketState open = _$open;
  static const SocketState closing = _$closing;
  static const SocketState closed = _$closed;

  static BuiltSet<SocketState> get values => _$SocketStateValues;

  static SocketState valueOf(String name) => _$SocketStateValueOf(name);

  static Serializer<SocketState> get serializer => _$socketStateSerializer;
}
