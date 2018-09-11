import 'package:engine_io_client/src/engine_io/client/socket.dart';
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:test/test.dart';

void main() {
  test('properlyParseHttpUriWithoutPort', () {
    final SocketOptions opts = SocketOptions.fromUri(Uri.parse('http://localhost'));
    final Socket socket = Socket(opts);

    expect(socket.options.hostname, 'localhost');
    expect(socket.options.port, 80);
  });

  test('properlyParseHttpsUriWithoutPort', () {
    final SocketOptions opts = SocketOptions.fromUri(Uri.parse('https://localhost'));
    final Socket socket = Socket(opts);

    expect(socket.options.hostname, 'localhost');
    expect(socket.options.port, 443);
  });

  test('properlyParseWssUriWithoutPort', () {
    final SocketOptions opts = SocketOptions.fromUri(Uri.parse('wss://localhost'));
    final Socket socket = Socket(opts);

    expect(socket.options.hostname, 'localhost');
    expect(socket.options.port, 443);
  });

  test('properlyParseWssUriWithPort', () {
    final SocketOptions opts = SocketOptions.fromUri(Uri.parse('wss://localhost:2020'));
    final Socket socket = Socket(opts);

    expect(socket.options.hostname, 'localhost');
    expect(socket.options.port, 2020);
  });

  test('properlyParseHostWithPort', () {
    const SocketOptions opts = const SocketOptions(host: 'localhost', port: 8080);

    final Socket socket = Socket(opts);
    expect(socket.options.hostname, 'localhost');
    expect(socket.options.port, 8080);
  });

  test('properlyParseIPv6UriWithoutPort', () {
    final SocketOptions opts = SocketOptions.fromUri(Uri.parse('http://[::1]'));
    final Socket socket = Socket(opts);

    expect(socket.options.hostname, '::1');
    expect(socket.options.port, 80);
  });

  test('properlyParseIPv6UriWithPort', () {
    final SocketOptions opts = SocketOptions.fromUri(Uri.parse('http://[::1]:8080'));
    final Socket socket = Socket(opts);

    expect(socket.options.hostname, '::1');
    expect(socket.options.port, 8080);
  });

  test('properlyParseIPv6HostWithoutPort1', () {
    const SocketOptions opts = const SocketOptions(host: '[::1]');
    final Socket socket = Socket(opts);

    expect(socket.options.hostname, '::1');
    expect(socket.options.port, 80);
  });

  test('properlyParseIPv6HostWithoutPort2', () {
    const SocketOptions opts = const SocketOptions(host: '[::1]', secure: true);
    final Socket socket = Socket(opts);

    expect(socket.options.hostname, '::1');
    expect(socket.options.port, 443);
  });

  test('properlyParseIPv6HostWithPort', () {
    const SocketOptions opts = const SocketOptions(host: '[::1]', port: 8080);
    final Socket socket = Socket(opts);

    expect(socket.options.hostname, '::1');
    expect(socket.options.port, 8080);
  });

  test('properlyParseIPv6HostWithoutBrace', () {
    const SocketOptions opts = const SocketOptions(host: '[::1]');
    final Socket socket = Socket(opts);

    expect(socket.options.hostname, '::1');
    expect(socket.options.port, 80);
  });
}
