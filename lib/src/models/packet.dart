library packet;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:socket_io/src/models/packet_type.dart';

part 'packet.g.dart';

abstract class Packet<T> implements Built<Packet<T>, PacketBuilder<T>> {
  factory Packet([PacketBuilder<T> updates(PacketBuilder<T> b)]) = _$Packet<T>;

  factory Packet.fromValues(int type, [T data]) {
    return new Packet<T>((PacketBuilder<T> b) {
      b
        ..type = PacketType.values.elementAt(type)
        ..data = data;
    });
  }

  factory Packet.values(PacketType type, [T data]) {
    return new Packet<T>((PacketBuilder<T> b) {
      b
        ..type = type
        ..data = data;
    });
  }

  Packet._();

  PacketType get type;

  @nullable
  T get data;

  static Packet<String> error = new Packet<String>((PacketBuilder<String> b) {
    b
      ..type = PacketType.error
      ..data = 'parser error';
  });

  static Packet<List<int>> binaryError = new Packet<List<int>>((PacketBuilder<List<int>> b) {
    b
      ..type = PacketType.error
      ..data = <int>[];
  });

  // ignore: always_specify_types
  static Serializer<Packet> get serializer => _$packetSerializer;
}
