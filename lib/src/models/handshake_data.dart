library handshake_data;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'handshake_data.g.dart';

abstract class HandshakeData implements Built<HandshakeData, HandshakeDataBuilder> {
  factory HandshakeData([HandshakeDataBuilder updates(HandshakeDataBuilder b)]) = _$HandshakeData;

  HandshakeData._();

  String get socketId;

  BuiltList<String> get upgrades;

  int get pingInterval;

  int get pingTimeout;

  static Serializer<HandshakeData> get serializer => _$handshakeDataSerializer;
}
