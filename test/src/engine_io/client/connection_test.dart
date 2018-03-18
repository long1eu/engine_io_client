import 'dart:async';

import 'package:engine_io_client/src/engine_io/client/socket.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/socket_event.dart';
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() {
  final Log log = new Log('EngineIo.connection');
  final SocketOptions opts = new SocketOptions((SocketOptionsBuilder b) {
    b..port = Connection.PORT;
  });

  test('connectToLocalhost', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (List<dynamic> args) {
      socket.on(SocketEvent.message.name, (List<dynamic> args) {
        values.add(args[0]);
      });
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(values.first, 'hi');
    socket.close();
  });

  test('receiveMultibyteUTF8StringsWithPolling', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (List<dynamic> args) {
      socket.send('cash money €€€');
      socket.on(SocketEvent.message.name, (List<dynamic> args) {
        if (args[0] == 'hi') return;
        values.add(args[0]);
        socket.close();
      });
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(values.first, 'cash money €€€');
  });

  test('receiveEmoji', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (List<dynamic> args) {
      socket.send('\uD800\uDC00-\uDB7F\uDFFF\uDB80\uDC00-\uDBFF\uDFFF\uE000-\uF8FF');
      socket.on(SocketEvent.message.name, (List<dynamic> args) {
        if (args[0] == 'hi') return;
        values.add(args[0]);
        socket.close();
      });
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(values.first, '\uD800\uDC00-\uDB7F\uDFFF\uDB80\uDC00-\uDBFF\uDFFF\uE000-\uF8FF');
  });

  test('notSendPacketsIfSocketCloses', () async {
    bool noPacket = true;

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (List<dynamic> args) async {
      socket.on(SocketEvent.packetCreate.name, (List<dynamic> args) => noPacket = false);

      await socket.close();
      socket.send('hi');
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(noPacket, isTrue);
  });

  test('deferCloseWhenUpgrading', () async {
    bool upgraded = false;

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (List<dynamic> args) {
      socket
        ..on(SocketEvent.upgrade.name, (List<dynamic> args) {
          log.d('main: $args');
          upgraded = true;
        })
        ..on(SocketEvent.upgrading.name, (List<dynamic> args) async {
          await socket.close();
        });
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(upgraded, isTrue);
  });

  test('closeOnUpgradeErrorIfClosingIsDeferred', () async {
    bool upgradeError;

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (List<dynamic> args) {
      socket
        ..on(SocketEvent.upgradeError.name, (List<dynamic> args) {
          log.d('main: $args');
          upgradeError = true;
        })
        ..on(SocketEvent.upgrading.name, (List<dynamic> args) async {
          log.d('main: $args');
          await socket.close();
          socket.transport.onError('upgrade error c', new Exception());
        });
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(upgradeError, isTrue);
  });

  test('notSendPacketsIfClosingIsDeferred', () async {
    bool noPacket = true;

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (List<dynamic> args) {
      socket.on(SocketEvent.upgrading.name, (List<dynamic> args) async {
        socket.on(SocketEvent.packetCreate.name, (List<dynamic> args) => noPacket = false);
        await socket.close();
        socket.send('hi');
      });
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(noPacket, isTrue);
  });

  test('sendAllBufferedPacketsIfClosingIsDeferred', () async {
    int length;

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (List<dynamic> args) {
      socket
        ..on(SocketEvent.upgrading.name, (List<dynamic> args) async {
          socket.send('hsi');
          await socket.close();
        })
        ..on(SocketEvent.close.name, (List<dynamic> args) {
          log.d('close.name');
          length = socket.writeBuffer.length;
        });
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(length, 0);
  });
}
