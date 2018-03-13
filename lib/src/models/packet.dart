library packet;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:socket_io/src/models/packet_type.dart';

part 'packet.g.dart';

abstract class Packet implements Built<Packet, PacketBuilder> {
  factory Packet([PacketBuilder updates(PacketBuilder b)]) = _$Packet;

  factory Packet.fromValues(int type, [dynamic data]) {
    return new Packet((PacketBuilder b) {
      b
        ..type = PacketType.values.elementAt(type)
        ..data = data;
    });
  }

  factory Packet.values(PacketType type, [dynamic data]) {
    return new Packet((PacketBuilder b) {
      b
        ..type = type
        ..data = data;
    });
  }

  Packet._();

  PacketType get type;

  @nullable
  Object get data;

  static Packet error = new Packet((PacketBuilder b) {
    b
      ..type = PacketType.error
      ..data = 'parser error';
  });

  static Packet binaryError = new Packet((PacketBuilder b) {
    b
      ..type = PacketType.error
      ..data = <int>[];
  });

  // ignore: always_specify_types
  static Serializer<Packet> get serializer => _$packetSerializer;
}
