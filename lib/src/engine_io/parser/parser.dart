import 'dart:typed_data';

import 'package:socket_io/src/models/packet.dart';
import 'package:socket_io/src/models/packet_type.dart';
import 'package:utf/utf.dart';

// ignore_for_file: avoid_as
// ignore_for_file: always_specify_types
const int MAX_INT_CHAR_LENGTH = 10;
const int PROTOCOL = 3;

typedef void VoidCallback<T>(T data);
typedef bool DecodePayload<T>(Packet<T> packet, int index, int total);

class Parser {
  Parser._();

  static void encodePacket(Packet packet, EncodeCallback callback, [bool utf8encode = false]) {
    final dynamic data = packet.data;
    if (data is List<int>) {
      final List<int> list = <int>[]
        ..insert(0, packet.type.index)
        ..insertAll(1, data);
      callback.call(list);
      return;
    }

    String encoded = packet.type.index.toString();
    if (data != null) {
      encoded += utf8encode ? new String.fromCharCodes(encodeUtf8(data)) : data.toString();
    }
    callback.call(encoded);
  }

  static Packet<String> decodePacket(String data, [bool utf8decode = false]) {
    if (data == null) return Packet.error;

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
        return Packet.error;
      }
    }

    if (type < 0 || type >= PacketType.values.length) return Packet.error;

    if (data.length > 1) {
      return new Packet<String>.fromValues(type, data.substring(1));
    } else {
      return new Packet<String>.fromValues(type);
    }
  }

  static Packet<List<int>> decodeBytePacket(List<int> data) {
    final int type = data[0];
    final List<int> intArray = <int>[];

    intArray.addAll(data.sublist(1));

    return new Packet<List<int>>.fromValues(type, intArray);
  }

  static void encodePayload(List<Packet> packets, EncodeCallback callback) {
    for (Packet packet in packets) {
      if (packet.data is List<int>) {
        encodeBinaryPayload(packets, callback);
        return;
      }
    }

    if (packets.isEmpty) {
      callback.call('0:');
      return;
    }

    final StringBuffer result = new StringBuffer();

    for (Packet packet in packets) {
      encodePacket(packet, new EncodeCallback<dynamic>((dynamic message) {
        result.write(setLengthHeader(message as String));
      }), false);
    }

    callback.call(result.toString());
  }

  static String setLengthHeader(String message) => '${message.length}:$message';

  static void encodeBinaryPayload(List<Packet> packets, EncodeCallback callback) {
    if (packets.isEmpty) {
      callback.call(new List<int>(0));
      return;
    }

    final List<List<int>> results = new List<List<int>>.generate(packets.length, (_) => <int>[]);

    for (Packet packet in packets) {
      encodeOneBinaryPacket(packet, new EncodeCallback<List<int>>((List<int> data) {
        results.add(data);
      }));
    }

    callback.call(results.fold<Int8List>(new Int8List(0), (l1, l2) => l1 + l2));
  }

  static void encodeOneBinaryPacket(Packet package, EncodeCallback doneCallback) {
    encodePacket(package, new EncodeCallback<dynamic>((Object packet) {
      if (packet is String) {
        final String encodingLength = packet.length.toString();
        final List<int> sizeBuffer = new Int8List.fromList(new List<int>.generate(encodingLength.length + 2, (_) => 0));

        sizeBuffer[0] = 0; // is a string
        for (int i = 0; i < encodingLength.length; i++) {
          sizeBuffer[i + 1] = _getNumericValue(encodingLength, i);
        }
        sizeBuffer[sizeBuffer.length - 1] = 255;

        doneCallback.call(sizeBuffer + packet.codeUnits);
        return;
      } else if (packet is List<int>) {
        final String encodingLength = packet.length.toString();
        final List<int> sizeBuffer = new Int8List.fromList(new List<int>.generate(encodingLength.length + 2, (_) => 0));

        sizeBuffer[0] = 1; // is binary
        for (int i = 0; i < encodingLength.length; i++) {
          sizeBuffer[i + 1] = _getNumericValue(encodingLength, i);
        }
        sizeBuffer[sizeBuffer.length - 1] = 255;

        doneCallback.call(sizeBuffer + packet);
      }
    }), true);
  }

  static int _getNumericValue(String encodingLength, int i) => int.parse(decodeUtf8(<int>[encodingLength.codeUnitAt(i)]));

  static void decodePayload(String data, DecodePayloadCallback<String> callback) {
    if (data == null || data.isEmpty) {
      callback.call(Packet.error, 0, 1);
      return;
    }

    final int l = data.length;
    StringBuffer length = new StringBuffer();
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
        callback.call(Packet.error, 0, 1);
        return;
      }

      String msg;
      try {
        msg = data.substring(i + 1, i + 1 + n);
      } catch (e) {
        callback.call(Packet.error, 0, 1);
        return;
      }

      if (msg.isNotEmpty) {
        final Packet<String> packet = decodePacket(msg, false);
        if (Packet.error.type == packet.type && Packet.error.data == packet.data) {
          callback.call(Packet.error, 0, 1);
          return;
        }

        final bool ret = callback.call(packet, i + n, l);
        if (!ret) {
          return;
        }
      }

      i += n;
      length = new StringBuffer();
    }

    if (length.length > 0) {
      callback.call(Packet.error, 0, 1);
    }
  }

  static void decodeBinaryPayload(List<int> data, DecodePayloadCallback callback) {
    List<int> bufferTail = new Int8List.fromList(data);
    final List<Object> buffers = <Object>[];

    while (bufferTail.isNotEmpty) {
      final StringBuffer strLen = new StringBuffer();
      final bool isString = (bufferTail[0] & 0xFF) == 0;
      for (int i = 1;; i++) {
        final int b = bufferTail[i] & 0xFF;

        if (b == 255) break;
        // supports only integer
        if (strLen.length > MAX_INT_CHAR_LENGTH) {
          callback.call(Packet.binaryError, 0, 1);
          return;
        }
        strLen.write(b);
      }

      final int msgLength = int.parse(strLen.toString());

      final List<int> msg = bufferTail.sublist(3, msgLength + 3);

      if (isString) {
        buffers.add(new String.fromCharCodes(msg));
      } else {
        buffers.add(msg);
      }

      bufferTail = bufferTail.sublist(msgLength + 3);
    }

    final int total = buffers.length;
    for (int i = 0; i < total; i++) {
      final Object buffer = buffers[i];
      if (buffer is String) {
        callback.call(decodePacket(buffer, true), i, total);
      } else if (buffer is List<int>) {
        callback.call(decodeBytePacket(buffer), i, total);
      }
    }
  }
}

class EncodeCallback<T> {
  EncodeCallback(this.call);

  final VoidCallback<T> call;
}

class DecodePayloadCallback<T> {
  DecodePayloadCallback(this.call);

  final DecodePayload<T> call;
}
