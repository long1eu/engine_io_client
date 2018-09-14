import 'dart:async';

import 'package:engine_io_client/engine_io_client.dart';
import 'package:engine_io_client/src/engine_io/client/socket.dart';
import 'package:engine_io_client/src/engine_io/client/transport.dart';
import 'package:engine_io_client/src/engine_io/client/transports/polling.dart';
import 'package:engine_io_client/src/engine_io/client/transports/web_socket.dart';
import 'package:engine_io_client/src/models/handshake_data.dart';
import 'package:engine_io_client/src/models/socket_event.dart';
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() {
  final Log log = Log('server_connection_test');

  const SocketOptions opts = const SocketOptions(port: Connection.PORT);

  test('openAndClose', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Socket(opts);
    socket
      ..on(SocketEvent.open, (List<dynamic> args) async => values.add('onOpen'))
      ..on(SocketEvent.close, (List<dynamic> args) async => values.add('onClose'));

    socket.open();
    await Future<void>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});
    expect(values.first, 'onOpen');
    socket.close();
    await Future<void>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});
    expect(values.length, 2);
    expect(values.last, 'onClose');
  });

  test('messages', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Socket(opts);
    socket
      ..on(SocketEvent.open, (List<dynamic> args) => socket.send('hello'))
      ..on(SocketEvent.message, (List<dynamic> args) async => values.add(args[0]));

    socket.open();
    await Future<void>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(values[0], 'hi');
    expect(values[1], 'hello');
    socket.close();
  });

  test('handshake', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Socket(opts);
    socket.on(SocketEvent.handshake, (List<dynamic> args) async => values.add(args));
    socket.open();
    await Future<void>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    final List<dynamic> args = values[0];
    final HandshakeData handshakeData = args[0];
    expect(values.length, 1);
    expect(handshakeData.sessionId, isNotNull);
    expect(handshakeData.upgrades, isNotEmpty);
    expect(handshakeData.pingTimeout > 0, isTrue);
    expect(handshakeData.pingInterval > 0, isTrue);

    socket.close();
  });

  test('upgrade', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Socket(opts);
    socket
      ..on(SocketEvent.upgrading, (List<dynamic> args) async => values.add(args[0]))
      ..on(SocketEvent.upgrade, (List<dynamic> args) async => values.add(args[0]));
    socket.open();

    await Future<void>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(values[0] is Transport, isTrue);
    expect(values[0], isNotNull);
    expect(values[1] is Transport, isTrue);
    expect(values[1], isNotNull);

    socket.close();
  });

  test('pollingHeaders', () async {
    final List<dynamic> messages = <dynamic>[];

    final SocketOptions opts = SocketOptions(
        port: Connection.PORT,
        transports: const <String>[Polling.NAME],
        onRequestHeaders: (Map<String, String> headers) {
          log.e('main: requestHeaders');
          headers['X-EngineIO'] = 'foo';
          return headers;
        },
        onResponseHeaders: (Map<String, String> headers) {
          log.e('main: responseHeaders');
          print(headers);

          final List<String> values = headers['X-EngineIO'.toLowerCase()].split(',');
          messages.add(values[0]);
          messages.add(values[1]);
        });

    final Socket socket = Socket(opts);
    socket.open();

    await Future<void>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(messages[0], 'hi');
    expect(messages[1], 'foo');

    socket.close();
  });

  test('websocketHandshakeHeaders', () async {
    final List<dynamic> messages = <dynamic>[];

    final SocketOptions opts = SocketOptions(
        port: Connection.PORT,
        transports: const <String>[WebSocket.NAME],
        onRequestHeaders: (Map<String, String> headers) {
          log.e('main: requestHeaders $headers');
          headers['X-EngineIO'] = 'foo';
          return headers;
        },
        onResponseHeaders: (Map<String, String> headers) {
          log.e('main: responseHeaders $headers');

          final List<String> values = headers['X-EngineIO'.toLowerCase()].split(',');
          messages.add(values[0]);
          messages.add(values[1]);
        });

    final Socket socket = Socket(opts);

    socket.open();

    await Future<void>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(messages[0], 'hi');
    expect(messages[1], 'foo');

    socket.close();
  });

  test('rememberWebsocket', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Socket(opts);
    socket.on(SocketEvent.upgrade, (List<dynamic> args) async {
      final Transport transport = args[0];
      socket.close();

      if (transport.name == WebSocket.NAME) {
        const SocketOptions opts = const SocketOptions(port: Connection.PORT, rememberUpgrade: true);

        final Socket socket2 = Socket(opts);
        socket2.open();
        values.add(socket2.transport.name);
        socket2.close();
      }
    });
    socket.open();
    values.add(socket.transport.name);

    await Future<void>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(values[0], Polling.NAME);
    expect(values[1], WebSocket.NAME);

    socket.close();
  });

  test('notRememberWebsocket', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Socket(opts);
    socket.on(SocketEvent.upgrade, (List<dynamic> args) async {
      final Transport transport = args[0];
      socket.close();

      if (transport.name == WebSocket.NAME) {
        const SocketOptions opts = const SocketOptions(port: Connection.PORT, rememberUpgrade: false);

        final Socket socket2 = Socket(opts);
        socket2.open();
        values.add(socket2.transport.name);
        socket2.close();
      }
    });
    socket.open();
    values.add(socket.transport.name);

    await Future<void>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(values[0], Polling.NAME);
    expect(values[1], Polling.NAME);

    socket.close();
  });
}
