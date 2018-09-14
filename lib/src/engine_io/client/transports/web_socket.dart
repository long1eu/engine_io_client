import 'dart:async';

import 'package:engine_io_client/src/engine_io/client/engine_io_error.dart';
import 'package:engine_io_client/src/engine_io/client/transport.dart';
import 'package:engine_io_client/src/engine_io/parser/parser.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/packet.dart';
import 'package:engine_io_client/src/models/transport_event.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/models/transport_state.dart';
import 'package:engine_io_client/src/parse_qs/parse_qs.dart';
import 'package:engine_io_client/src/yeast/yeast.dart';
import 'package:web_socket_channel/io.dart';

class WebSocket extends Transport {
  static const String NAME = 'websocket';
  static final Log log = Log('EngineIo.WebSocket');

  WebSocket(TransportOptions options) : super(options, NAME);

  IOWebSocketChannel socket;

  @override
  Future<void> doOpen() async {
    final Map<String, String> headers = options.onRequestHeaders?.call(<String, String>{}) ?? <String, String>{};
    socket = IOWebSocketChannel.connect(uri, headers: headers);
    socket.stream.listen(onMessage, onError: onSocketError, onDone: onClose);
    await onOpen();
  }

  Future<void> onMessage(dynamic event) async {
    log.d('onMessage: $event');
    if (event == null) return;
    if (event is String || event is List<int>) {
      await onData(event);
    } else
      throw EngineIOError(name, '$event is not String nor List<int>.');
  }

  void onSocketError(dynamic e, StackTrace s) async => await onError('websocket error', e);

  @override
  Future<void> write<T>(List<Packet<T>> packets) async {
    writable = false;

    int total = packets.length;
    for (Packet<T> packet in packets) {
      if (readyState != TransportState.opening && readyState != TransportState.open) {
        // Ensure we don't try to send anymore packets if the socket ends up being closed due to an exception
        break;
      }

      final T encoded = Parser.encodePacket<T>(packet);
      try {
        socket.sink.add(encoded);
      } catch (e) {
        log.e('WebSocket closed before we could write.');
      }

      if (0 == --total) {
        writable = true;
        await emit(TransportEvent.drain);
      }
    }
  }

  @override
  Future<void> doClose() async {
    await socket?.sink?.close(1000, '');
    socket = null;
  }

  String get uri {
    final Map<String, String> query = options?.query ?? <String, String>{};
    final String schema = options.secure ? 'wss' : 'ws';

    String port = '';

    if (options.port > 0 && ((schema == 'wss' && options.port != 443) || (schema == 'ws' && options.port != 80))) {
      port = ':${options.port}';
    }

    if (options.timestampRequests) query[options.timestampParam] = Yeast.yeast();

    String derivedQuery = ParseQS.encode(query);
    if (derivedQuery.isNotEmpty) {
      derivedQuery = '?$derivedQuery';
    }

    final String hostname = options.hostname.contains(':') ? '[${options.hostname}]' : options.hostname;
    return '$schema://$hostname$port${options.path}$derivedQuery';
  }
}
