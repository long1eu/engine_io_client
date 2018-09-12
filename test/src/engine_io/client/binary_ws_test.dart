import 'dart:async';

import 'package:engine_io_client/src/engine_io/client/socket.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/socket_event.dart';
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() async {
  final Log log = Log('EngineIo.binary_ws_connection');
  const SocketOptions opts = const SocketOptions(port: Connection.PORT);
  Socket socket;

  test('receiveBinaryData', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> binaryData = <int>[]..length = 5;
    for (int i = 0; i < binaryData.length; i++) {
      binaryData[i] = i;
    }

    socket = Socket(opts);
    socket.on(SocketEvent.open, (List<dynamic> args) {
      log.e('open');
      socket.on(SocketEvent.upgrade, (List<dynamic> args) async {
        log.e('upgrade');
        socket.on(SocketEvent.message, (List<dynamic> args) {
          log.e('args: $args');
          if (args[0] == 'hi') return;
          values.add(args[0]);
        });
        await socket.send(binaryData);
      });
    });
    socket.open();
    await Future<void>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(values.first, binaryData);
    socket.close();
  });

  test('receiveBinaryDataAndMultibyteUTF8String', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> binaryData = List<int>.generate(5, (_) => 0);
    for (int i = 0; i < binaryData.length; i++) binaryData[0] = i;

    socket = Socket(opts);
    socket.on(SocketEvent.open, (List<dynamic> args) {
      log.e('main: open');
      socket.on(SocketEvent.upgrade, (List<dynamic> args) async {
        log.e('main: upgrade');
        socket.on(SocketEvent.message, (List<dynamic> args) {
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
    await Future<void>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});
    log.d(values.toString());
    expect(values[0], binaryData);
    expect(values[1], 'cash money €€€');
    expect(values[2], 'cash money ss €€€');
    socket.close();
  });
}
