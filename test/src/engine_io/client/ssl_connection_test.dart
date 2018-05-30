import 'dart:io' hide Socket, WebSocket;

import 'package:engine_io_client/engine_io_client.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  //final Log log = new Log('ssl_connection');

  test('receiveBinaryData_PollingSSL', () async {
    final List<int> binaryData = new List<int>.generate(5, (int i) => i);

    final String certFile = '${Directory.current.path.toString()}/test/resources/test.crt';
    final SecurityContext context = new SecurityContext()..setTrustedCertificates(certFile);
    final SocketOptions opts = new SocketOptions(
      port: 3001,
      transports: <String>[Polling.NAME],
      secure: true,
      securityContext: context,
    );

    final Socket socket = new Socket(opts);

    final Observable<Event> events$ =
        socket.on(Socket.eventMessage).where((Event event) => event.args[0] != 'hi').map((Event event) => event.args[0]);
    socket.send(binaryData);
    socket.open();

    expect(events$, emits(binaryData));
  });

  test('receiveBinaryDataAndMultibyteUTF8String_PollingSSL', () async {
    final List<int> binaryData = new List<int>.generate(5, (int i) => i);

    final String certFile = '${Directory.current.path.toString()}/test/resources/test.crt';
    final SecurityContext context = new SecurityContext()..setTrustedCertificates(certFile);
    final SocketOptions opts = new SocketOptions(
      port: 3001,
      transports: <String>[Polling.NAME],
      secure: true,
      securityContext: context,
    );

    final Socket socket = new Socket(opts);
    final Observable<Event> onMessage$ = socket.on(Socket.eventMessage).map<Event>((Event event) => event.args[0]).take(2);
    socket.on(Socket.eventOpen).listen((Event event) => socket.send(binaryData));
    socket.open();

    expect(onMessage$, emitsInOrder(<dynamic>['hi', binaryData, emitsDone]));
  });

  test('receiveBinaryData_WebSocketSSL', () async {
    final List<int> binaryData = new List<int>.generate(5, (int i) => i);

    final String certFile = '${Directory.current.path.toString()}/test/resources/test.crt';
    final SecurityContext context = new SecurityContext()..setTrustedCertificates(certFile);
    final SocketOptions opts = new SocketOptions(
      port: 3001,
      transports: <String>[WebSocket.NAME],
      secure: true,
      securityContext: context,
    );

    final Socket socket = new Socket(opts);
    final Observable<Event> onMessage$ = socket.on(Socket.eventMessage).map<dynamic>((Event event) => event.args[0]).take(2);
    socket.on(Socket.eventOpen).listen((Event event) => socket.send(binaryData));
    socket.open();

    expect(onMessage$, emitsInOrder(<dynamic>['hi', binaryData, emitsDone]));
  });

  test('receiveBinaryDataAndMultibyteUTF8String_WebSocketSSL', () async {
    final List<int> binaryData = new List<int>.generate(5, (int i) => i);

    final String certFile = '${Directory.current.path.toString()}/test/resources/test.crt';
    final SecurityContext context = new SecurityContext()..setTrustedCertificates(certFile);
    final SocketOptions opts = new SocketOptions(
      port: 3001,
      transports: <String>[WebSocket.NAME],
      secure: true,
      securityContext: context,
    );

    final Socket socket = new Socket(opts);
    final Observable<Event> onMessage$ = socket
        .on(Socket.eventMessage)
        .where((Event event) => event.args[0] != 'hi')
        .map<dynamic>((Event event) => event.args[0])
        .take(4);

    socket.on(Socket.eventOpen).listen((Event event) {
      socket.send(binaryData);
      socket.send('cash money €€€');
      socket.send('cash money ss €€€');
      socket.send('20["getAckBinary",""]');
    });

    socket.open();

    expect(
        onMessage$,
        emitsInOrder(<dynamic>[
          binaryData,
          'cash money €€€',
          'cash money ss €€€',
          '20["getAckBinary",""]',
          emitsDone,
        ]));
  });
}
