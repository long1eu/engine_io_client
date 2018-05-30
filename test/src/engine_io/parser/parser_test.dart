import 'package:engine_io_client/src/engine_io/parser/parser.dart';
import 'package:engine_io_client/src/models/packet.dart';
import 'package:test/test.dart';

// ignore_for_file: always_specify_types
const String ERROR_DATA = 'parser error';

void main() {
  const Packet ping = const Packet(Packet.ping);
  const Packet pong = const Packet(Packet.pong);

  test('encodeAsString', () {
    const Packet packet = const Packet(Packet.message, 'test');
    final dynamic encode = Parser.encodePacket(packet);
    expect(encode.runtimeType, String);
  });

  test('decodeAsPacket', () {
    const Packet packet = const Packet(Packet.message, 'test');
    final String encoded = Parser.encodePacket(packet);
    final Packet decoded = Parser.decodePacket(encoded);

    expect(decoded.runtimeType, packet.runtimeType);
  });

  test('noData', () {
    const Packet message = const Packet(Packet.message);
    final String data = Parser.encodePacket(message);
    final Packet package = Parser.decodePacket(data);

    expect(package.type, Packet.message);
    expect(package.data, isNull);
  });

  test('encodeOpenPacket', () {
    const Packet packet = const Packet(Packet.open, '{"some":"json"}');
    final String data = Parser.encodePacket(packet);
    final Packet package = Parser.decodePacket(data);

    expect(package.type, Packet.open);
    expect(package.data, '{"some":"json"}');
  });

  test('encodeClosePacket', () {
    const Packet packet = const Packet(Packet.close);
    final String data = Parser.encodePacket(packet);
    final Packet package = Parser.decodePacket(data);

    expect(package.type, Packet.close);
  });

  test('encodePingPacket', () {
    const Packet packet = const Packet(Packet.ping, '1');
    final String data = Parser.encodePacket(packet);
    final Packet package = Parser.decodePacket(data);

    expect(package.type, Packet.ping);
    expect(package.data, '1');
  });

  test('encodePongPacket', () {
    const Packet packet = const Packet(Packet.pong, '1');
    final String data = Parser.encodePacket(packet);
    final Packet package = Parser.decodePacket(data);

    expect(package.type, Packet.pong);
    expect(package.data, '1');
  });

  test('encodeMessagePacket', () {
    const Packet packet = const Packet(Packet.message, 'aaa');
    final String data = Parser.encodePacket(packet);
    final Packet package = Parser.decodePacket(data);

    expect(package.type, Packet.message);
    expect(package.data, 'aaa');
  });

  test('encodeUTF8SpecialCharsMessagePacket', () {
    const Packet packet = const Packet(Packet.message, 'utf8 — string');
    final String data = Parser.encodePacket(packet);
    final Packet package = Parser.decodePacket(data);

    expect(package.type, Packet.message);
    expect(package.data, 'utf8 — string');
  });

  test('encodeUpgradePacket', () {
    const Packet packet = const Packet(Packet.upgrade);
    final String data = Parser.encodePacket(packet);
    final Packet package = Parser.decodePacket(data);

    expect(package.type, Packet.upgrade);
  });

  test('encodingFormat', () {
    Packet packet = const Packet(Packet.message, 'test');
    String data = Parser.encodePacket(packet);
    expect(new RegExp('[0-9].*').hasMatch(data), isTrue);

    packet = const Packet(Packet.message);
    data = Parser.encodePacket(packet);
    expect(new RegExp('[0-9]').hasMatch(data), isTrue);
  });

  test('encodingStringMessageWithLoneSurrogatesReplacedByUFFFD', () {
    const String data = '\uDC00\uD834\uDF06\uDC00 \uD800\uD835\uDF07\uD800';
    const Packet packet = const Packet(Packet.message, data);
    final String list = Parser.encodePacket(packet, true);
    final Packet package = Parser.decodePacket(list, true);

    expect(package.type, Packet.message);
    expect(package.data, '\uFFFD\uD834\uDF06\uFFFD \uFFFD\uD835\uDF07\uFFFD');
  });

  test('decodeEmptyPayload', () {
    final Packet package = Parser.decodePacket(null);

    expect(package.type, Packet.error);
    expect(package.data, ERROR_DATA);
  });

  test('decodeBadFormat', () {
    final Packet package = Parser.decodePacket(':::');

    expect(package.type, Packet.error);
    expect(package.data, ERROR_DATA);
  });

  test('decodeWrongTypes', () {
    final Packet package = Parser.decodePacket('94103');

    expect(package.type, Packet.error);
    expect(package.data, ERROR_DATA);
  });

  test('encodePayloads', () {
    final List<Packet> packets = <Packet>[ping, pong];
    final String data = Parser.encodePayload(packets);

    expect(data.runtimeType, String);
  });

  test('encodeAndDecodePayloads', () {
    const Packet message = const Packet(Packet.message, 'a');

    String data = Parser.encodePayload(<Packet>[message]);
    List<Packet> packets = Parser.decodePayload(data);
    expect(packets.length, 1);

    data = Parser.encodePayload(<Packet>[message, ping]);
    packets = Parser.decodePayload(data);
    expect(packets.first.type, Packet.message);
    expect(packets.last.type, Packet.ping);
  });

  test('encodeAndDecodeEmptyPayloads', () {
    final String data = Parser.encodePayload(<Packet>[]);
    print(data);

    final List<Packet> packets = Parser.decodePayload(data);
    expect(packets.length, 1);
    expect(packets.first.type, Packet.open);
  });

  test('notUTF8EncodeWhenDealingWithStringsOnly', () {
    const List<Packet> packets = const <Packet>[const Packet(Packet.message, '€€€'), const Packet(Packet.message, 'α')];

    final String encoded = Parser.encodePayload(packets);
    expect(encoded, '4:4€€€2:4α');
  });

  test('decodePayloadBadFormat', () {
    List<Packet> packets = Parser.decodePayload('!1');

    expect(packets.first.type, Packet.error);
    expect(packets.first.data, equals(ERROR_DATA));
    expect(packets.length, 1);

    packets = Parser.decodePayload('');

    expect(packets.first.type, Packet.error);
    expect(packets.first.data, equals(ERROR_DATA));
    expect(packets.length, 1);

    packets = Parser.decodePayload('))');

    expect(packets.first.type, Packet.error);
    expect(packets.first.data, equals(ERROR_DATA));
    expect(packets.length, 1);
  });

  test('decodePayloadBadLength', () {
    final List<Packet> packets = Parser.decodePayload('1:');

    expect(packets.first.type, Packet.error);
    expect(packets.first.data, equals(ERROR_DATA));
    expect(packets.length, 1);
  });

  test('decodePayloadBadPacketFormat', () {
    List<Packet> packets = Parser.decodePayload('3:99:');

    expect(packets.first.type, Packet.error);
    expect(packets.first.data, equals(ERROR_DATA));
    expect(packets.length, 1);

    packets = Parser.decodePayload('1:aa');

    expect(packets.first.type, Packet.error);
    expect(packets.first.data, equals(ERROR_DATA));
    expect(packets.length, 1);

    packets = Parser.decodePayload('1:a2:b');

    expect(packets.first.type, Packet.error);
    expect(packets.first.data, equals(ERROR_DATA));
    expect(packets.length, 1);
  });

  test('encodeBinaryMessage', () {
    final List<int> data = new List<int>.generate(5, (_) => 0);
    for (int i = 0; i < data.length; i++) {
      data[0] = i;
    }

    final Packet message = new Packet(Packet.message, data);
    final List<int> encoded = Parser.encodePacket(message);

    final Packet packet = Parser.decodeBytePacket(encoded);
    expect(packet.type, Packet.message);
    expect(packet.data, equals(data));
  });

  test('encodeBinaryContents', () {
    final List<int> firstBuffer = new List<int>.generate(5, (_) => 0);
    for (int i = 0; i < firstBuffer.length; i++) {
      firstBuffer[0] = i;
    }
    final List<int> secondBuffer = new List<int>.generate(4, (_) => 0);
    for (int i = 0; i < secondBuffer.length; i++) {
      secondBuffer[0] = firstBuffer.length + i;
    }

    final List<Packet> list = <Packet>[new Packet(Packet.message, firstBuffer), new Packet(Packet.message, secondBuffer)];

    final List<int> encoded = Parser.encodePayload(list);

    final List<Packet> packets = Parser.decodeBinaryPayload(encoded);
    expect(packets.first.type, Packet.message);
    expect(packets.first.data, firstBuffer);
    expect(packets.last.type, Packet.message);
    expect(packets.last.data, secondBuffer);
  });

  test('encodeMixedBinaryAndStringContents', () {
    final List<int> firstBuffer = new List<int>.generate(5, (_) => 0);
    for (int i = 0; i < firstBuffer.length; i++) {
      firstBuffer[0] = i;
    }

    final List<Packet> list = <Packet>[
      new Packet(Packet.message, firstBuffer),
      const Packet(Packet.message, 'hello'),
      const Packet(Packet.close),
    ];
    final dynamic data = Parser.encodePayload(list);

    final List<Packet> packets = Parser.decodeBinaryPayload(data);

    expect(packets[0].type, Packet.message);
    expect(packets[0].data, equals(firstBuffer));

    expect(packets[1].type, Packet.message);
    expect(packets[1].data, 'hello');

    expect(packets[2].type, Packet.close);
  });
}
