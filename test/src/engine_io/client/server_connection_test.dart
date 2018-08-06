import 'dart:async';

import 'package:engine_io_client/engine_io_client.dart';
import 'package:engine_io_client/src/engine_io/client/socket.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/handshake_data.dart';
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() {
  final Log log = new Log('server_connection_test');

  const SocketOptions opts = const SocketOptions(port: Connection.PORT);

  test('openAndClose', () async {
    final Socket socket = new Socket(opts);

    final Observable<Event> events$ = new Observable<Event>.merge(<Observable<Event>>[
      socket.on(Socket.eventOpen),
      socket.on(Socket.eventClose).map((Event event) => new Event(Socket.eventClose)),
    ]);

    socket.open();
    socket.close();
    expect(events$, emitsInOrder(<Event>[new Event(Socket.eventOpen), new Event(Socket.eventClose)]));
  });

  test('messages', () async {
    final Socket socket = new Socket(opts);

    final Observable<Event> events$ = new Observable<Event>.merge(<Observable<Event>>[
      socket.on(Socket.eventOpen).flatMap((Event event) => socket.write$('hello')).ignoreElements(),
      socket.on(Socket.eventMessage).map((Event event) => event.args[0]),
    ]);

    socket.open();

    expect(events$, emitsInOrder(<String>['hi', 'hello']));
  });

  test('handshake', () async {
    final Socket socket = new Socket(opts);

    socket.open();
    final HandshakeData handshakeData = (await socket.on(Socket.eventHandshake).first).args[0];

    expect(handshakeData.sessionId, isNotNull);
    expect(handshakeData.upgrades, isNotEmpty);
    expect(handshakeData.pingTimeout > 0, isTrue);
    expect(handshakeData.pingInterval > 0, isTrue);
  });

  test('upgrade', () async {
    final Socket socket = new Socket(opts);

    final Observable<Event> events$ = new Observable<Event>.merge(<Observable<Event>>[
      socket.on(Socket.eventUpgrading),
      socket.on(Socket.eventUpgrade),
    ]).map((Event event) => event.args[0].options.socket.transport.name);

    socket.open();

    expect(events$, emitsInOrder(<String>['polling', 'websocket']));
  });

  test('pollingHeaders', () async {
    const SocketOptions opts = const SocketOptions(port: Connection.PORT, transports: const <String>[
      Polling.NAME
    ], headers: const <String, List<String>>{
      'X-EngineIO': const <String>['foo']
    });
    final Socket socket = new Socket(opts);

    final Observable<Event> events$ = socket
        .on(Socket.eventTransport)
        .doOnData((Event event) => log.e(event.args[0]))
        .flatMap<Event>((Event event) => event.args[0].on(Transport.eventResponseHeaders))
        .map<dynamic>((Event event) => event.args[0]['x-engineio'])
        .take(1);

    new Future<void>.delayed(const Duration(seconds: 1), () => socket.open());

    expect(events$, emits(<String>['hi,foo']));
  });

  test('rememberWebsocket', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);

    socket.on(Socket.eventUpgrade).listen((Event event) {
      final Transport transport = event.args[0];
      socket.close();

      if (transport.name == WebSocket.NAME) {
        const SocketOptions opts = const SocketOptions(port: Connection.PORT, rememberUpgrade: true);

        final Socket socket2 = new Socket(opts);
        socket2.open();
        values.add(socket2.transport.name);
        socket2.close();
      }
    });

    socket.open();
    values.add(socket.transport.name);

    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(values[0], Polling.NAME);
    expect(values[1], WebSocket.NAME);
  });

  test('notRememberWebsocket', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket.on(Socket.eventUpgrade).listen((Event event) {
      final Transport transport = event.args[0];
      socket.close();

      if (transport.name == WebSocket.NAME) {
        const SocketOptions opts = const SocketOptions(port: Connection.PORT, rememberUpgrade: false);

        final Socket socket2 = new Socket(opts);
        socket2.open();
        values.add(socket2.transport.name);
        socket2.close();
      }
    });

    socket.open();
    values.add(socket.transport.name);

    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(values[0], Polling.NAME);
    expect(values[1], Polling.NAME);
  });
}
