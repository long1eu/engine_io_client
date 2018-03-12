// GENERATED CODE - DO NOT MODIFY BY HAND

part of ready_state;

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

const ReadyState _$opening = const ReadyState._('opening');
const ReadyState _$open = const ReadyState._('open');
const ReadyState _$closed = const ReadyState._('closed');
const ReadyState _$paused = const ReadyState._('paused');

ReadyState _$ReadyStateValueOf(String name) {
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

final BuiltSet<ReadyState> _$ReadyStateValues =
    new BuiltSet<ReadyState>(const <ReadyState>[
  _$opening,
  _$open,
  _$closed,
  _$paused,
]);

Serializer<ReadyState> _$readyStateSerializer = new _$ReadyStateSerializer();

class _$ReadyStateSerializer implements PrimitiveSerializer<ReadyState> {
  @override
  final Iterable<Type> types = const <Type>[ReadyState];
  @override
  final String wireName = 'ReadyState';

  @override
  Object serialize(Serializers serializers, ReadyState object,
          {FullType specifiedType: FullType.unspecified}) =>
      object.name;

  @override
  ReadyState deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType: FullType.unspecified}) =>
      ReadyState.valueOf(serialized as String);
}
