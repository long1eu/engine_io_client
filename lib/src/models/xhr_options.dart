library xhr_options;

import 'dart:io';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'xhr_options.g.dart';

abstract class XhrOptions implements Built<XhrOptions, XhrOptionsBuilder> {
  factory XhrOptions([XhrOptionsBuilder updates(XhrOptionsBuilder b)]) = _$XhrOptions;

  factory XhrOptions.get(String uri, dynamic data, HttpClient client, [String method = 'GET']) {
    return new XhrOptions((XhrOptionsBuilder b) {
      b
        ..uri = uri
        ..data = data
        ..method = method
        ..client = client;
    });
  }

  XhrOptions._();

  String get uri;

  String get method;

  @BuiltValueField(serialize: false)
  HttpClient get client;

  @nullable
  Object get data;

  static Serializer<XhrOptions> get serializer => _$xhrOptionsSerializer;
}
