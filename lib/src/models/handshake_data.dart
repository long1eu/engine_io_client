library handshake_data;

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:socket_io/src/models/serializers.dart';

part 'handshake_data.g.dart';

abstract class HandshakeData implements Built<HandshakeData, HandshakeDataBuilder> {
  factory HandshakeData([HandshakeDataBuilder updates(HandshakeDataBuilder b)]) = _$HandshakeData;

  factory HandshakeData.fromJson(dynamic data) {
    Map<String, dynamic> map;
    if (data is String) {
      map = JSON.decode(data);
    } else
      map = data;

    return serializers.deserializeWith(HandshakeData.serializer, map);
  }

  HandshakeData._();

  @BuiltValueField(wireName: 'sid')
  String get socketId;

  BuiltList<String> get upgrades;

  int get pingInterval;

  int get pingTimeout;

  static Serializer<HandshakeData> get serializer => _$handshakeDataSerializer;
}
