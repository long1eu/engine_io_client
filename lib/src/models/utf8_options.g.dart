// GENERATED CODE - DO NOT MODIFY BY HAND

part of utf8_options;

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

Serializer<UTF8Options> _$uTF8OptionsSerializer = new _$UTF8OptionsSerializer();

class _$UTF8OptionsSerializer implements StructuredSerializer<UTF8Options> {
  @override
  final Iterable<Type> types = const [UTF8Options, _$UTF8Options];
  @override
  final String wireName = 'UTF8Options';

  @override
  Iterable serialize(Serializers serializers, UTF8Options object,
      {FullType specifiedType: FullType.unspecified}) {
    final result = <Object>[
      'strict',
      serializers.serialize(object.strict, specifiedType: const FullType(bool)),
    ];

    return result;
  }

  @override
  UTF8Options deserialize(Serializers serializers, Iterable serialized,
      {FullType specifiedType: FullType.unspecified}) {
    final result = new UTF8OptionsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'strict':
          result.strict = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$UTF8Options extends UTF8Options {
  @override
  final bool strict;

  factory _$UTF8Options([void updates(UTF8OptionsBuilder b)]) =>
      (new UTF8OptionsBuilder()..update(updates)).build();

  _$UTF8Options._({this.strict}) : super._() {
    if (strict == null)
      throw new BuiltValueNullFieldError('UTF8Options', 'strict');
  }

  @override
  UTF8Options rebuild(void updates(UTF8OptionsBuilder b)) =>
      (toBuilder()..update(updates)).build();

  @override
  UTF8OptionsBuilder toBuilder() => new UTF8OptionsBuilder()..replace(this);

  @override
  bool operator ==(dynamic other) {
    if (identical(other, this)) return true;
    if (other is! UTF8Options) return false;
    return strict == other.strict;
  }

  @override
  int get hashCode {
    return $jf($jc(0, strict.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('UTF8Options')..add('strict', strict))
        .toString();
  }
}

class UTF8OptionsBuilder implements Builder<UTF8Options, UTF8OptionsBuilder> {
  _$UTF8Options _$v;

  bool _strict;
  bool get strict => _$this._strict;
  set strict(bool strict) => _$this._strict = strict;

  UTF8OptionsBuilder();

  UTF8OptionsBuilder get _$this {
    if (_$v != null) {
      _strict = _$v.strict;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UTF8Options other) {
    if (other == null) throw new ArgumentError.notNull('other');
    _$v = other as _$UTF8Options;
  }

  @override
  void update(void updates(UTF8OptionsBuilder b)) {
    if (updates != null) updates(this);
  }

  @override
  _$UTF8Options build() {
    final _$result = _$v ?? new _$UTF8Options._(strict: strict);
    replace(_$result);
    return _$result;
  }
}
