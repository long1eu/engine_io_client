import 'dart:convert';

class Packet<T> {
  final PacketType type;
  final T data;

  Packet(this.type, [this.data]);

  static Packet<String> error = Packet<String>(PacketType.error, 'parser error');

  static Packet<List<int>> binaryError = Packet<List<int>>(PacketType.error, <int>[]);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'data': data,
    };
  }

  @override
  String toString() => jsonEncode(toJson(), toEncodable: (Object it) => it.toString());
}

class PacketType {
  final int i;

  const PacketType._(this.i);

  static const PacketType open = const PacketType._(0);
  static const PacketType close = const PacketType._(1);
  static const PacketType ping = const PacketType._(2);
  static const PacketType pong = const PacketType._(3);
  static const PacketType message = const PacketType._(4);
  static const PacketType upgrade = const PacketType._(5);
  static const PacketType noop = const PacketType._(6);
  static const PacketType error = const PacketType._(7);

  static const List<String> _strings = const <String>['open', 'close', 'ping', 'pong', 'message', 'upgrade', 'noop', 'error'];

  static const List<PacketType> values = const <PacketType>[open, close, ping, pong, message, upgrade, noop, error];

  static int index(String value) => _strings.indexOf(value);

  @override
  String toString() => _strings[i];
}
