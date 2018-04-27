import 'dart:async';

import 'package:engine_io_client/src/engine_io/client/socket.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() {
  final Log log = new Log('EngineIo.connection');

  final SocketOptions opts = new SocketOptions(port: Connection.PORT);

  test('connectToLocalhost', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket.on(Socket.eventOpen, (List<dynamic> args) {
      socket.on(Socket.eventMessage, (List<dynamic> args) {
        values.add(args[0]);
      });
    });
    await socket.open$();
    await new Future<Null>.delayed(const Duration(milliseconds: 20000), () {});
    log.d(values);

    //expect(values.first, 'hi');
    await socket.close$();
  });

  test('receiveMultibyteUTF8StringsWithPolling', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket.on(Socket.eventOpen, (List<dynamic> args) async {
      await socket.send$('cash money €€€');
      socket.on(Socket.eventMessage, (List<dynamic> args) async {
        log.e(args);
        if (args[0] == 'hi') return;
        values.add(args[0]);
        await socket.close$();
      });
    });
    await socket.open$();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(values.first, 'cash money €€€');
  });

  test('receiveEmoji', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket.on(Socket.eventOpen, (List<dynamic> args) async {
      await socket.send$('\uD800\uDC00-\uDB7F\uDFFF\uDB80\uDC00-\uDBFF\uDFFF\uE000-\uF8FF');
      socket.on(Socket.eventMessage, (List<dynamic> args) async {
        if (args[0] == 'hi') return;
        values.add(args[0]);
        await socket.close$();
      });
    });
    await socket.open$();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(values.first, '\uD800\uDC00-\uDB7F\uDFFF\uDB80\uDC00-\uDBFF\uDFFF\uE000-\uF8FF');
  });

  test('notSendPacketsIfSocketCloses', () async {
    bool noPacket = true;

    final Socket socket = new Socket(opts);
    socket.on(Socket.eventOpen, (List<dynamic> args) async {
      socket.on(Socket.eventPacketCreate, (List<dynamic> args) async {
        noPacket = false;
      });

      await socket.close$();
      await socket.send$('hi');
    });
    await socket.open$();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(noPacket, isTrue);
  });

  test('deferCloseWhenUpgrading', () async {
    bool upgraded = false;

    final Socket socket = new Socket(opts);
    socket.on(Socket.eventOpen, (List<dynamic> args) {
      socket
        ..on(Socket.eventUpgrade, (List<dynamic> args) {
          log.d('main: $args');
          upgraded = true;
        })
        ..on(Socket.eventUpgrading, (List<dynamic> args) async {
          await socket.close$();
        });
    });
    await socket.open$();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(upgraded, isTrue);
  });

  test('closeOnUpgradeErrorIfClosingIsDeferred', () async {
    bool upgradeError;

    final Socket socket = new Socket(opts);
    socket.on(Socket.eventOpen, (List<dynamic> args) {
      socket
        ..on(Socket.eventUpgradeError, (List<dynamic> args) {
          log.d('main: $args');
          upgradeError = true;
        })
        ..on(Socket.eventUpgrading, (List<dynamic> args) async {
          log.d('main: $args');
          await socket.close$();
          await socket.transport.onError('upgrade error c', new Exception());
        });
    });
    await socket.open$();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(upgradeError, isTrue);
  });

  test('notSendPacketsIfClosingIsDeferred', () async {
    bool noPacket = true;

    final Socket socket = new Socket(opts);
    socket.on(Socket.eventOpen, (List<dynamic> args) {
      socket.on(Socket.eventUpgrading, (List<dynamic> args) async {
        socket.on(Socket.eventPacketCreate, (List<dynamic> args) async {
          noPacket = false;
        });
        await socket.close$();
        await socket.send$('hi');
      });
    });
    await socket.open$();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(noPacket, isTrue);
  });

  test('sendAllBufferedPacketsIfClosingIsDeferred', () async {
    int length;

    final Socket socket = new Socket(opts);
    socket.on(Socket.eventOpen, (List<dynamic> args) {
      socket
        ..on(Socket.eventUpgrading, (List<dynamic> args) async {
          await socket.send$('hsi');
          await socket.close$();
        })
        ..on(Socket.eventClose, (List<dynamic> args) {
          log.d('close.name');
          length = socket.writeBuffer.length;
        });
    });
    await socket.open$();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(length, 0);
  });
}
