import 'package:engine_io_client/src/engine_io/client/transports/web_socket.dart';
import 'package:engine_io_client/src/engine_io/client/transports/xhr/polling_xhr.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:test/test.dart';

void main() {
  test('uri', () {
    const TransportOptions options = const TransportOptions(
        path: '/engine.io',
        hostname: 'localhost',
        secure: false,
        query: <String, String>{'sid': 'test'},
        timestampRequests: false);

    final PollingXhr polling = PollingXhr(options);

    expect(polling.uri, 'http://localhost/engine.io?sid=test');
  });

  test('uriWithDefaultPort', () {
    const TransportOptions options = const TransportOptions(
        path: '/engine.io',
        hostname: 'localhost',
        secure: false,
        query: <String, String>{'sid': 'test'},
        port: 80,
        timestampRequests: false);

    final PollingXhr polling = PollingXhr(options);

    expect(polling.uri, 'http://localhost/engine.io?sid=test');
  });

  test('uriWithPort', () {
    const TransportOptions options = const TransportOptions(
        path: '/engine.io',
        hostname: 'localhost',
        secure: false,
        query: <String, String>{'sid': 'test'},
        port: 3000,
        timestampRequests: false);

    final PollingXhr polling = PollingXhr(options);

    expect(polling.uri, 'http://localhost:3000/engine.io?sid=test');
  });

  test('httpsUriWithDefaultPort', () {
    const TransportOptions options = const TransportOptions(
        path: '/engine.io',
        hostname: 'localhost',
        secure: true,
        query: <String, String>{'sid': 'test'},
        port: 443,
        timestampRequests: false);

    final PollingXhr polling = PollingXhr(options);

    expect(polling.uri, 'https://localhost/engine.io?sid=test');
  });

  test('timestampedUri', () {
    const TransportOptions options =
        const TransportOptions(path: '/engine.io', hostname: 'localhost', timestampParam: 't', timestampRequests: true);

    final PollingXhr polling = PollingXhr(options);
    expect(RegExp('http://localhost/engine.io\\?(j=[0-9]+&)?t=[0-9A-Za-z-_.]+').hasMatch(polling.uri), isTrue);
  });

  test('ipv6Uri', () {
    const TransportOptions options =
        const TransportOptions(path: '/engine.io', hostname: '::1', secure: false, port: 80, timestampRequests: false);

    final PollingXhr polling = PollingXhr(options);
    expect(polling.uri, 'http://[::1]/engine.io');
  });

  test('ipv6UriWithPort', () {
    const TransportOptions options =
        const TransportOptions(path: '/engine.io', hostname: '::1', secure: false, port: 8080, timestampRequests: false);

    final PollingXhr polling = PollingXhr(options);
    expect(polling.uri, 'http://[::1]:8080/engine.io');
  });

  test('wsUri', () {
    const TransportOptions options = const TransportOptions(
        path: '/engine.io',
        hostname: 'test',
        secure: false,
        query: <String, String>{'transport': 'WebSocket'},
        timestampRequests: false);

    final WebSocket ws = WebSocket(options);
    expect(ws.uri, 'ws://test/engine.io?transport=WebSocket');
  });

  test('wssUri', () {
    const TransportOptions options =
        const TransportOptions(path: '/engine.io', hostname: 'test', secure: true, timestampRequests: false);

    final WebSocket ws = WebSocket(options);
    expect(ws.uri, 'wss://test/engine.io');
  });

  test('wsTimestampedUri', () {
    const TransportOptions options =
        const TransportOptions(path: '/engine.io', hostname: 'localhost', timestampParam: 'woot', timestampRequests: true);

    final WebSocket ws = WebSocket(options);
    expect(RegExp('ws://localhost/engine.io\\?woot=[0-9A-Za-z-_.]+').hasMatch(ws.uri), isTrue);
  });

  test('wsIPv6Uri', () {
    const TransportOptions options =
        const TransportOptions(path: '/engine.io', hostname: '::1', secure: false, port: 80, timestampRequests: false);

    final WebSocket ws = WebSocket(options);
    expect(ws.uri, 'ws://[::1]/engine.io');
  });

  test('ipv6UriWithPort', () {
    const TransportOptions options =
        const TransportOptions(path: '/engine.io', hostname: '::1', secure: false, port: 8080, timestampRequests: false);

    final WebSocket ws = WebSocket(options);
    expect(ws.uri, 'ws://[::1]:8080/engine.io');
  });
}
