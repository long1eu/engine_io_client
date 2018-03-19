// GENERATED CODE - DO NOT MODIFY BY HAND

part of socket_options;

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

Serializer<SocketOptions> _$socketOptionsSerializer =
    new _$SocketOptionsSerializer();

class _$SocketOptionsSerializer implements StructuredSerializer<SocketOptions> {
  @override
  final Iterable<Type> types = const [SocketOptions, _$SocketOptions];
  @override
  final String wireName = 'SocketOptions';

  @override
  Iterable serialize(Serializers serializers, SocketOptions object,
      {FullType specifiedType: FullType.unspecified}) {
    final result = <Object>[
      'transports',
      serializers.serialize(object.transports,
          specifiedType:
              const FullType(BuiltList, const [const FullType(String)])),
      'upgrade',
      serializers.serialize(object.upgrade,
          specifiedType: const FullType(bool)),
      'rememberUpgrade',
      serializers.serialize(object.rememberUpgrade,
          specifiedType: const FullType(bool)),
      'transportOptions',
      serializers.serialize(object.transportOptions,
          specifiedType: const FullType(BuiltMap, const [
            const FullType(String),
            const FullType(TransportOptions)
          ])),
      'hostname',
      serializers.serialize(object.hostname,
          specifiedType: const FullType(String)),
      'path',
      serializers.serialize(object.path, specifiedType: const FullType(String)),
      'timestampParam',
      serializers.serialize(object.timestampParam,
          specifiedType: const FullType(String)),
      'secure',
      serializers.serialize(object.secure, specifiedType: const FullType(bool)),
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
    if (object.host != null) {
      result
        ..add('host')
        ..add(serializers.serialize(object.host,
            specifiedType: const FullType(String)));
    }
    if (object.rawQuery != null) {
      result
        ..add('rawQuery')
        ..add(serializers.serialize(object.rawQuery,
            specifiedType: const FullType(String)));
    }
    if (object.securityContext != null) {
      result
        ..add('securityContext')
        ..add(serializers.serialize(object.securityContext,
            specifiedType: const FullType(SecurityContext)));
    }

    return result;
  }

  @override
  SocketOptions deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType: FullType.unspecified}) {
    final result = new SocketOptionsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'transports':
          result.transports.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(String)]))
              as BuiltList);
          break;
        case 'upgrade':
          result.upgrade = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'rememberUpgrade':
          result.rememberUpgrade = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'host':
          result.host = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'rawQuery':
          result.rawQuery = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'transportOptions':
          result.transportOptions.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(String),
                const FullType(TransportOptions)
              ])) as BuiltMap);
          break;
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
        case 'securityContext':
          result.securityContext = serializers.deserialize(value,
                  specifiedType: const FullType(SecurityContext))
              as SecurityContext;
          break;
      }
    }

    return result.build();
  }
}

class _$SocketOptions extends SocketOptions {
  @override
  final BuiltList<String> transports;
  @override
  final bool upgrade;
  @override
  final bool rememberUpgrade;
  @override
  final String host;
  @override
  final String rawQuery;
  @override
  final BuiltMap<String, TransportOptions> transportOptions;
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
  @override
  final SecurityContext securityContext;

  factory _$SocketOptions([void updates(SocketOptionsBuilder b)]) =>
      (new SocketOptionsBuilder()..update(updates)).build();

  _$SocketOptions._(
      {this.transports,
      this.upgrade,
      this.rememberUpgrade,
      this.host,
      this.rawQuery,
      this.transportOptions,
      this.hostname,
      this.path,
      this.timestampParam,
      this.secure,
      this.timestampRequests,
      this.port,
      this.policyPort,
      this.query,
      this.securityContext})
      : super._() {
    if (transports == null)
      throw new BuiltValueNullFieldError('SocketOptions', 'transports');
    if (upgrade == null)
      throw new BuiltValueNullFieldError('SocketOptions', 'upgrade');
    if (rememberUpgrade == null)
      throw new BuiltValueNullFieldError('SocketOptions', 'rememberUpgrade');
    if (transportOptions == null)
      throw new BuiltValueNullFieldError('SocketOptions', 'transportOptions');
    if (hostname == null)
      throw new BuiltValueNullFieldError('SocketOptions', 'hostname');
    if (path == null)
      throw new BuiltValueNullFieldError('SocketOptions', 'path');
    if (timestampParam == null)
      throw new BuiltValueNullFieldError('SocketOptions', 'timestampParam');
    if (secure == null)
      throw new BuiltValueNullFieldError('SocketOptions', 'secure');
    if (timestampRequests == null)
      throw new BuiltValueNullFieldError('SocketOptions', 'timestampRequests');
    if (port == null)
      throw new BuiltValueNullFieldError('SocketOptions', 'port');
    if (policyPort == null)
      throw new BuiltValueNullFieldError('SocketOptions', 'policyPort');
    if (query == null)
      throw new BuiltValueNullFieldError('SocketOptions', 'query');
  }

  @override
  SocketOptions rebuild(void updates(SocketOptionsBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  SocketOptionsBuilder toBuilder() => new SocketOptionsBuilder()..replace(this);

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! SocketOptions) return false;
    return transports == other.transports &&
        upgrade == other.upgrade &&
        rememberUpgrade == other.rememberUpgrade &&
        host == other.host &&
        rawQuery == other.rawQuery &&
        transportOptions == other.transportOptions &&
        hostname == other.hostname &&
        path == other.path &&
        timestampParam == other.timestampParam &&
        secure == other.secure &&
        timestampRequests == other.timestampRequests &&
        port == other.port &&
        policyPort == other.policyPort &&
        query == other.query &&
        securityContext == other.securityContext;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc(
                                $jc(
                                    $jc(
                                        $jc(
                                            $jc(
                                                $jc(
                                                    $jc(
                                                        $jc(
                                                            $jc(
                                                                0,
                                                                transports
                                                                    .hashCode),
                                                            upgrade.hashCode),
                                                        rememberUpgrade
                                                            .hashCode),
                                                    host.hashCode),
                                                rawQuery.hashCode),
                                            transportOptions.hashCode),
                                        hostname.hashCode),
                                    path.hashCode),
                                timestampParam.hashCode),
                            secure.hashCode),
                        timestampRequests.hashCode),
                    port.hashCode),
                policyPort.hashCode),
            query.hashCode),
        securityContext.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('SocketOptions')
          ..add('transports', transports)
          ..add('upgrade', upgrade)
          ..add('rememberUpgrade', rememberUpgrade)
          ..add('host', host)
          ..add('rawQuery', rawQuery)
          ..add('transportOptions', transportOptions)
          ..add('hostname', hostname)
          ..add('path', path)
          ..add('timestampParam', timestampParam)
          ..add('secure', secure)
          ..add('timestampRequests', timestampRequests)
          ..add('port', port)
          ..add('policyPort', policyPort)
          ..add('query', query)
          ..add('securityContext', securityContext))
        .toString();
  }
}

class SocketOptionsBuilder
    implements Builder<SocketOptions, SocketOptionsBuilder> {
  _$SocketOptions _$v;

  ListBuilder<String> _transports;
  ListBuilder<String> get transports =>
      _$this._transports ??= new ListBuilder<String>();
  set transports(ListBuilder<String> transports) =>
      _$this._transports = transports;

  bool _upgrade;
  bool get upgrade => _$this._upgrade;
  set upgrade(bool upgrade) => _$this._upgrade = upgrade;

  bool _rememberUpgrade;
  bool get rememberUpgrade => _$this._rememberUpgrade;
  set rememberUpgrade(bool rememberUpgrade) =>
      _$this._rememberUpgrade = rememberUpgrade;

  String _host;
  String get host => _$this._host;
  set host(String host) => _$this._host = host;

  String _rawQuery;
  String get rawQuery => _$this._rawQuery;
  set rawQuery(String rawQuery) => _$this._rawQuery = rawQuery;

  MapBuilder<String, TransportOptions> _transportOptions;
  MapBuilder<String, TransportOptions> get transportOptions =>
      _$this._transportOptions ??= new MapBuilder<String, TransportOptions>();
  set transportOptions(MapBuilder<String, TransportOptions> transportOptions) =>
      _$this._transportOptions = transportOptions;

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

  SecurityContext _securityContext;
  SecurityContext get securityContext => _$this._securityContext;
  set securityContext(SecurityContext securityContext) =>
      _$this._securityContext = securityContext;

  SocketOptionsBuilder();

  SocketOptionsBuilder get _$this {
    if (_$v != null) {
      _transports = _$v.transports?.toBuilder();
      _upgrade = _$v.upgrade;
      _rememberUpgrade = _$v.rememberUpgrade;
      _host = _$v.host;
      _rawQuery = _$v.rawQuery;
      _transportOptions = _$v.transportOptions?.toBuilder();
      _hostname = _$v.hostname;
      _path = _$v.path;
      _timestampParam = _$v.timestampParam;
      _secure = _$v.secure;
      _timestampRequests = _$v.timestampRequests;
      _port = _$v.port;
      _policyPort = _$v.policyPort;
      _query = _$v.query?.toBuilder();
      _securityContext = _$v.securityContext;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SocketOptions other) {
    if (other == null) throw new ArgumentError.notNull('other');
    _$v = other as _$SocketOptions;
  }

  @override
  void update(void updates(SocketOptionsBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$SocketOptions build() {
    _$SocketOptions _$result;
    try {
      _$result = _$v ??
          new _$SocketOptions._(
              transports: transports.build(),
              upgrade: upgrade,
              rememberUpgrade: rememberUpgrade,
              host: host,
              rawQuery: rawQuery,
              transportOptions: transportOptions.build(),
              hostname: hostname,
              path: path,
              timestampParam: timestampParam,
              secure: secure,
              timestampRequests: timestampRequests,
              port: port,
              policyPort: policyPort,
              query: query.build(),
              securityContext: securityContext);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'transports';
        transports.build();

        _$failedField = 'transportOptions';
        transportOptions.build();

        _$failedField = 'query';
        query.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'SocketOptions', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}
