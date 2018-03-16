library transport_options;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:engine_io_client/src/engine_io/client/socket.dart';

part 'transport_options.g.dart';

abstract class TransportOptions implements Built<TransportOptions, TransportOptionsBuilder> {
  factory TransportOptions([TransportOptionsBuilder updates(TransportOptionsBuilder b)]) {
    return new _$TransportOptions((TransportOptionsBuilder b) {
      return b
        ..port = -1
        ..policyPort = -1
        ..secure = false
        ..timestampRequests = false
        ..update(updates);
    });
  }

  TransportOptions._();

  String get hostname;

  String get path;

  @nullable
  String get timestampParam;

  @nullable
  bool get secure;

  bool get timestampRequests;

  int get port;

  int get policyPort;

  BuiltMap<String, String> get query;

  @BuiltValueField(serialize: false)
  @nullable
  Socket get socket;

  static Serializer<TransportOptions> get serializer => _$transportOptionsSerializer;
}
