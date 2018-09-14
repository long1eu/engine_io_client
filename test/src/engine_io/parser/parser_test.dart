import 'package:engine_io_client/src/engine_io/parser/parser.dart';
import 'package:engine_io_client/src/models/packet.dart';
import 'package:test/test.dart';

const String ERROR_DATA = 'parser error';

void main() {
  final Packet ping = Packet(PacketType.ping);
  final Packet pong = Packet(PacketType.pong);

  test('encodeAsString', () {
    final Packet packet = Packet(PacketType.message, 'test');
    final String encode = Parser.encodePacket(packet);
    expect(encode.runtimeType, String);
  });

  test('decodeAsPacket', () {
    final Packet packet = Packet(PacketType.message, 'test');
    final String encoded = Parser.encodePacket(packet);
    final Packet decoded = Parser.decodePacket(encoded);

    expect(decoded.runtimeType, packet.runtimeType);
  });

  test('noData', () {
    final Packet message = Packet(PacketType.message);
    final String data = Parser.encodePacket(message);
    final Packet package = Parser.decodePacket(data);

    expect(package.type, PacketType.message);
    expect(package.data, isNull);
  });

  test('encodeOpenPacket', () {
    final Packet packet = Packet(PacketType.open, '{"some":"json"}');
    final String data = Parser.encodePacket(packet);
    final Packet package = Parser.decodePacket(data);

    expect(package.type, PacketType.open);
    expect(package.data, '{"some":"json"}');
  });

  test('encodeClosePacket', () {
    final Packet packet = Packet(PacketType.close);
    final String data = Parser.encodePacket(packet);
    final Packet package = Parser.decodePacket(data);

    expect(package.type, PacketType.close);
  });

  test('encodePingPacket', () {
    final Packet packet = Packet(PacketType.ping, '1');
    final String data = Parser.encodePacket(packet);
    final Packet package = Parser.decodePacket(data);

    expect(package.type, PacketType.ping);
    expect(package.data, '1');
  });

  test('encodePongPacket', () {
    final Packet packet = Packet(PacketType.pong, '1');
    final String data = Parser.encodePacket(packet);
    final Packet package = Parser.decodePacket(data);

    expect(package.type, PacketType.pong);
    expect(package.data, '1');
  });

  test('encodeMessagePacket', () {
    final Packet packet = Packet(PacketType.message, 'aaa');
    final String data = Parser.encodePacket(packet);
    final Packet package = Parser.decodePacket(data);

    expect(package.type, PacketType.message);
    expect(package.data, 'aaa');
  });

  test('encodeUTF8SpecialCharsMessagePacket', () {
    final Packet packet = Packet(PacketType.message, 'utf8 — string');
    final String data = Parser.encodePacket(packet);
    final Packet package = Parser.decodePacket(data);

    expect(package.type, PacketType.message);
    expect(package.data, 'utf8 — string');
  });

  test('encodeUpgradePacket', () {
    final Packet packet = Packet(PacketType.upgrade);
    final String data = Parser.encodePacket(packet);
    final Packet package = Parser.decodePacket(data);

    expect(package.type, PacketType.upgrade);
  });

  test('encodingFormat', () {
    Packet packet = Packet(PacketType.message, 'test');
    String data = Parser.encodePacket(packet);
    expect(RegExp('[0-9].*').hasMatch(data), isTrue);

    packet = Packet(PacketType.message);
    data = Parser.encodePacket(packet) as String;
    expect(RegExp('[0-9]').hasMatch(data), isTrue);
  });

  test('encodingStringMessageWithLoneSurrogatesReplacedByUFFFD', () {
    const String data = '\uDC00\uD834\uDF06\uDC00 \uD800\uD835\uDF07\uD800';
    final Packet packet = Packet(PacketType.message, data);
    final String list = Parser.encodePacket(packet, true);
    final Packet package = Parser.decodePacket(list, true);

    expect(package.type, PacketType.message);
    expect(package.data, '\uFFFD\uD834\uDF06\uFFFD \uFFFD\uD835\uDF07\uFFFD');
  });

  test('decodeEmptyPayload', () {
    final Packet package = Parser.decodePacket(null);

    expect(package.type, PacketType.error);
    expect(package.data, ERROR_DATA);
  });

  test('decodeBadFormat', () {
    final Packet package = Parser.decodePacket(':::');

    expect(package.type, PacketType.error);
    expect(package.data, ERROR_DATA);
  });

  test('decodeWrongTypes', () {
    final Packet package = Parser.decodePacket('94103');

    expect(package.type, PacketType.error);
    expect(package.data, ERROR_DATA);
  });

  test('encodePayloads', () {
    final List<Packet> packets = <Packet>[ping, pong];
    final String data = Parser.encodePayload(packets);

    expect(data.runtimeType, String);
  });

  test('encodeAndDecodePayloads', () {
    final Packet message = Packet(PacketType.message, 'a');

    String data = Parser.encodePayload(<Packet>[message]);
    List<Packet> packets = Parser.decodePayload(data);
    expect(packets.length, 1);

    data = Parser.encodePayload(<Packet>[message, ping]) as String;
    packets = Parser.decodePayload(data);
    expect(packets.first.type, PacketType.message);
    expect(packets.last.type, PacketType.ping);
  });

  test('encodeAndDecodeEmptyPayloads', () {
    final String data = Parser.encodePayload(<Packet>[]);
    print(data);

    final List<Packet> packets = Parser.decodePayload(data);
    expect(packets.length, 1);
    expect(packets.first.type, PacketType.open);
  });

  test('notUTF8EncodeWhenDealingWithStringsOnly', () {
    final List<Packet> packets = <Packet>[Packet(PacketType.message, '€€€'), Packet(PacketType.message, 'α')];

    final String encoded = Parser.encodePayload(packets);
    expect(encoded, '4:4€€€2:4α');
  });

  test('decodePayloadBadFormat', () {
    List<Packet> packets = Parser.decodePayload('!1');

    expect(packets.first.type, PacketType.error);
    expect(packets.first.data, equals(ERROR_DATA));
    expect(packets.length, 1);

    packets = Parser.decodePayload('');

    expect(packets.first.type, PacketType.error);
    expect(packets.first.data, equals(ERROR_DATA));
    expect(packets.length, 1);

    packets = Parser.decodePayload('))');

    expect(packets.first.type, PacketType.error);
    expect(packets.first.data, equals(ERROR_DATA));
    expect(packets.length, 1);
  });

  test('decodePayloadBadLength', () {
    final List<Packet> packets = Parser.decodePayload('1:');

    expect(packets.first.type, PacketType.error);
    expect(packets.first.data, equals(ERROR_DATA));
    expect(packets.length, 1);
  });

  test('decodePayloadBadPacketFormat', () {
    List<Packet> packets = Parser.decodePayload('3:99:');

    expect(packets.first.type, PacketType.error);
    expect(packets.first.data, equals(ERROR_DATA));
    expect(packets.length, 1);

    packets = Parser.decodePayload('1:aa');

    expect(packets.first.type, PacketType.error);
    expect(packets.first.data, equals(ERROR_DATA));
    expect(packets.length, 1);

    packets = Parser.decodePayload('1:a2:b');

    expect(packets.first.type, PacketType.error);
    expect(packets.first.data, equals(ERROR_DATA));
    expect(packets.length, 1);
  });

  test('encodeBinaryMessage', () {
    final List<int> data = List<int>.generate(5, (_) => 0);
    for (int i = 0; i < data.length; i++) {
      data[0] = i;
    }

    final Packet message = Packet(PacketType.message, data);
    final List<int> encoded = Parser.encodePacket(message);

    final Packet packet = Parser.decodeBytePacket(encoded);
    expect(packet.type, PacketType.message);
    expect(packet.data, equals(data));
  });

  test('encodeBinaryContents', () {
    final List<int> firstBuffer = List<int>.generate(5, (_) => 0);
    for (int i = 0; i < firstBuffer.length; i++) {
      firstBuffer[0] = i;
    }
    final List<int> secondBuffer = List<int>.generate(4, (_) => 0);
    for (int i = 0; i < secondBuffer.length; i++) {
      secondBuffer[0] = firstBuffer.length + i;
    }

    final List<Packet> list = <Packet>[Packet(PacketType.message, firstBuffer), Packet(PacketType.message, secondBuffer)];

    final List<int> encoded = Parser.encodePayload(list);

    final List<Packet> packets = Parser.decodeBinaryPayload(encoded);
    expect(packets.first.type, PacketType.message);
    expect(packets.first.data, firstBuffer);
    expect(packets.last.type, PacketType.message);
    expect(packets.last.data, secondBuffer);
  });

  test('encodeMixedBinaryAndStringContents', () {
    final List<int> firstBuffer = List<int>.generate(5, (_) => 0);
    for (int i = 0; i < firstBuffer.length; i++) {
      firstBuffer[0] = i;
    }

    final List<Packet> list = <Packet>[
      Packet(PacketType.message, firstBuffer),
      Packet(PacketType.message, 'hello'),
      Packet(PacketType.close),
    ];
    final dynamic data = Parser.encodePayload(list);

    final List<Packet> packets = Parser.decodeBinaryPayload(data as List<int>);

    expect(packets[0].type, PacketType.message);
    expect(packets[0].data, equals(firstBuffer));

    expect(packets[1].type, PacketType.message);
    expect(packets[1].data, 'hello');

    expect(packets[2].type, PacketType.close);
  });
}
