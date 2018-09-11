class Packet<T> {
  final String type;
  final T data;

  Packet(this.type, [this.data]);

  static Packet<String> error = Packet<String>(PacketType.error, 'parser error');

  static Packet<List<int>> binaryError = Packet<List<int>>(PacketType.error, <int>[]);

  @override
  String toString() => 'Packet{type: $type, data: $data}';
}

class PacketType {
  const PacketType._();

  static const String open = 'open';
  static const String close = 'close';
  static const String ping = 'ping';
  static const String pong = 'pong';
  static const String message = 'message';
  static const String upgrade = 'upgrade';
  static const String noop = 'noop';
  static const String error = 'error';

  static const List<String> values = const <String>[open, close, ping, pong, message, upgrade, noop, error];

  static int index(String value) => values.indexOf(value);
}
