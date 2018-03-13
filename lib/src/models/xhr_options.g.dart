// GENERATED CODE - DO NOT MODIFY BY HAND

part of xhr_options;

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

Serializer<XhrOptions> _$xhrOptionsSerializer = new _$XhrOptionsSerializer();

class _$XhrOptionsSerializer implements StructuredSerializer<XhrOptions> {
  @override
  final Iterable<Type> types = const [XhrOptions, _$XhrOptions];
  @override
  final String wireName = 'XhrOptions';

  @override
  Iterable serialize(Serializers serializers, XhrOptions object,
      {FullType specifiedType: FullType.unspecified}) {
    final result = <Object>[
      'uri',
      serializers.serialize(object.uri, specifiedType: const FullType(String)),
      'method',
      serializers.serialize(object.method,
          specifiedType: const FullType(String)),
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
  XhrOptions deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType: FullType.unspecified}) {
    final result = new XhrOptionsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'uri':
          result.uri = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'method':
          result.method = serializers.deserialize(value,
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

class _$XhrOptions extends XhrOptions {
  @override
  final String uri;
  @override
  final String method;
  @override
  final Client client;
  @override
  final Object data;

  factory _$XhrOptions([void updates(XhrOptionsBuilder b)]) =>
      (new XhrOptionsBuilder()..update(updates)).build();

  _$XhrOptions._({this.uri, this.method, this.client, this.data}) : super._() {
    if (uri == null) throw new BuiltValueNullFieldError('XhrOptions', 'uri');
    if (method == null)
      throw new BuiltValueNullFieldError('XhrOptions', 'method');
    if (client == null)
      throw new BuiltValueNullFieldError('XhrOptions', 'client');
  }

  @override
  XhrOptions rebuild(void updates(XhrOptionsBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  XhrOptionsBuilder toBuilder() => new XhrOptionsBuilder()..replace(this);

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! XhrOptions) return false;
    return uri == other.uri &&
        method == other.method &&
        client == other.client &&
        data == other.data;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, uri.hashCode), method.hashCode), client.hashCode),
        data.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('XhrOptions')
          ..add('uri', uri)
          ..add('method', method)
          ..add('client', client)
          ..add('data', data))
        .toString();
  }
}

class XhrOptionsBuilder implements Builder<XhrOptions, XhrOptionsBuilder> {
  _$XhrOptions _$v;

  String _uri;
  String get uri => _$this._uri;
  set uri(String uri) => _$this._uri = uri;

  String _method;
  String get method => _$this._method;
  set method(String method) => _$this._method = method;

  Client _client;
  Client get client => _$this._client;
  set client(Client client) => _$this._client = client;

  Object _data;
  Object get data => _$this._data;
  set data(Object data) => _$this._data = data;

  XhrOptionsBuilder();

  XhrOptionsBuilder get _$this {
    if (_$v != null) {
      _uri = _$v.uri;
      _method = _$v.method;
      _client = _$v.client;
      _data = _$v.data;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(XhrOptions other) {
    if (other == null) throw new ArgumentError.notNull('other');
    _$v = other as _$XhrOptions;
  }

  @override
  void update(void updates(XhrOptionsBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$XhrOptions build() {
    final _$result = _$v ??
        new _$XhrOptions._(
            uri: uri, method: method, client: client, data: data);
    replace(_$result);
    return _$result;
  }
}
