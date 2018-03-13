// GENERATED CODE - DO NOT MODIFY BY HAND

part of handshake_data;

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

Serializer<HandshakeData> _$handshakeDataSerializer =
    new _$HandshakeDataSerializer();

class _$HandshakeDataSerializer implements StructuredSerializer<HandshakeData> {
  @override
  final Iterable<Type> types = const [HandshakeData, _$HandshakeData];
  @override
  final String wireName = 'HandshakeData';

  @override
  Iterable serialize(Serializers serializers, HandshakeData object,
      {FullType specifiedType: FullType.unspecified}) {
    final result = <Object>[
      'sid',
      serializers.serialize(object.sessionId,
          specifiedType: const FullType(String)),
      'upgrades',
      serializers.serialize(object.upgrades,
          specifiedType:
              const FullType(BuiltList, const [const FullType(String)])),
      'pingInterval',
      serializers.serialize(object.pingInterval,
          specifiedType: const FullType(int)),
      'pingTimeout',
      serializers.serialize(object.pingTimeout,
          specifiedType: const FullType(int)),
    ];

    return result;
  }

  @override
  HandshakeData deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType: FullType.unspecified}) {
    final result = new HandshakeDataBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'sid':
          result.sessionId = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'upgrades':
          result.upgrades.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(String)]))
              as BuiltList);
          break;
        case 'pingInterval':
          result.pingInterval = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'pingTimeout':
          result.pingTimeout = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$HandshakeData extends HandshakeData {
  @override
  final String sessionId;
  @override
  final BuiltList<String> upgrades;
  @override
  final int pingInterval;
  @override
  final int pingTimeout;

  factory _$HandshakeData([void updates(HandshakeDataBuilder b)]) =>
      (new HandshakeDataBuilder()..update(updates)).build();

  _$HandshakeData._(
      {this.sessionId, this.upgrades, this.pingInterval, this.pingTimeout})
      : super._() {
    if (sessionId == null)
      throw new BuiltValueNullFieldError('HandshakeData', 'sessionId');
    if (upgrades == null)
      throw new BuiltValueNullFieldError('HandshakeData', 'upgrades');
    if (pingInterval == null)
      throw new BuiltValueNullFieldError('HandshakeData', 'pingInterval');
    if (pingTimeout == null)
      throw new BuiltValueNullFieldError('HandshakeData', 'pingTimeout');
  }

  @override
  HandshakeData rebuild(void updates(HandshakeDataBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  HandshakeDataBuilder toBuilder() => new HandshakeDataBuilder()..replace(this);

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! HandshakeData) return false;
    return sessionId == other.sessionId &&
        upgrades == other.upgrades &&
        pingInterval == other.pingInterval &&
        pingTimeout == other.pingTimeout;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, sessionId.hashCode), upgrades.hashCode),
            pingInterval.hashCode),
        pingTimeout.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('HandshakeData')
          ..add('sessionId', sessionId)
          ..add('upgrades', upgrades)
          ..add('pingInterval', pingInterval)
          ..add('pingTimeout', pingTimeout))
        .toString();
  }
}

class HandshakeDataBuilder
    implements Builder<HandshakeData, HandshakeDataBuilder> {
  _$HandshakeData _$v;

  String _sessionId;
  String get sessionId => _$this._sessionId;
  set sessionId(String sessionId) => _$this._sessionId = sessionId;

  ListBuilder<String> _upgrades;
  ListBuilder<String> get upgrades =>
      _$this._upgrades ??= new ListBuilder<String>();
  set upgrades(ListBuilder<String> upgrades) => _$this._upgrades = upgrades;

  int _pingInterval;
  int get pingInterval => _$this._pingInterval;
  set pingInterval(int pingInterval) => _$this._pingInterval = pingInterval;

  int _pingTimeout;
  int get pingTimeout => _$this._pingTimeout;
  set pingTimeout(int pingTimeout) => _$this._pingTimeout = pingTimeout;

  HandshakeDataBuilder();

  HandshakeDataBuilder get _$this {
    if (_$v != null) {
      _sessionId = _$v.sessionId;
      _upgrades = _$v.upgrades?.toBuilder();
      _pingInterval = _$v.pingInterval;
      _pingTimeout = _$v.pingTimeout;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(HandshakeData other) {
    if (other == null) throw new ArgumentError.notNull('other');
    _$v = other as _$HandshakeData;
  }

  @override
  void update(void updates(HandshakeDataBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$HandshakeData build() {
    _$HandshakeData _$result;
    try {
      _$result = _$v ??
          new _$HandshakeData._(
              sessionId: sessionId,
              upgrades: upgrades.build(),
              pingInterval: pingInterval,
              pingTimeout: pingTimeout);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'upgrades';
        upgrades.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'HandshakeData', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}
