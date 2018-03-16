import 'package:built_collection/built_collection.dart';
import 'package:engine_io_client/src/engine_io/client/socket.dart';
import 'package:engine_io_client/src/engine_io/client/transports/polling.dart';
import 'package:engine_io_client/src/engine_io/client/transports/web_socket.dart';
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:test/test.dart';

void main() {
  test('filterUpgrades', () {
    final SocketOptions opts = new SocketOptions((SocketOptionsBuilder b) {
      b..transports = new ListBuilder<String>(<String>[Polling.NAME]);
    });

    final Socket socket = new Socket(opts);
    final List<String> upgrades = <String>[Polling.NAME, WebSocket.NAME];

    final List<String> expected = <String>[Polling.NAME];
    expect(socket.filterUpgrades(new BuiltList<String>(upgrades)), expected);
  });

  test('properlyParseHttpUriWithoutPort', () {
    final SocketOptions opts = new SocketOptions.fromUri(Uri.parse('http://localhost'));
    final Socket socket = new Socket(opts);

    expect(socket.options.hostname, 'localhost');
    expect(socket.options.port, 80);
  });

  test('properlyParseHttpsUriWithoutPort', () {
    final SocketOptions opts = new SocketOptions.fromUri(Uri.parse('https://localhost'));
    final Socket socket = new Socket(opts);

    expect(socket.options.hostname, 'localhost');
    expect(socket.options.port, 443);
  });

  test('properlyParseWssUriWithoutPort', () {
    final SocketOptions opts = new SocketOptions.fromUri(Uri.parse('wss://localhost'));
    final Socket socket = new Socket(opts);

    expect(socket.options.hostname, 'localhost');
    expect(socket.options.port, 443);
  });

  test('properlyParseWssUriWithPort', () {
    final SocketOptions opts = new SocketOptions.fromUri(Uri.parse('wss://localhost:2020'));
    final Socket socket = new Socket(opts);

    expect(socket.options.hostname, 'localhost');
    expect(socket.options.port, 2020);
  });

  test('properlyParseHostWithPort', () {
    final SocketOptions opts = new SocketOptions((SocketOptionsBuilder b) {
      b
        ..host = 'localhost'
        ..port = 8080;
    });

    final Socket socket = new Socket(opts);
    expect(socket.options.hostname, 'localhost');
    expect(socket.options.port, 8080);
  });

  test('properlyParseIPv6UriWithoutPort', () {
    final SocketOptions opts = new SocketOptions.fromUri(Uri.parse('http://[::1]'));
    final Socket socket = new Socket(opts);

    expect(socket.options.hostname, '::1');
    expect(socket.options.port, 80);
  });

  test('properlyParseIPv6UriWithPort', () {
    final SocketOptions opts = new SocketOptions.fromUri(Uri.parse('http://[::1]:8080'));
    final Socket socket = new Socket(opts);

    expect(socket.options.hostname, '::1');
    expect(socket.options.port, 8080);
  });

  test('properlyParseIPv6HostWithoutPort1', () {
    final SocketOptions opts = new SocketOptions((SocketOptionsBuilder b) {
      b..host = '[::1]';
    });
    final Socket socket = new Socket(opts);

    expect(socket.options.hostname, '::1');
    expect(socket.options.port, 80);
  });

  test('properlyParseIPv6HostWithoutPort2', () {
    final SocketOptions opts = new SocketOptions((SocketOptionsBuilder b) {
      b
        ..host = '[::1]'
        ..secure = true;
    });
    final Socket socket = new Socket(opts);

    expect(socket.options.hostname, '::1');
    expect(socket.options.port, 443);
  });

  test('properlyParseIPv6HostWithPort', () {
    final SocketOptions opts = new SocketOptions((SocketOptionsBuilder b) {
      b
        ..host = '[::1]'
        ..port = 8080;
    });
    final Socket socket = new Socket(opts);

    expect(socket.options.hostname, '::1');
    expect(socket.options.port, 8080);
  });

  test('properlyParseIPv6HostWithoutBrace', () {
    final SocketOptions opts = new SocketOptions((SocketOptionsBuilder b) {
      b
        ..host = '::1';
    });
    final Socket socket = new Socket(opts);

    expect(socket.options.hostname, '::1');
    expect(socket.options.port, 80);
  });
}
