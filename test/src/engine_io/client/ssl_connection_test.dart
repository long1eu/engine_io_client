import 'dart:async';
import 'dart:io' hide Socket;

import 'package:engine_io_client/engine_io_client.dart';
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() {
  final Log log = Log('ssl_connection');

  test('receiveBinaryData_PollingSSL', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> binaryData = <int>[]..length = 5;
    for (int i = 0; i < binaryData.length; i++) {
      binaryData[i] = i;
    }

    final String certFile = '${Directory.current.path.toString()}/test/resources/test.crt';
    final SecurityContext context = SecurityContext()..setTrustedCertificates(certFile);
    final SocketOptions opts = SocketOptions(
      port: Connection.PORT,
      transports: const <String>[Polling.NAME],
      secure: true,
      securityContext: context,
    );

    final Socket socket = Socket(opts);
    socket.on(SocketEvent.open, (List<dynamic> args) async {
      log.e('open');
      socket.on(SocketEvent.message, (List<dynamic> args) {
        log.e('args: $args');
        if (args[0] == 'hi') return;
        values.add(args[0]);
      });
      await socket.send(binaryData);
    });
    socket.open();
    await Future<void>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(values[0], binaryData);
    socket.close();
  });

  test('receiveBinaryDataAndMultibyteUTF8String_PollingSSL', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> binaryData = List<int>.generate(5, (_) => 0);
    for (int i = 0; i < binaryData.length; i++) binaryData[i] = i;

    final String certFile = '${Directory.current.path.toString()}/test/resources/test.crt';
    final SecurityContext context = SecurityContext()..setTrustedCertificates(certFile);

    final SocketOptions opts = SocketOptions(
      port: Connection.PORT,
      transports: const <String>[Polling.NAME],
      secure: true,
      securityContext: context,
    );

    final Socket socket = Socket(opts);
    socket.on(SocketEvent.open, (List<dynamic> args) async {
      log.d('open');
      socket.on(SocketEvent.message, (List<dynamic> args) {
        log.d('args: $args');
        if (args[0] == 'hi') return;
        values.add(args[0]);
      });

      await socket.send(binaryData);
      await socket.send('cash money €€€');
      await socket.send('cash money ss €€€');
      await socket.send('20["getAckBinary",""]');
    });
    socket.open();
    await Future<void>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    log.d(values.toString());
    expect(values[0], binaryData);
    expect(values[1], 'cash money €€€');
    expect(values[2], 'cash money ss €€€');
    expect(values[3], '20["getAckBinary",""]');
    socket.close();
  });

  test('receiveBinaryData_WebSocketSSL', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> binaryData = <int>[]..length = 5;
    for (int i = 0; i < binaryData.length; i++) {
      binaryData[i] = i;
    }

    final String certFile = '${Directory.current.path.toString()}/test/resources/test.crt';
    final SecurityContext context = SecurityContext()..setTrustedCertificates(certFile);

    final SocketOptions opts = SocketOptions(
      port: Connection.PORT,
      secure: true,
      securityContext: context,
    );

    HttpOverrides.runZoned(() async {
      final Socket socket = Socket(opts);
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
    }, createHttpClient: (_) {
      return HttpClient(context: context);
    });
  });

  test('receiveBinaryDataAndMultibyteUTF8String_WebSocketSSL', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> binaryData = List<int>.generate(5, (_) => 0);
    for (int i = 0; i < binaryData.length; i++) binaryData[0] = i;

    final String certFile = '${Directory.current.path.toString()}/test/resources/test.crt';
    final SecurityContext context = SecurityContext()..setTrustedCertificates(certFile);

    final SocketOptions opts = SocketOptions(
      port: Connection.PORT,
      secure: true,
      securityContext: context,
    );

    HttpOverrides.runZoned(() async {
      final Socket socket = Socket(opts);
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
    }, createHttpClient: (_) {
      return HttpClient(context: context);
    });
  });
}
