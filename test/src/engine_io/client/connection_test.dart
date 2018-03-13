import 'dart:async';

import 'package:flutter_logger/flutter_logger.dart';
import 'package:socket_io/src/engine_io/client/socket.dart';
import 'package:socket_io/src/models/socket_event.dart';
import 'package:socket_io/src/models/socket_options.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() {
  final Log log = new Log('connection');
  final SocketOptions opts = new SocketOptions((SocketOptionsBuilder b) {
    b..port = Connection.PORT;
  });

  test('connectToLocalhost', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (dynamic args) {
      socket.on(SocketEvent.message.name, (dynamic args) {
        values.add(args);
      });
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});

    expect(values.first, 'hi');
    socket.close();
  });

  test('receiveMultibyteUTF8StringsWithPolling', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (dynamic args) {
      socket.send('cash money €€€');
      socket.on(SocketEvent.message.name, (dynamic args) {
        if (args == 'hi') return;
        values.add(args);
        socket.close();
      });
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});

    expect(values.first, 'cash money €€€');
  });

  test('receiveEmoji', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (dynamic args) {
      socket.send('\uD800\uDC00-\uDB7F\uDFFF\uDB80\uDC00-\uDBFF\uDFFF\uE000-\uF8FF');
      socket.on(SocketEvent.message.name, (dynamic args) {
        if (args == 'hi') return;
        values.add(args);
        socket.close();
      });
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});

    expect(values.first, '\uD800\uDC00-\uDB7F\uDFFF\uDB80\uDC00-\uDBFF\uDFFF\uE000-\uF8FF');
  });

  test('notSendPacketsIfSocketCloses', () async {
    bool noPacket = true;

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (dynamic args) async {
      socket.on(SocketEvent.packetCreate.name, (dynamic args) => noPacket = false);

      await socket.close();
      socket.send('hi');
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});

    expect(noPacket, isTrue);
  });

  test('deferCloseWhenUpgrading', () async {
    bool upgraded = false;

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (dynamic args) {
      socket.on(SocketEvent.upgrade.name, (dynamic args) {
        log.d('main: $args');
        upgraded = true;
      }).on(SocketEvent.upgrading.name, (dynamic args) async {
        await socket.close();
      });
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});

    expect(upgraded, isTrue);
  });

  test('closeOnUpgradeErrorIfClosingIsDeferred', () async {
    bool upgradeError;

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (dynamic args) {
      socket.on(SocketEvent.upgradeError.name, (dynamic args) {
        log.d('main: $args');
        upgradeError = true;
      }).on(SocketEvent.upgrading.name, (dynamic args) async {
        log.d('main: $args');
        await socket.close();
        socket.transport.onError('upgrade error c', new Exception());
      });
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});

    expect(upgradeError, isTrue);
  });

  test('notSendPacketsIfClosingIsDeferred', () async {
    bool noPacket = true;

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (dynamic args) {
      socket.on(SocketEvent.upgrading.name, (dynamic args) async {
        socket.on(SocketEvent.packetCreate.name, (dynamic args) => noPacket = false);
        await socket.close();
        socket.send('hi');
      });
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});

    expect(noPacket, isTrue);
  });

  test('sendAllBufferedPacketsIfClosingIsDeferred', () async {
    int length;

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.open.name, (dynamic args) {
      socket.on(SocketEvent.upgrading.name, (dynamic args) async {
        socket.send('hsi');
        await socket.close();
      }).on(SocketEvent.close.name, (dynamic args) {
        log.d('close.name');
        length = socket.writeBuffer.length;
      });
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});

    expect(length, 0);
  });
}
