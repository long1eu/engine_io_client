// GENERATED CODE - DO NOT MODIFY BY HAND

part of socket_state;

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

const SocketState _$opening = const SocketState._('opening');
const SocketState _$open = const SocketState._('open');
const SocketState _$closing = const SocketState._('closing');
const SocketState _$closed = const SocketState._('closed');

SocketState _$SocketStateValueOf(String name) {
  switch (name) {
    case 'opening':
      return _$opening;
    case 'open':
      return _$open;
    case 'closing':
      return _$closing;
    case 'closed':
      return _$closed;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<SocketState> _$SocketStateValues =
    new BuiltSet<SocketState>(const <SocketState>[
  _$opening,
  _$open,
  _$closing,
  _$closed,
]);

Serializer<SocketState> _$socketStateSerializer = new _$SocketStateSerializer();

class _$SocketStateSerializer implements PrimitiveSerializer<SocketState> {
  @override
  final Iterable<Type> types = const <Type>[SocketState];
  @override
  final String wireName = 'SocketState';

  @override
  Object serialize(Serializers serializers, SocketState object,
          {FullType specifiedType: FullType.unspecified}) =>
      object.name;

  @override
  SocketState deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType: FullType.unspecified}) =>
      SocketState.valueOf(serialized as String);
}
