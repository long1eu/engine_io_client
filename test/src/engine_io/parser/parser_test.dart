import 'package:socket_io/src/engine_io/parser/parser.dart';
import 'package:socket_io/src/models/packet.dart';
import 'package:socket_io/src/models/packet_type.dart';
import 'package:test/test.dart';

// ignore_for_file: always_specify_types
const String ERROR_DATA = 'parser error';

void main() {
  test('encodeAsString', () {
    final Packet packet = new Packet.values(PacketType.message, 'test');
    Parser.encodePacket(packet, new EncodeCallback((dynamic data) {
      expect(data.runtimeType, String);
    }));
  });

  test('decodeAsPacket', () {
    final Packet packet = new Packet.values(PacketType.message, 'test');
    Parser.encodePacket(packet, new EncodeCallback((dynamic data) {
      expect(Parser.decodePacket(data).runtimeType, packet.runtimeType);
    }));
  });

  test('noData', () {
    Parser.encodePacket(new Packet.values(PacketType.message), new EncodeCallback((dynamic data) {
      final Packet package = Parser.decodePacket(data);
      expect(package.type, PacketType.message);
      expect(package.data, isNull);
    }));
  });

  test('encodeOpenPacket', () {
    Parser.encodePacket(new Packet.values(PacketType.open, '{"some":"json"}'), new EncodeCallback((dynamic data) {
      final Packet package = Parser.decodePacket(data);
      expect(package.type, PacketType.open);
      expect(package.data, '{"some":"json"}');
    }));
  });

  test('encodeClosePacket', () {
    Parser.encodePacket(new Packet.values(PacketType.close), new EncodeCallback((dynamic data) {
      final Packet package = Parser.decodePacket(data);
      expect(package.type, PacketType.close);
    }));
  });

  test('encodePingPacket', () {
    Parser.encodePacket(new Packet.values(PacketType.ping, '1'), new EncodeCallback((dynamic data) {
      final Packet package = Parser.decodePacket(data);
      expect(package.type, PacketType.ping);
      expect(package.data, '1');
    }));
  });

  test('encodePongPacket', () {
    Parser.encodePacket(new Packet.values(PacketType.pong, '1'), new EncodeCallback((dynamic data) {
      final Packet package = Parser.decodePacket(data);
      expect(package.type, PacketType.pong);
      expect(package.data, '1');
    }));
  });

  test('encodeMessagePacket', () {
    Parser.encodePacket(new Packet.values(PacketType.message, 'aaa'), new EncodeCallback((dynamic data) {
      final Packet package = Parser.decodePacket(data);
      expect(package.type, PacketType.message);
      expect(package.data, 'aaa');
    }));
  });

  test('encodeUTF8SpecialCharsMessagePacket', () {
    Parser.encodePacket(new Packet.values(PacketType.message, 'utf8 — string'), new EncodeCallback((dynamic data) {
      final Packet package = Parser.decodePacket(data);
      expect(package.type, PacketType.message);
      expect(package.data, 'utf8 — string');
    }));
  });

  test('encodeUpgradePacket', () {
    Parser.encodePacket(new Packet.values(PacketType.upgrade), new EncodeCallback((dynamic data) {
      final Packet package = Parser.decodePacket(data);
      expect(package.type, PacketType.upgrade);
    }));
  });

  test('encodingFormat', () {
    Parser.encodePacket(new Packet.values(PacketType.message, 'test'), new EncodeCallback((dynamic data) {
      expect(new RegExp('[0-9].*').hasMatch(data), isTrue);
    }));

    Parser.encodePacket(new Packet.values(PacketType.message), new EncodeCallback((dynamic data) {
      expect(new RegExp('[0-9]').hasMatch(data), isTrue);
    }));
  });

  test('encodingStringMessageWithLoneSurrogatesReplacedByUFFFD', () {
    final String data = '\uDC00\uD834\uDF06\uDC00 \uD800\uD835\uDF07\uD800';
    Parser.encodePacket(new Packet.values(PacketType.message, data), new EncodeCallback((dynamic data) {
      final Packet package = Parser.decodePacket(data, true);

      expect(package.type, PacketType.message);
      expect(package.data, '\uFFFD\uD834\uDF06\uFFFD \uFFFD\uD835\uDF07\uFFFD');
    }), true);
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
    Parser.encodePayload(<Packet>[new Packet.values(PacketType.ping), new Packet.values(PacketType.pong)],
        new EncodeCallback((dynamic data) {
      expect(data.runtimeType, String);
    }));
  });

  test('encodeAndDecodePayloads', () {
    Parser.encodePayload(<Packet>[new Packet.values(PacketType.message, 'a')],
        new EncodeCallback((dynamic data) {
      Parser.decodePayload(data, new DecodePayloadCallback((Packet packet, int index, int total) {
        final bool isLast = index + 1 == total;
        expect(isLast, isTrue);
        return true;
      }));
    }));

    Parser.encodePayload(<Packet>[
      new Packet.values(PacketType.message, 'a'),
      new Packet.values(PacketType.ping),
    ], new EncodeCallback((dynamic data) {
      Parser.decodePayload(data, new DecodePayloadCallback((Packet packet, int index, int total) {
        final bool isLast = index + 1 == total;
        if (!isLast) {
          expect(packet.type, PacketType.message);
        } else {
          expect(packet.type, PacketType.ping);
        }
        return true;
      }));
    }));
  });

  test('encodeAndDecodeEmptyPayloads', () {
    Parser.encodePayload(<Packet>[], new EncodeCallback((dynamic data) {
      Parser.decodePayload(data, new DecodePayloadCallback((Packet packet, int index, int total) {
        expect(packet.type, PacketType.open);
        final bool isLast = index + 1 == total;
        expect(isLast, isTrue);

        return true;
      }));
    }));
  });

  test('notUTF8EncodeWhenDealingWithStringsOnly', () {
    Parser.encodePayload(<Packet>[
      new Packet.values(PacketType.message, '€€€'),
      new Packet.values(PacketType.message, 'α'),
    ], new EncodeCallback((dynamic data) {
      expect(data, '4:4€€€2:4α');
    }));
  });

  test('decodePayloadBadFormat', () {
    Parser.decodePayload('1!', new DecodePayloadCallback((Packet packet, int index, int total) {
      final bool isLast = index + 1 == total;
      expect(packet.type, PacketType.error);
      expect(packet.data, equals(ERROR_DATA));
      expect(isLast, isTrue);
      return true;
    }));

    Parser.decodePayload('', new DecodePayloadCallback((Packet packet, int index, int total) {
      final bool isLast = index + 1 == total;
      expect(packet.type, PacketType.error);
      expect(packet.data, equals(ERROR_DATA));
      expect(isLast, isTrue);
      return true;
    }));

    Parser.decodePayload('))', new DecodePayloadCallback((Packet packet, int index, int total) {
      final bool isLast = index + 1 == total;
      expect(packet.type, PacketType.error);
      expect(packet.data, equals(ERROR_DATA));
      expect(isLast, isTrue);
      return true;
    }));
  });

  test('decodePayloadBadLength', () {
    Parser.decodePayload('1:', new DecodePayloadCallback((Packet packet, int index, int total) {
      final bool isLast = index + 1 == total;
      expect(packet.type, PacketType.error);
      expect(packet.data, equals(ERROR_DATA));
      expect(isLast, isTrue);
      return true;
    }));
  });

  test('decodePayloadBadPacketFormat', () {
    Parser.decodePayload('3:99:', new DecodePayloadCallback((Packet packet, int index, int total) {
      final bool isLast = index + 1 == total;
      expect(packet.type, PacketType.error);
      expect(packet.data, equals(ERROR_DATA));
      expect(isLast, isTrue);
      return true;
    }));

    Parser.decodePayload('1:aa', new DecodePayloadCallback((Packet packet, int index, int total) {
      final bool isLast = index + 1 == total;
      expect(packet.type, PacketType.error);
      expect(packet.data, equals(ERROR_DATA));
      expect(isLast, isTrue);
      return true;
    }));

    Parser.decodePayload('1:a2:b', new DecodePayloadCallback((Packet packet, int index, int total) {
      final bool isLast = index + 1 == total;
      expect(packet.type, PacketType.error);
      expect(packet.data, equals(ERROR_DATA));
      expect(isLast, isTrue);
      return true;
    }));
  });

  test('encodeBinaryMessage', () {
    final List<int> data = new List<int>(5);
    for (int i = 0; i < data.length; i++) {
      data[0] = i;
    }

    Parser.encodePacket(new Packet.values(PacketType.message, data),
        new EncodeCallback((dynamic encoded) {
      final Packet p = Parser.decodeBytePacket(encoded);
      expect(p.type, PacketType.message);
      expect(p.data, equals(data));

      return true;
    }));
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

    Parser.encodePayload(<Packet>[
      new Packet.values(PacketType.message, firstBuffer),
      new Packet.values(PacketType.message, secondBuffer)
    ], new EncodeCallback((dynamic data) {
      Parser.decodeBinaryPayload(data, new DecodePayloadCallback((Packet packet, int index, int total) {
        final bool isLast = index + 1 == total;
        expect(packet.type, PacketType.message);

        if (!isLast) {
          expect(packet.data, equals(firstBuffer));
        } else {
          expect(packet.data, equals(secondBuffer));
        }

        return true;
      }));
    }));
  });

  test('encodeMixedBinaryAndStringContents', () {
    final List<int> firstBuffer = new List<int>.generate(5, (_) => 0);
    for (int i = 0; i < firstBuffer.length; i++) {
      firstBuffer[0] = i;
    }

    Parser.encodePayload(<Packet>[
      new Packet.values(PacketType.message, firstBuffer),
      new Packet.values(PacketType.message, 'hello'),
      new Packet.values(PacketType.close),
    ], new EncodeCallback((dynamic encoded) {
      Parser.decodeBinaryPayload(encoded, new DecodePayloadCallback((Packet packet, int index, int total) {
        if (index == 0) {
          expect(packet.type, PacketType.message);
          expect(packet.data, equals(firstBuffer));
        } else if (index == 1) {
          expect(packet.type, PacketType.message);
          expect(packet.data, 'hello');
        } else {
          expect(packet.type, PacketType.close);
        }
        return true;
      }));
    }));
  });
}
