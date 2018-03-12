// GENERATED CODE - DO NOT MODIFY BY HAND

part of packet_type;

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

const PacketType _$open = const PacketType._('open');
const PacketType _$close = const PacketType._('close');
const PacketType _$ping = const PacketType._('ping');
const PacketType _$pong = const PacketType._('pong');
const PacketType _$message = const PacketType._('message');
const PacketType _$upgrade = const PacketType._('upgrade');
const PacketType _$noop = const PacketType._('noop');
const PacketType _$error = const PacketType._('error');

PacketType _$PacketTypeValueOf(String name) {
  switch (name) {
    case 'open':
      return _$open;
    case 'close':
      return _$close;
    case 'ping':
      return _$ping;
    case 'pong':
      return _$pong;
    case 'message':
      return _$message;
    case 'upgrade':
      return _$upgrade;
    case 'noop':
      return _$noop;
    case 'error':
      return _$error;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<PacketType> _$PacketTypeValues =
    new BuiltSet<PacketType>(const <PacketType>[
  _$open,
  _$close,
  _$ping,
  _$pong,
  _$message,
  _$upgrade,
  _$noop,
  _$error,
]);

Serializer<PacketType> _$packetTypeSerializer = new _$PacketTypeSerializer();

class _$PacketTypeSerializer implements PrimitiveSerializer<PacketType> {
  @override
  final Iterable<Type> types = const <Type>[PacketType];
  @override
  final String wireName = 'PacketType';

  @override
  Object serialize(Serializers serializers, PacketType object,
          {FullType specifiedType: FullType.unspecified}) =>
      object.name;

  @override
  PacketType deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType: FullType.unspecified}) =>
      PacketType.valueOf(serialized as String);
}
