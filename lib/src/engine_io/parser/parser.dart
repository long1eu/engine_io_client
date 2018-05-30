import 'dart:typed_data';

import 'package:engine_io_client/src/models/packet.dart';
import 'package:utf/utf.dart';

const int MAX_INT_CHAR_LENGTH = 10;

typedef bool DecodePayload(Packet packet, int index, int total);

class Parser {
  static const int PROTOCOL = 3;

  Parser._();

  static dynamic encodePacket(Packet packet, [bool utf8encode = false]) {
    final dynamic data = packet.data;
    if (data is List<int>) {
      final int length = data.length + 1;
      final Int8List list = new Int8List(1 + data.length);
      list[0] = Packet.index(packet.type);
      for (int i = 1; i < length; i++) list[i] = data[i - 1] ?? 0;

      return list;
    }

    String encoded = Packet.index(packet.type).toString();
    if (data != null) {
      encoded += utf8encode ? new String.fromCharCodes(encodeUtf8(data)) : data.toString();
    }

    return encoded;
  }

  static Packet decodePacket(String data, [bool utf8decode = false]) {
    if (data == null) return Packet.errorPacket;

    int type;
    try {
      type = int.parse(new String.fromCharCode(data.codeUnitAt(0)));
    } catch (e) {
      type = -1;
    }

    if (utf8decode) {
      try {
        data = decodeUtf8(data.codeUnits);
      } catch (e) {
        return Packet.errorPacket;
      }
    }

    if (type < 0 || type >= Packet.values.length) return Packet.errorPacket;

    if (data.length > 1) {
      return new Packet.fromValues(type, data.substring(1));
    } else {
      return new Packet.fromValues(type);
    }
  }

  static Packet decodeBytePacket(List<int> data) {
    final int type = data[0];
    final List<int> intArray = <int>[];

    intArray.addAll(data.sublist(1));

    return new Packet.fromValues(type, intArray);
  }

  static dynamic encodePayload(List<Packet> packets) {
    for (Packet packet in packets) {
      if (packet.data is List<int>) {
        return encodeBinaryPayload(packets);
      }
    }

    if (packets.isEmpty) return '0:';

    final StringBuffer result = new StringBuffer();

    for (Packet packet in packets) {
      // ignore: avoid_as
      result.write(setLengthHeader(encodePacket(packet, false) as String));
    }

    return result.toString();
  }

  static String setLengthHeader(String message) => '${message.length}:$message';

  static List<int> encodeBinaryPayload(List<Packet> packets) {
    if (packets.isEmpty) return new Int8List(0);

    final List<Int8List> results = new List<Int8List>.generate(packets.length, (_) => new Int8List(0));

    for (Packet packet in packets) {
      results.add(encodeOneBinaryPacket(packet));
    }

    return results.fold<Int8List>(new Int8List(0), (l1, l2) => l1 + l2);
  }

  static Int8List encodeOneBinaryPacket(Packet package) {
    final dynamic packet = encodePacket(package, true);
    if (packet is String) {
      final String encodingLength = packet.length.toString();
      final Int8List sizeBuffer = new Int8List.fromList(new List<int>.generate(encodingLength.length + 2, (_) => 0));

      sizeBuffer[0] = 0; // is a string
      for (int i = 0; i < encodingLength.length; i++) {
        sizeBuffer[i + 1] = _getNumericValue(encodingLength, i);
      }
      sizeBuffer[sizeBuffer.length - 1] = 255;

      return new Int8List.fromList(sizeBuffer + packet.codeUnits);
    } else if (packet is Int8List) {
      final String encodingLength = packet.length.toString();
      final Int8List sizeBuffer = new Int8List.fromList(new List<int>.generate(encodingLength.length + 2, (_) => 0));

      sizeBuffer[0] = 1; // is binary
      for (int i = 0; i < encodingLength.length; i++) {
        sizeBuffer[i + 1] = _getNumericValue(encodingLength, i);
      }
      sizeBuffer[sizeBuffer.length - 1] = 255;

      return new Int8List.fromList(sizeBuffer + packet);
    }

    throw new StateError('The result can only be String and List<int>');
  }

  static int _getNumericValue(String encodingLength, int i) => int.parse(decodeUtf8(<int>[encodingLength.codeUnitAt(i)]));

  static List<Packet> decodePayload(String data) {
    if (data == null || data.isEmpty) return <Packet>[Packet.errorPacket];

    final List<Packet> packets = <Packet>[];

    final int l = data.length;
    final StringBuffer length = new StringBuffer();
    for (int i = 0; i < l; i++) {
      final int chr = data.codeUnitAt(i);

      if (':'.codeUnitAt(0) != chr) {
        length.writeCharCode(chr);
        continue;
      }

      int n;
      try {
        n = int.parse(length.toString());
      } catch (e) {
        return <Packet>[Packet.errorPacket];
      }

      String msg;
      try {
        msg = data.substring(i + 1, i + 1 + n);
      } catch (e) {
        return <Packet>[Packet.errorPacket];
      }

      if (msg.isNotEmpty) {
        final Packet packet = decodePacket(msg, false);
        if (Packet.errorPacket.type == packet.type && Packet.errorPacket.data == packet.data) {
          return <Packet>[Packet.errorPacket];
        }

        packets.add(packet);
      } else {
        final Packet packet = new Packet.fromValues(n);
        packets.add(packet);
      }

      i += n;
      length.clear();
    }

    if (length.length > 0) return <Packet>[Packet.errorPacket];

    return packets;
  }

  static List<Packet> decodeBinaryPayload(List<int> data) {
    Uint8List bufferTail = new Uint8List.fromList(data);
    final List<Object> buffers = <Object>[];

    while (bufferTail.lengthInBytes > 0) {
      final StringBuffer strLen = new StringBuffer();
      final bool isString = (bufferTail[0] & 0xFF) == 0;
      for (int i = 1;; i++) {
        final int b = bufferTail[i] & 0xFF;
        if (b == 255) break;
        // supports only integer
        if (strLen.length > MAX_INT_CHAR_LENGTH) {
          return <Packet>[Packet.binaryError];
        }
        strLen.write(b);
      }

      final Uint8List currentList = bufferTail.sublist(strLen.length + 1);
      final int msgLength = int.parse(strLen.toString());

      final Uint8List msg = currentList.sublist(1, msgLength + 1);
      if (isString) {
        buffers.add(byteArrayToString(msg));
      } else {
        buffers.add(msg);
      }
      bufferTail = bufferTail.sublist(strLen.length + 1 + msgLength + 1);
    }

    final List<Packet> packets = <Packet>[];
    final int total = buffers.length;
    for (int i = 0; i < total; i++) {
      final Object buffer = buffers[i];
      if (buffer is String) {
        packets.add(decodePacket(buffer, true));
      } else if (buffer is List<int>) {
        packets.add(decodeBytePacket(buffer));
      }
    }

    return packets;
  }

  static String byteArrayToString(Uint8List bytes) {
    final StringBuffer builder = new StringBuffer();
    for (int b in bytes) {
      builder.writeCharCode(b & 0xFF);
    }
    return builder.toString();
  }
}
