// GENERATED CODE - DO NOT MODIFY BY HAND

part of polling_event;

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

const PollingEvent _$poll = const PollingEvent._('poll');
const PollingEvent _$pollComplete = const PollingEvent._('pollComplete');

PollingEvent _$PollingEventValueOf(String name) {
  switch (name) {
    case 'poll':
      return _$poll;
    case 'pollComplete':
      return _$pollComplete;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<PollingEvent> _$PollingEventValues =
    new BuiltSet<PollingEvent>(const <PollingEvent>[
  _$poll,
  _$pollComplete,
]);

Serializer<PollingEvent> _$pollingEventSerializer =
    new _$PollingEventSerializer();

class _$PollingEventSerializer implements PrimitiveSerializer<PollingEvent> {
  @override
  final Iterable<Type> types = const <Type>[PollingEvent];
  @override
  final String wireName = 'PollingEvent';

  @override
  Object serialize(Serializers serializers, PollingEvent object,
          {FullType specifiedType: FullType.unspecified}) =>
      object.name;

  @override
  PollingEvent deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType: FullType.unspecified}) =>
      PollingEvent.valueOf(serialized as String);
}
