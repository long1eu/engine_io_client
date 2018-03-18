library packet;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:engine_io_client/src/models/packet_type.dart';

part 'packet.g.dart';

abstract class Packet implements Built<Packet, PacketBuilder> {
  factory Packet([PacketBuilder updates(PacketBuilder b)]) = _$Packet;

  factory Packet.fromValues(int type, [dynamic data]) => new Packet.values(PacketType.values[type], data);

  factory Packet.values(String type, [dynamic data]) {
    return new Packet((PacketBuilder b) {
      b
        ..type = type
        ..data = data;
    });
  }

  Packet._();

  String get type;

  @nullable
  Object get data;

  static Packet error = new Packet.values(PacketType.error, 'parser error');

  static Packet binaryError = new Packet.values(PacketType.error, <int>[]);

  static Serializer<Packet> get serializer => _$packetSerializer;
}
