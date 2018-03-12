// GENERATED CODE - DO NOT MODIFY BY HAND

part of transport_options;

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

Serializer<TransportOptions> _$transportOptionsSerializer =
    new _$TransportOptionsSerializer();

class _$TransportOptionsSerializer
    implements StructuredSerializer<TransportOptions> {
  @override
  final Iterable<Type> types = const [TransportOptions, _$TransportOptions];
  @override
  final String wireName = 'TransportOptions';

  @override
  Iterable serialize(Serializers serializers, TransportOptions object,
      {FullType specifiedType: FullType.unspecified}) {
    final result = <Object>[
      'hostname',
      serializers.serialize(object.hostname,
          specifiedType: const FullType(String)),
      'path',
      serializers.serialize(object.path, specifiedType: const FullType(String)),
      'timestampRequests',
      serializers.serialize(object.timestampRequests,
          specifiedType: const FullType(bool)),
      'port',
      serializers.serialize(object.port, specifiedType: const FullType(int)),
      'policyPort',
      serializers.serialize(object.policyPort,
          specifiedType: const FullType(int)),
      'query',
      serializers.serialize(object.query,
          specifiedType: const FullType(BuiltMap,
              const [const FullType(String), const FullType(String)])),
    ];
    if (object.timestampParam != null) {
      result
        ..add('timestampParam')
        ..add(serializers.serialize(object.timestampParam,
            specifiedType: const FullType(String)));
    }
    if (object.secure != null) {
      result
        ..add('secure')
        ..add(serializers.serialize(object.secure,
            specifiedType: const FullType(bool)));
    }

    return result;
  }

  @override
  TransportOptions deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType: FullType.unspecified}) {
    final result = new TransportOptionsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'hostname':
          result.hostname = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'path':
          result.path = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'timestampParam':
          result.timestampParam = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'secure':
          result.secure = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'timestampRequests':
          result.timestampRequests = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'port':
          result.port = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'policyPort':
          result.policyPort = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'query':
          result.query.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(String),
                const FullType(String)
              ])) as BuiltMap);
          break;
      }
    }

    return result.build();
  }
}

class _$TransportOptions extends TransportOptions {
  @override
  final String hostname;
  @override
  final String path;
  @override
  final String timestampParam;
  @override
  final bool secure;
  @override
  final bool timestampRequests;
  @override
  final int port;
  @override
  final int policyPort;
  @override
  final BuiltMap<String, String> query;

  factory _$TransportOptions([void updates(TransportOptionsBuilder b)]) =>
      (new TransportOptionsBuilder()..update(updates)).build();

  _$TransportOptions._(
      {this.hostname,
      this.path,
      this.timestampParam,
      this.secure,
      this.timestampRequests,
      this.port,
      this.policyPort,
      this.query})
      : super._() {
    if (hostname == null)
      throw new BuiltValueNullFieldError('TransportOptions', 'hostname');
    if (path == null)
      throw new BuiltValueNullFieldError('TransportOptions', 'path');
    if (timestampRequests == null)
      throw new BuiltValueNullFieldError(
          'TransportOptions', 'timestampRequests');
    if (port == null)
      throw new BuiltValueNullFieldError('TransportOptions', 'port');
    if (policyPort == null)
      throw new BuiltValueNullFieldError('TransportOptions', 'policyPort');
    if (query == null)
      throw new BuiltValueNullFieldError('TransportOptions', 'query');
  }

  @override
  TransportOptions rebuild(void updates(TransportOptionsBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  TransportOptionsBuilder toBuilder() =>
      new TransportOptionsBuilder()..replace(this);

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! TransportOptions) return false;
    return hostname == other.hostname &&
        path == other.path &&
        timestampParam == other.timestampParam &&
        secure == other.secure &&
        timestampRequests == other.timestampRequests &&
        port == other.port &&
        policyPort == other.policyPort &&
        query == other.query;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc($jc($jc(0, hostname.hashCode), path.hashCode),
                            timestampParam.hashCode),
                        secure.hashCode),
                    timestampRequests.hashCode),
                port.hashCode),
            policyPort.hashCode),
        query.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('TransportOptions')
          ..add('hostname', hostname)
          ..add('path', path)
          ..add('timestampParam', timestampParam)
          ..add('secure', secure)
          ..add('timestampRequests', timestampRequests)
          ..add('port', port)
          ..add('policyPort', policyPort)
          ..add('query', query))
        .toString();
  }
}

class TransportOptionsBuilder
    implements Builder<TransportOptions, TransportOptionsBuilder> {
  _$TransportOptions _$v;

  String _hostname;
  String get hostname => _$this._hostname;
  set hostname(String hostname) => _$this._hostname = hostname;

  String _path;
  String get path => _$this._path;
  set path(String path) => _$this._path = path;

  String _timestampParam;
  String get timestampParam => _$this._timestampParam;
  set timestampParam(String timestampParam) =>
      _$this._timestampParam = timestampParam;

  bool _secure;
  bool get secure => _$this._secure;
  set secure(bool secure) => _$this._secure = secure;

  bool _timestampRequests;
  bool get timestampRequests => _$this._timestampRequests;
  set timestampRequests(bool timestampRequests) =>
      _$this._timestampRequests = timestampRequests;

  int _port;
  int get port => _$this._port;
  set port(int port) => _$this._port = port;

  int _policyPort;
  int get policyPort => _$this._policyPort;
  set policyPort(int policyPort) => _$this._policyPort = policyPort;

  MapBuilder<String, String> _query;
  MapBuilder<String, String> get query =>
      _$this._query ??= new MapBuilder<String, String>();
  set query(MapBuilder<String, String> query) => _$this._query = query;

  TransportOptionsBuilder();

  TransportOptionsBuilder get _$this {
    if (_$v != null) {
      _hostname = _$v.hostname;
      _path = _$v.path;
      _timestampParam = _$v.timestampParam;
      _secure = _$v.secure;
      _timestampRequests = _$v.timestampRequests;
      _port = _$v.port;
      _policyPort = _$v.policyPort;
      _query = _$v.query?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TransportOptions other) {
    if (other == null) throw new ArgumentError.notNull('other');
    _$v = other as _$TransportOptions;
  }

  @override
  void update(void updates(TransportOptionsBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$TransportOptions build() {
    _$TransportOptions _$result;
    try {
      _$result = _$v ??
          new _$TransportOptions._(
              hostname: hostname,
              path: path,
              timestampParam: timestampParam,
              secure: secure,
              timestampRequests: timestampRequests,
              port: port,
              policyPort: policyPort,
              query: query.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'query';
        query.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'TransportOptions', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}
