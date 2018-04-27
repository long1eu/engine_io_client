class Packet<T> {
  Packet(this.type, [this.data]);

  factory Packet.fromValues(int type, [T data]) => new Packet<T>(values[type], data);

  final String type;

  final T data;

  static Packet<String> errorPacket = new Packet<String>(error, 'parser error');

  static Packet<List<int>> binaryError = new Packet<List<int>>(error, <int>[]);

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

  @override
  String toString() => 'Packet{type: $type, data: $data}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Packet && runtimeType == other.runtimeType && type == other.type && data == other.data;

  @override
  int get hashCode => type.hashCode ^ data.hashCode;
}
