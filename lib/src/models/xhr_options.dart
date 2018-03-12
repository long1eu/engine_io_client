library xhr_options;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:http/http.dart';

part 'xhr_options.g.dart';

abstract class XhrOptions<T> implements Built<XhrOptions<T>, XhrOptionsBuilder<T>> {
  factory XhrOptions([XhrOptionsBuilder<T> updates(XhrOptionsBuilder<T> b)]) = _$XhrOptions<T>;

  factory XhrOptions.get(String uri, T data, Client client, [String method = 'GET']) {
    return new XhrOptions<T>((XhrOptionsBuilder<T> b) {
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
  Client get client;

  @nullable
  T get data;

  static Serializer<XhrOptions> get serializer => _$xhrOptionsSerializer;
}
