import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:socket_io_engine/src/engine_io/client/engine_io_exception.dart';
import 'package:socket_io_engine/src/engine_io/client/transport.dart';
import 'package:socket_io_engine/src/engine_io/parser/parser.dart';
import 'package:socket_io_engine/src/logger.dart';
import 'package:socket_io_engine/src/models/packet.dart';
import 'package:socket_io_engine/src/models/transport_event.dart';
import 'package:socket_io_engine/src/models/transport_options.dart';
import 'package:socket_io_engine/src/models/transport_state.dart';
import 'package:socket_io_engine/src/parse_qs/parse_qs.dart';
import 'package:socket_io_engine/src/yeast/yeast.dart';
import 'package:web_socket_channel/io.dart';

class WebSocket extends Transport {
  static const String NAME = 'websocket';
  static final Log log = new Log(NAME);

  WebSocket(TransportOptions options) : super(options, NAME);

  IOWebSocketChannel socket;

  @override
  Future<Null> doOpen() async {
    final Map<String, List<String>> headers = <String, List<String>>{};
    emit(TransportEvent.requestHeaders.name, headers);
    socket = new IOWebSocketChannel.connect(uri, headers: headers);
    socket.stream.listen(onMessage, onError: onSocketError, onDone: onClose);
    onOpen();
  }

  Future<Null> onMessage(dynamic event) async {
    log.d('onMessage: $event');
    if (event == null) return;
    if (event is String || event is List<int>) {
      await onData(event);
    } else
      throw new EngineIOException(name, '$event is not String nor List<int>.');
  }

  void onSocketError(Exception e) => onError('websocket error', e);

  @override
  Future<Null> write(List<Packet> packets) async {
    writable = false;

    int total = packets.length;
    for (Packet packet in packets) {
      if (readyState != TransportState.opening && readyState != TransportState.open) {
        // Ensure we don't try to send anymore packets if the socket ends up being closed due to an exception
        break;
      }

      final dynamic encoded = Parser.encodePacket(packet);
      try {
        socket.sink.add(encoded);
      } catch (e) {
        log.e('WebSocket closed before we could write.');
      }

      if (0 == --total) {
        writable = true;
        emit(TransportEvent.drain.name);
      }
    }
  }

  @override
  Future<Null> doClose() async {
    await socket?.sink?.close(1000, '');
    socket = null;
  }

  String get uri {
    final MapBuilder<String, String> query = options?.query?.toBuilder() ?? new MapBuilder<String, String>();
    final String schema = options.secure ? 'wss' : 'ws';

    String port = '';

    if (options.port > 0 && ((schema == 'wss' && options.port != 443) || (schema == 'ws' && options.port != 80))) {
      port = ':${options.port}';
    }

    if (options.timestampRequests) query[options.timestampParam] = Yeast.yeast();

    String derivedQuery = ParseQS.encode(query.build());
    if (derivedQuery.isNotEmpty) {
      derivedQuery = '?$derivedQuery';
    }

    final String hostname = options.hostname.contains(':') ? '[${options.hostname}]' : options.hostname;
    return '$schema://$hostname$port${options.path}$derivedQuery';
  }
}
