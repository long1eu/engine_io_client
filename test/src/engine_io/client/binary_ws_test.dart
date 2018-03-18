import 'dart:async';

import 'package:engine_io_client/src/engine_io/client/socket.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/socket_event.dart';
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() async {
  final Log log = new Log('EngineIo.binary_ws_connection');
  Socket socket;

  test('receiveBinaryData', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> binaryData = <int>[]..length = 5;
    for (int i = 0; i < binaryData.length; i++) {
      binaryData[i] = i;
    }

    final SocketOptions opts = new SocketOptions((SocketOptionsBuilder b) {
      b..port = Connection.PORT;
    });

    socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (List<dynamic> args) {
      log.d('open');
      socket.on(SocketEvent.upgrade.name, (List<dynamic> args) async {
        log.d('upgrade');
        socket.on(SocketEvent.message.name, (List<dynamic> args) {
          log.d('args: $args');
          if (args[0] == 'hi') return;
          values.add(args[0]);
        });
        await socket.send(binaryData);
      });
    });
    await socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(values.first, binaryData);
    socket.close();
  });

  test('receiveBinaryDataAndMultibyteUTF8String', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> binaryData = new List<int>.generate(5, (_) => 0);
    for (int i = 0; i < binaryData.length; i++) binaryData[0] = i;

    final SocketOptions opts = new SocketOptions((SocketOptionsBuilder b) {
      b..port = Connection.PORT;
    });

    socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (List<dynamic> args) {
      socket.on(SocketEvent.upgrade.name, (List<dynamic> args) async {
        socket.on(SocketEvent.message.name, (List<dynamic> args) {
          log.d('args: $args');
          if (args[0] == 'hi') return;
          values.add(args[0]);
        });

        await socket.send(binaryData);
        await socket.send('cash money €€€');
        await socket.send('cash money ss €€€');
      });
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(values[0], binaryData);
    expect(values[1], 'cash money €€€');
    expect(values[2], 'cash money ss €€€');
    socket.close();
  });
}
