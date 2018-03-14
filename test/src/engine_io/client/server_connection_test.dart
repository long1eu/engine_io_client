import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:socket_io_engine/src/engine_io/client/socket.dart';
import 'package:socket_io_engine/src/engine_io/client/transport.dart';
import 'package:socket_io_engine/src/engine_io/client/transports/polling.dart';
import 'package:socket_io_engine/src/engine_io/client/transports/web_socket.dart';
import 'package:socket_io_engine/src/models/handshake_data.dart';
import 'package:socket_io_engine/src/models/socket_event.dart';
import 'package:socket_io_engine/src/models/socket_options.dart';
import 'package:socket_io_engine/src/models/transport_event.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() {
  final SocketOptions opts = new SocketOptions((SocketOptionsBuilder b) {
    b..port = Connection.PORT;
  });

  test('openAndClose', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket
        .on(SocketEvent.open.name, (dynamic args) => values.add('onOpen'))
        .on(SocketEvent.close.name, (dynamic args) => values.add('onClose'));

    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    expect(values.first, 'onOpen');
    await socket.close();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    expect(values.length, 2);
    expect(values.last, 'onClose');
  });

  test('messages', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket
        .on(SocketEvent.open.name, (dynamic args) => socket.send('hello'))
        .on(SocketEvent.message.name, (dynamic args) => values.add(args));

    await socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});

    expect(values[0], 'hi');
    expect(values[1], 'hello');
    socket.close();
  });

  test('handshake', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.handshake.name, (dynamic args) => values.add(args));
    await socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});

    final HandshakeData handshakeData = values[0];
    expect(handshakeData.sessionId, isNotNull);
    expect(handshakeData.upgrades, isNotEmpty);
    expect(handshakeData.pingTimeout > 0, isTrue);
    expect(handshakeData.pingInterval > 0, isTrue);

    socket.close();
  });

  test('upgrade', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket
        .on(SocketEvent.upgrading.name, (dynamic args) => values.add(args))
        .on(SocketEvent.upgrade.name, (dynamic args) => values.add(args));
    await socket.open();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});

    expect(values[0] is Transport, isTrue);
    expect(values[0], isNotNull);
    expect(values[1] is Transport, isTrue);
    expect(values[1], isNotNull);

    socket.close();
  });

  test('pollingHeaders', () async {
    final List<dynamic> messages = <dynamic>[];

    final SocketOptions opts = new SocketOptions((SocketOptionsBuilder b) {
      b
        ..port = Connection.PORT
        ..transports = new ListBuilder<String>(<String>[Polling.NAME]);
    });

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.transport.name, (dynamic args) {
      final Transport transport = args;
      transport.on(TransportEvent.requestHeaders.name, (dynamic args) {
        final Map<String, List<String>> headers = args;
        headers['X-EngineIO'] = <String>['foo'];
      }).on(TransportEvent.responseHeaders.name, (dynamic args) {
        final Map<String, List<String>> headers = args;
        print(headers);

        final List<String> values = headers['X-EngineIO'.toLowerCase()][0].split(',');
        messages.add(values[0]);
        messages.add(values[1]);
      });
    });
    await socket.open();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});

    expect(messages[0], 'hi');
    expect(messages[1], 'foo');

    socket.close();
  });

  //This will fail because WebSocket doesn't have a way to retrieve the headers
  test('websocketHandshakeHeaders', () async {
    final List<dynamic> messages = <dynamic>[];

    final SocketOptions opts = new SocketOptions((SocketOptionsBuilder b) {
      b
        ..port = Connection.PORT
        ..transports = new ListBuilder<String>(<String>[WebSocket.NAME]);
    });

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.transport.name, (dynamic args) {
      final Transport transport = args;
      transport.on(TransportEvent.requestHeaders.name, (dynamic args) {
        final Map<String, List<String>> headers = args;
        headers['X-EngineIO'] = <String>['foo'];
      }).on(TransportEvent.responseHeaders.name, (dynamic args) {
        final Map<String, List<String>> headers = args;
        print(headers);

        final List<String> values = headers['X-EngineIO'.toLowerCase()][0].split(',');
        messages.add(values[0]);
        messages.add(values[1]);
      });
    });
    await socket.open();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});

    expect(messages[0], 'hi');
    expect(messages[1], 'foo');

    socket.close();
  });

  test('rememberWebsocket', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.upgrade.name, (dynamic args) async {
      final Transport transport = args;
      await socket.close();

      if (transport.name == WebSocket.NAME) {
        final SocketOptions opts = new SocketOptions((b) {
          b
            ..port = Connection.PORT
            ..rememberUpgrade = true;
        });

        final Socket socket2 = new Socket(opts);
        await socket2.open();
        values.add(socket2.transport.name);
        socket2.close();
      }
    });
    await socket.open();
    values.add(socket.transport.name);

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});

    expect(values[0], Polling.NAME);
    expect(values[1], WebSocket.NAME);

    socket.close();
  });

  test('notRememberWebsocket', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket.on(SocketEvent.upgrade.name, (dynamic args) async {
      final Transport transport = args;
      await socket.close();

      if (transport.name == WebSocket.NAME) {
        final SocketOptions opts = new SocketOptions((b) {
          b
            ..port = Connection.PORT
            ..rememberUpgrade = false;
        });

        final Socket socket2 = new Socket(opts);
        await socket2.open();
        values.add(socket2.transport.name);
        socket2.close();
      }
    });
    await socket.open();
    values.add(socket.transport.name);

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});

    expect(values[0], Polling.NAME);
    expect(values[1], Polling.NAME);

    socket.close();
  });
}
