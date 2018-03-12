library ready_state;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ready_state.g.dart';

class ReadyState extends EnumClass {
  const ReadyState._(String name) : super(name);

  static const ReadyState opening = _$opening;
  static const ReadyState open = _$open;
  static const ReadyState closed = _$closed;
  static const ReadyState paused = _$paused;

  static BuiltSet<ReadyState> get values => _$ReadyStateValues;

  static ReadyState valueOf(String name) => _$ReadyStateValueOf(name);

  static Serializer<ReadyState> get serializer => _$readyStateSerializer;
}
