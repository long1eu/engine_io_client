import 'dart:async';
import 'dart:io' as io;

import 'package:built_collection/built_collection.dart';
import 'package:flutter_logger/flutter_logger.dart';
import 'package:socket_io/src/engine_io/client/engine_io_exception.dart';
import 'package:socket_io/src/engine_io/client/transport.dart';
import 'package:socket_io/src/engine_io/parser/parser.dart';
import 'package:socket_io/src/models/packet.dart';
import 'package:socket_io/src/models/ready_state.dart';
import 'package:socket_io/src/models/transport_event.dart';
import 'package:socket_io/src/models/transport_options.dart';
import 'package:socket_io/src/parse_qs/parse_qs.dart';
import 'package:socket_io/src/yeast/yeast.dart';

class WebSocket extends Transport {
  static final Log log = new Log('WebSocket');

  WebSocket(TransportOptions options) : super(options, 'WebSocket');

  io.WebSocket socket;

  @override
  void doOpen() async {
    final Map<String, List<String>> headers = <String, List<String>>{};
    emit(TransportEvent.requestHeaders.name, headers);

    log.d('uri: $uri');
    socket = await io.WebSocket.connect(uri);
    socket.listen(onMessage, onError: onSocketError, onDone: onClose);
    emit(TransportEvent.responseHeaders.name, null);
    onOpen();
  }

  void onMessage(dynamic event) {
    if (event == null) return;
    if (event is String || event is List<int>) {
      onData(event);
    } else
      throw new EngineIOException(name, '$event is not String nor List<int>.');
  }

  void onSocketError(Exception e) => onError('websocket error', e);

  @override
  void write(List<Packet<dynamic>> packets) {
    writable = false;

    int total = packets.length;
    for (Packet<dynamic> packet in packets) {
      if (readyState != ReadyState.opening && readyState != ReadyState.open) {
        // Ensure we don't try to send anymore packets if the socket ends up being closed due to an exception
        break;
      }

      Parser.encodePacket(packet, new EncodeCallback<dynamic>((dynamic data) {
        try {
          socket.add(data);
        } catch (e) {
          log.e('WebSocket closed before we could write.');
        }

        if (0 == --total) {
          Timer.run(() {
            writable = true;
            emit(TransportEvent.drain.name);
          });
        }
      }));
    }
  }

  @override
  void doClose() {
    socket?.close(1000, '');
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
