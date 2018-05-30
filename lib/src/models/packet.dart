import 'package:engine_io_client/src/logger.dart';

class Packet {
  const Packet(this.type, [this.data]);

  factory Packet.fromValues(int type, [dynamic data]) => new Packet(values[type], data);

  final String type;

  final dynamic data;

  static const Packet errorPacket = const Packet(error, 'parser error');

  static const Packet binaryError = const Packet(error, <int>[]);

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
  String toString() {
    return (new ToStringHelper('Packet')..add('type', '$type')..add('data', '$data')).toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Packet && runtimeType == other.runtimeType && type == other.type && data == other.data;

  @override
  int get hashCode => type.hashCode ^ data.hashCode;
}
