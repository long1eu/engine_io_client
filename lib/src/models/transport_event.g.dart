// GENERATED CODE - DO NOT MODIFY BY HAND

part of transport_event;

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

const TransportEvent _$open = const TransportEvent._('open');
const TransportEvent _$close = const TransportEvent._('close');
const TransportEvent _$packet = const TransportEvent._('packet');
const TransportEvent _$drain = const TransportEvent._('drain');
const TransportEvent _$error = const TransportEvent._('error');
const TransportEvent _$requestHeaders =
    const TransportEvent._('requestHeaders');
const TransportEvent _$responseHeaders =
    const TransportEvent._('responseHeaders');

TransportEvent _$TransportEventValueOf(String name) {
  switch (name) {
    case 'open':
      return _$open;
    case 'close':
      return _$close;
    case 'packet':
      return _$packet;
    case 'drain':
      return _$drain;
    case 'error':
      return _$error;
    case 'requestHeaders':
      return _$requestHeaders;
    case 'responseHeaders':
      return _$responseHeaders;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<TransportEvent> _$TransportEventValues =
    new BuiltSet<TransportEvent>(const <TransportEvent>[
  _$open,
  _$close,
  _$packet,
  _$drain,
  _$error,
  _$requestHeaders,
  _$responseHeaders,
]);

Serializer<TransportEvent> _$transportEventSerializer =
    new _$TransportEventSerializer();

class _$TransportEventSerializer
    implements PrimitiveSerializer<TransportEvent> {
  @override
  final Iterable<Type> types = const <Type>[TransportEvent];
  @override
  final String wireName = 'TransportEvent';

  @override
  Object serialize(Serializers serializers, TransportEvent object,
          {FullType specifiedType: FullType.unspecified}) =>
      object.name;

  @override
  TransportEvent deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType: FullType.unspecified}) =>
      TransportEvent.valueOf(serialized as String);
}
