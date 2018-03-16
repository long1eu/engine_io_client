import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:socket_io_engine/src/engine_io/client/transport.dart';
import 'package:socket_io_engine/src/engine_io/parser/parser.dart';
import 'package:socket_io_engine/src/logger.dart';
import 'package:socket_io_engine/src/models/packet.dart';
import 'package:socket_io_engine/src/models/packet_type.dart';
import 'package:socket_io_engine/src/models/polling_event.dart';
import 'package:socket_io_engine/src/models/transport_event.dart';
import 'package:socket_io_engine/src/models/transport_options.dart';
import 'package:socket_io_engine/src/models/transport_state.dart';
import 'package:socket_io_engine/src/parse_qs/parse_qs.dart';
import 'package:socket_io_engine/src/yeast/yeast.dart';

abstract class Polling extends Transport {
  static const String NAME = 'polling';
  static final Log log = new Log(NAME);

  Polling(TransportOptions options) : super(options, NAME);

  bool _polling;

  @override
  Future<Null> doOpen() async => await poll();

  void pause(void onPause()) {
    readyState = TransportState.paused;

    void pause() {
      log.d('paused');
      readyState = TransportState.paused;
      onPause();
    }

    if (_polling || !writable) {
      int total = 0;

      if (_polling) {
        log.d('we are currently polling - waiting to pause');
        total++;
        once(PollingEvent.pollComplete.name, (dynamic args) {
          log.d('pre-pause polling complete');
          if (--total == 0) pause();
        });
      }

      if (!writable) {
        log.d('we are currently writing - waiting to pause');
        total++;
        once(TransportEvent.drain.name, (dynamic args) {
          log.d('pre-pause writing complete');
          if (--total == 0) pause();
        });
      }
    } else {
      pause();
    }
  }

  Future<Null> poll() async {
    log.d('polling');
    _polling = true;
    await doPoll();
    emit(PollingEvent.poll.name);
  }

  @override
  Future<Null> onData(dynamic data) => _onData(data);

  Future<Null> _onData(dynamic data) async {
    log.i('polling got data $data ');

    final List<Packet> packets = data is String ? Parser.decodePayload(data) : Parser.decodeBinaryPayload(data);
    for (Packet packet in packets) {
      if (readyState == TransportState.opening) onOpen();
      if (packet.type == PacketType.close) onClose();
      onPacket(packet);
    }

    if (readyState != TransportState.closed) {
      _polling = false;
      emit(PollingEvent.pollComplete.name);

      if (readyState == TransportState.open) {
        await poll();
      } else {
        log.i('ignoring poll - transport state "$readyState"');
      }
    }
  }

  @override
  Future<Null> doClose() async {
    void close(dynamic args) {
      log.d('writing close packet');
      try {
        write(<Packet>[new Packet.values(PacketType.close)]);
      } catch (err) {
        throw new Exception(err);
      }
    }

    if (readyState == TransportState.open) {
      log.d('transport open - closing');
      close(null);
    } else {
      // in case we're trying to close while
      // handshaking is in progress (engine.io-client GH-164)
      log.d('transport not open - deferring close');
      once(TransportEvent.open.name, close);
    }
  }

  @override
  Future<Null> write(List<Packet> packets) async {
    writable = false;
    void callback() {
      writable = true;
      emit(TransportEvent.drain.name);
    }

    final dynamic encoded = Parser.encodePayload(packets);

    if (encoded is List<int> || encoded is String) {
      await doWrite(encoded, callback);
    } else {
      log.w('Unexpected data: $encoded');
    }
  }

  String get uri {
    final MapBuilder<String, String> query = options?.query?.toBuilder() ?? new MapBuilder<String, String>();
    final String schema = options.secure ? 'https' : 'http';

    String port = '';
    if (options.port > 0 && ((schema == 'https' && options.port != 443) || (schema == 'http' && options.port != 80))) {
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

  Future<Null> doWrite(dynamic data, void callback());

  Future<Null> doPoll();
}
