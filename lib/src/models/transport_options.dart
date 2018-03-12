library transport_options;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'transport_options.g.dart';

abstract class TransportOptions implements Built<TransportOptions, TransportOptionsBuilder> {
  factory TransportOptions([TransportOptionsBuilder updates(TransportOptionsBuilder b)]) = _$TransportOptions;

  TransportOptions._();

  String get hostname;

  String get path;

  String get timestampParam;

  bool get secure;

  bool get timestampRequests;

  int get port;

  int get policyPort;

  BuiltMap<String, String> get query;

  //Socket get socket;

  static Serializer<TransportOptions> get serializer => _$transportOptionsSerializer;
}
