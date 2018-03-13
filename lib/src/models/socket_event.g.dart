// GENERATED CODE - DO NOT MODIFY BY HAND

part of socket_event;

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

const SocketEvent _$open = const SocketEvent._('open');
const SocketEvent _$close = const SocketEvent._('close');
const SocketEvent _$message = const SocketEvent._('message');
const SocketEvent _$error = const SocketEvent._('error');
const SocketEvent _$upgradeError = const SocketEvent._('upgradeError');
const SocketEvent _$flush = const SocketEvent._('flush');
const SocketEvent _$drain = const SocketEvent._('drain');
const SocketEvent _$handshake = const SocketEvent._('handshake');
const SocketEvent _$upgrading = const SocketEvent._('upgrading');
const SocketEvent _$upgrade = const SocketEvent._('upgrade');
const SocketEvent _$packet = const SocketEvent._('packet');
const SocketEvent _$packet_create = const SocketEvent._('packetCreate');
const SocketEvent _$heartbeat = const SocketEvent._('heartbeat');
const SocketEvent _$data = const SocketEvent._('data');
const SocketEvent _$ping = const SocketEvent._('ping');
const SocketEvent _$pong = const SocketEvent._('pong');
const SocketEvent _$transport = const SocketEvent._('transport');

SocketEvent _$SocketEventValueOf(String name) {
  switch (name) {
    case 'open':
      return _$open;
    case 'close':
      return _$close;
    case 'message':
      return _$message;
    case 'error':
      return _$error;
    case 'upgradeError':
      return _$upgradeError;
    case 'flush':
      return _$flush;
    case 'drain':
      return _$drain;
    case 'handshake':
      return _$handshake;
    case 'upgrading':
      return _$upgrading;
    case 'upgrade':
      return _$upgrade;
    case 'packet':
      return _$packet;
    case 'packetCreate':
      return _$packet_create;
    case 'heartbeat':
      return _$heartbeat;
    case 'data':
      return _$data;
    case 'ping':
      return _$ping;
    case 'pong':
      return _$pong;
    case 'transport':
      return _$transport;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<SocketEvent> _$SocketEventValues =
    new BuiltSet<SocketEvent>(const <SocketEvent>[
  _$open,
  _$close,
  _$message,
  _$error,
  _$upgradeError,
  _$flush,
  _$drain,
  _$handshake,
  _$upgrading,
  _$upgrade,
  _$packet,
  _$packet_create,
  _$heartbeat,
  _$data,
  _$ping,
  _$pong,
  _$transport,
]);

Serializer<SocketEvent> _$socketEventSerializer = new _$SocketEventSerializer();

class _$SocketEventSerializer implements PrimitiveSerializer<SocketEvent> {
  @override
  final Iterable<Type> types = const <Type>[SocketEvent];
  @override
  final String wireName = 'SocketEvent';

  @override
  Object serialize(Serializers serializers, SocketEvent object,
          {FullType specifiedType: FullType.unspecified}) =>
      object.name;

  @override
  SocketEvent deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType: FullType.unspecified}) =>
      SocketEvent.valueOf(serialized as String);
}
