import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:flutter_logger/flutter_logger.dart';
import 'package:socket_io_engine/src/engine_io/client/socket.dart';
import 'package:socket_io_engine/src/engine_io/client/transports/polling.dart';
import 'package:socket_io_engine/src/models/socket_event.dart';
import 'package:socket_io_engine/src/models/socket_options.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() async {
  final Log log = new Log('binary_connection');
  Socket socket;

  test('receiveBinaryData', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> binaryData = <int>[]..length = 5;
    for (int i = 0; i < binaryData.length; i++) {
      binaryData[i] = i;
    }

    final SocketOptions opts = new SocketOptions((SocketOptionsBuilder b) {
      b
        ..port = Connection.PORT
        ..transports = new ListBuilder<String>(<String>[Polling.NAME]);
    });

    socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (dynamic args) {
      log.d('open');
      socket.send(binaryData);
      socket.on(SocketEvent.message.name, (dynamic args) {
        log.d('args: $args');
        if (args == 'hi') return;
        values.add(args);
      });
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});

    expect(values.first, binaryData);
    socket.close();
  });

  test('receiveBinaryDataAndMultibyteUTF8String', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> binaryData = new List<int>.generate(5, (_) => 0);
    for (int i = 0; i < binaryData.length; i++) binaryData[i] = i;

    final SocketOptions opts = new SocketOptions((SocketOptionsBuilder b) {
      b
        ..port = Connection.PORT
        ..transports = new ListBuilder<String>(<String>[Polling.NAME]);
    });

    socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (dynamic args) async {
      log.d('open');
      socket.on(SocketEvent.message.name, (dynamic args) {
        log.d('args: $args');
        if (args == 'hi') return;
        values.add(args);
      });

      await socket.send(binaryData);
      await socket.send('cash money €€€');
      await socket.send('cash money ss €€€');
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});

    log.d(values.toString());
    expect(values[0], binaryData);
    expect(values[1], 'cash money €€€');
    expect(values[2], 'cash money ss €€€');
    socket.close();
  });
}
