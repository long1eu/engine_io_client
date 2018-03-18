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
    final result = <Object>[
      'type',
      serializers.serialize(object.type, specifiedType: const FullType(String)),
    ];
    if (object.data != null) {
      result
        ..add('data')
        ..add(serializers.serialize(object.data,
            specifiedType: const FullType(Object)));
    }

    return result;
  }

  @override
  Packet deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType: FullType.unspecified}) {
    final result = new PacketBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'type':
          result.type = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'data':
          result.data = serializers.deserialize(value,
              specifiedType: const FullType(Object));
          break;
      }
    }

    return result.build();
  }
}

class _$Packet extends Packet {
  @override
  final String type;
  @override
  final Object data;

  factory _$Packet([void updates(PacketBuilder b)]) =>
      (new PacketBuilder()..update(updates)).build();

  _$Packet._({this.type, this.data}) : super._() {
    if (type == null) throw new BuiltValueNullFieldError('Packet', 'type');
  }

  @override
  Packet rebuild(void updates(PacketBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  PacketBuilder toBuilder() => new PacketBuilder()..replace(this);

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! Packet) return false;
    return type == other.type && data == other.data;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, type.hashCode), data.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Packet')
          ..add('type', type)
          ..add('data', data))
        .toString();
  }
}

class PacketBuilder implements Builder<Packet, PacketBuilder> {
  _$Packet _$v;

  String _type;
  String get type => _$this._type;
  set type(String type) => _$this._type = type;

  Object _data;
  Object get data => _$this._data;
  set data(Object data) => _$this._data = data;

  PacketBuilder();

  PacketBuilder get _$this {
    if (_$v != null) {
      _type = _$v.type;
      _data = _$v.data;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Packet other) {
    if (other == null) throw new ArgumentError.notNull('other');
    _$v = other as _$Packet;
  }

  @override
  void update(void updates(PacketBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$Packet build() {
    final _$result = _$v ?? new _$Packet._(type: type, data: data);
    replace(_$result);
    return _$result;
  }
}
