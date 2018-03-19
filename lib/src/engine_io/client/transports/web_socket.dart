import 'dart:async';
import 'dart:io' as io;

import 'package:built_collection/built_collection.dart';
import 'package:engine_io_client/src/engine_io/client/engine_io_exception.dart';
import 'package:engine_io_client/src/engine_io/client/transport.dart';
import 'package:engine_io_client/src/engine_io/parser/parser.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/packet.dart';
import 'package:engine_io_client/src/models/transport_event.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/models/transport_state.dart';
import 'package:engine_io_client/src/parse_qs/parse_qs.dart';
import 'package:engine_io_client/src/yeast/yeast.dart';

class WebSocket extends Transport {
  static const String NAME = 'websocket';
  static final Log log = new Log('EngineIo.WebSocket');

  WebSocket(TransportOptions options) : super(options, NAME);

  io.WebSocket socket;

  @override
  Future<Null> doOpen() async {
    final Map<String, List<String>> headers = <String, List<String>>{};
    await emit(TransportEvent.requestHeaders, <Map<String, List<String>>>[headers]);

    await io.HttpOverrides.runZoned<Future<Null>>(
      () async {
        socket = await io.WebSocket.connect(uri, headers: headers);
      },
      createHttpClient: (io.SecurityContext securityContext) {
        return new io.HttpClient(context: options.securityContext);
      },
    );
    socket.listen(onMessage, onError: onSocketError, onDone: onClose);
    await onOpen();
  }

  Future<Null> onMessage(dynamic event) async {
    log.d('onMessage: $event');
    if (event == null) return;
    if (event is String || event is List<int>) {
      await onData(event);
    } else
      throw new EngineIOException(name, '$event is not String nor List<int>.');
  }

  void onSocketError(Exception e) async => await onError('websocket error', e);

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
        socket.add(encoded);
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
  Future<Null> doClose() async {
    await socket?.close(1000, '');
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
