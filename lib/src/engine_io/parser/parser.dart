import 'dart:typed_data';

import 'package:engine_io_client/src/models/packet.dart';
import 'package:utf/utf.dart';

// ignore_for_file: avoid_as
// ignore_for_file: always_specify_types
const int MAX_INT_CHAR_LENGTH = 10;

typedef bool DecodePayload(Packet packet, int index, int total);

class Parser {
  static const int PROTOCOL = 3;

  Parser._();

  static Object encodePacket(Packet packet, [bool utf8encode = false]) {
    final Object data = packet.data;
    if (data is List<int>) {
      final int length = data.length + 1;
      final Int8List list = Int8List(1 + data.length);
      list[0] = packet.type.i;
      for (int i = 1; i < length; i++) list[i] = data[i - 1] ?? 0;

      return list;
    }

    String encoded = packet.type.i.toString();
    if (data != null) {
      encoded += utf8encode ? String.fromCharCodes(encodeUtf8(data as String)) : data.toString();
    }

    return encoded;
  }

  static Packet decodePacket(String data, [bool utf8decode = false]) {
    if (data == null) return Packet.error;

    int type;
    try {
      type = int.parse(String.fromCharCode(data.codeUnitAt(0)));
    } catch (e) {
      type = -1;
    }

    if (utf8decode) {
      try {
        data = decodeUtf8(data.codeUnits);
      } catch (e) {
        return Packet.error;
      }
    }

    if (type < 0 || type >= PacketType.values.length) return Packet.error;

    if (data.length > 1) {
      return Packet(PacketType.values[type], data.substring(1));
    } else {
      return Packet(PacketType.values[type]);
    }
  }

  static Packet decodeBytePacket(List<int> data) {
    final int type = data[0];
    final List<int> intArray = <int>[];

    intArray.addAll(data.sublist(1));

    return Packet(PacketType.values[type], intArray);
  }

  static dynamic /*String/List<int>*/ encodePayload(List<Packet> packets) {
    for (Packet packet in packets) {
      if (packet.data is List<int>) {
        return encodeBinaryPayload(packets);
      }
    }

    if (packets.isEmpty) return '0:';

    final StringBuffer result = StringBuffer();

    for (Packet packet in packets) {
      result.write(setLengthHeader(encodePacket(packet, false)));
    }

    return result.toString();
  }

  static String setLengthHeader(dynamic message) => '${message.length}:$message';

  static List<int> encodeBinaryPayload(List<Packet> packets) {
    if (packets.isEmpty) return Int8List(0);

    final List<Int8List> results = List<Int8List>.generate(packets.length, (_) => Int8List(0));

    for (Packet packet in packets) {
      results.add(encodeOneBinaryPacket(packet));
    }

    return results.fold<List<int>>(Int8List(0), (l1, l2) => l1 + l2);
  }

  static Int8List encodeOneBinaryPacket(Packet package) {
    final Object packet = encodePacket(package, true);
    if (packet is String) {
      final String encodingLength = packet.length.toString();
      final Int8List sizeBuffer = Int8List.fromList(List<int>.generate(encodingLength.length + 2, (_) => 0));

      sizeBuffer[0] = 0; // is a string
      for (int i = 0; i < encodingLength.length; i++) {
        sizeBuffer[i + 1] = _getNumericValue(encodingLength, i);
      }
      sizeBuffer[sizeBuffer.length - 1] = 255;

      return Int8List.fromList(sizeBuffer + packet.codeUnits);
    } else if (packet is Int8List) {
      final String encodingLength = packet.length.toString();
      final Int8List sizeBuffer = Int8List.fromList(List<int>.generate(encodingLength.length + 2, (_) => 0));

      sizeBuffer[0] = 1; // is binary
      for (int i = 0; i < encodingLength.length; i++) {
        sizeBuffer[i + 1] = _getNumericValue(encodingLength, i);
      }
      sizeBuffer[sizeBuffer.length - 1] = 255;

      return Int8List.fromList(sizeBuffer + packet);
    }

    throw StateError('The result can only be String and List<int>');
  }

  static int _getNumericValue(String encodingLength, int i) => int.parse(decodeUtf8(<int>[encodingLength.codeUnitAt(i)]));

  static List<Packet> decodePayload(String data) {
    if (data == null || data.isEmpty) return <Packet>[Packet.error];

    final List<Packet> packets = <Packet>[];

    final int l = data.length;
    final StringBuffer length = StringBuffer();
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
        return <Packet>[Packet.error];
      }

      String msg;
      try {
        msg = data.substring(i + 1, i + 1 + n);
      } catch (e) {
        return <Packet>[Packet.error];
      }

      if (msg.isNotEmpty) {
        final Packet packet = decodePacket(msg, false);
        if (Packet.error.type == packet.type && Packet.error.data == packet.data) {
          return <Packet>[Packet.error];
        }

        packets.add(packet);
      } else {
        final Packet packet = Packet(PacketType.values[n]);
        packets.add(packet);
      }

      i += n;
      length.clear();
    }

    if (length.length > 0) return <Packet>[Packet.error];

    return packets;
  }

  static List<Packet> decodeBinaryPayload(List<int> data) {
    Uint8List bufferTail = Uint8List.fromList(data);
    final List<Object> buffers = <Object>[];

    while (bufferTail.lengthInBytes > 0) {
      final StringBuffer strLen = StringBuffer();
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
      bufferTail = bufferTail.sublist(strLen.length + 1 + msgLength + 1) as Uint8List;
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
    final StringBuffer builder = StringBuffer();
    for (int b in bytes) {
      builder.writeCharCode(b & 0xFF);
    }
    return builder.toString();
  }
}
