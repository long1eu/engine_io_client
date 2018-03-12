// GENERATED CODE - DO NOT MODIFY BY HAND

part of xhr_event;

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

const XhrEvent _$success = const XhrEvent._('success');
const XhrEvent _$data = const XhrEvent._('data');
const XhrEvent _$error = const XhrEvent._('error');
const XhrEvent _$requestHeaders = const XhrEvent._('requestHeaders');
const XhrEvent _$responseHeaders = const XhrEvent._('responseHeaders');

XhrEvent _$XhrEventValueOf(String name) {
  switch (name) {
    case 'success':
      return _$success;
    case 'data':
      return _$data;
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

final BuiltSet<XhrEvent> _$XhrEventValues =
    new BuiltSet<XhrEvent>(const <XhrEvent>[
  _$success,
  _$data,
  _$error,
  _$requestHeaders,
  _$responseHeaders,
]);

Serializer<XhrEvent> _$xhrEventSerializer = new _$XhrEventSerializer();

class _$XhrEventSerializer implements PrimitiveSerializer<XhrEvent> {
  @override
  final Iterable<Type> types = const <Type>[XhrEvent];
  @override
  final String wireName = 'XhrEvent';

  @override
  Object serialize(Serializers serializers, XhrEvent object,
          {FullType specifiedType: FullType.unspecified}) =>
      object.name;

  @override
  XhrEvent deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType: FullType.unspecified}) =>
      XhrEvent.valueOf(serialized as String);
}
