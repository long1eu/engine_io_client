library packet_type;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'packet_type.g.dart';

class PacketType extends EnumClass {
  const PacketType._(String name) : super(name);

  static const PacketType open = _$open;
  static const PacketType close = _$close;
  static const PacketType ping = _$ping;
  static const PacketType pong = _$pong;
  static const PacketType message = _$message;
  static const PacketType upgrade = _$upgrade;
  static const PacketType noop = _$noop;
  static const PacketType error = _$error;

  static BuiltSet<PacketType> get values => _$PacketTypeValues;

  int get index {
    switch (this) {
      case open:
        return 0;
      case close:
        return 1;
      case ping:
        return 2;
      case pong:
        return 3;
      case message:
        return 4;
      case upgrade:
        return 5;
      case noop:
        return 6;
      default:
        return 7;
    }
  }

  static PacketType valueOf(String name) => _$PacketTypeValueOf(name);

  static Serializer<PacketType> get serializer => _$packetTypeSerializer;
}
