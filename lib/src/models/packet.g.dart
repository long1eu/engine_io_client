// GENERATED CODE - DO NOT MODIFY BY HAND

part of packet;

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

Serializer<Packet> _$packetSerializer = new _$PacketSerializer();

class _$PacketSerializer implements StructuredSerializer<Packet> {
  @override
  final Iterable<Type> types = const [Packet, _$Packet];
  @override
  final String wireName = 'Packet';

  @override
  Iterable serialize(Serializers serializers, Packet object,
      {FullType specifiedType: FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = <Object>[
      'type',
      serializers.serialize(object.type,
          specifiedType: const FullType(PacketType)),
    ];
    if (object.data != null) {
      result
        ..add('data')
        ..add(serializers.serialize(object.data, specifiedType: parameterT));
    }

    return result;
  }

  @override
  Packet deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType: FullType.unspecified}) {
    final isUnderspecified =
        specifiedType.isUnspecified || specifiedType.parameters.isEmpty;
    if (!isUnderspecified) serializers.expectBuilder(specifiedType);
    final parameterT =
        isUnderspecified ? FullType.object : specifiedType.parameters[0];

    final result = isUnderspecified
        ? new PacketBuilder<Object>()
        : serializers.newBuilder(specifiedType) as PacketBuilder;

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'type':
          result.type = serializers.deserialize(value,
              specifiedType: const FullType(PacketType)) as PacketType;
          break;
        case 'data':
          result.data =
              serializers.deserialize(value, specifiedType: parameterT);
          break;
      }
    }

    return result.build();
  }
}

// Error: Please make the following changes to use BuiltValue:
//
//        1. Stop class extending other classes. Only "implements" and "extends Object with" are allowed.
