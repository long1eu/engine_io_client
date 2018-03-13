// GENERATED CODE - DO NOT MODIFY BY HAND

part of transport_state;

// **************************************************************************
// Generator: BuiltValueGenerator
// **************************************************************************

// ignore_for_file: always_put_control_body_on_new_line
// ignore_for_file: annotate_overrides
// ignore_for_file: avoid_annotating_with_dynamic
// ignore_for_file: avoid_returning_this
// ignore_for_file: omit_local_variable_types
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: sort_constructors_first

const TransportState _$opening = const TransportState._('opening');
const TransportState _$open = const TransportState._('open');
const TransportState _$closed = const TransportState._('closed');
const TransportState _$paused = const TransportState._('paused');

TransportState _$ReadyStateValueOf(String name) {
  switch (name) {
    case 'opening':
      return _$opening;
    case 'open':
      return _$open;
    case 'closed':
      return _$closed;
    case 'paused':
      return _$paused;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<TransportState> _$ReadyStateValues =
    new BuiltSet<TransportState>(const <TransportState>[
  _$opening,
  _$open,
  _$closed,
  _$paused,
]);

Serializer<TransportState> _$transportStateSerializer =
    new _$TransportStateSerializer();

class _$TransportStateSerializer
    implements PrimitiveSerializer<TransportState> {
  @override
  final Iterable<Type> types = const <Type>[TransportState];
  @override
  final String wireName = 'TransportState';

  @override
  Object serialize(Serializers serializers, TransportState object,
          {FullType specifiedType: FullType.unspecified}) =>
      object.name;

  @override
  TransportState deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType: FullType.unspecified}) =>
      TransportState.valueOf(serialized as String);
}
