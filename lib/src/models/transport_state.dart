library transport_state;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'transport_state.g.dart';

class TransportState extends EnumClass {
  const TransportState._(String name) : super(name);

  static const TransportState opening = _$opening;
  static const TransportState open = _$open;
  static const TransportState closed = _$closed;
  static const TransportState paused = _$paused;

  static BuiltSet<TransportState> get values => _$ReadyStateValues;

  static TransportState valueOf(String name) => _$ReadyStateValueOf(name);

  static Serializer<TransportState> get serializer => _$transportStateSerializer;
}
