import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:engine_io_client/src/engine_io/client/transport.dart';
import 'package:engine_io_client/src/engine_io/parser/parser.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/packet.dart';
import 'package:engine_io_client/src/models/packet_type.dart';
import 'package:engine_io_client/src/models/polling_event.dart';
import 'package:engine_io_client/src/models/transport_event.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/models/transport_state.dart';
import 'package:engine_io_client/src/parse_qs/parse_qs.dart';
import 'package:engine_io_client/src/yeast/yeast.dart';

abstract class Polling extends Transport {
  static const String NAME = 'polling';
  static final Log log = new Log('EngineIo.Polling');

  Polling(TransportOptions options) : super(options, NAME);

  bool _polling;

  @override
  Future<Null> doOpen() async => await poll();

  Future<Null> pause(Future<Null> onPause()) async {
    readyState = TransportState.paused;

    Future<Null> pause() async {
      log.d('paused');
      readyState = TransportState.paused;
      await onPause();
    }

    if (_polling || !writable) {
      int total = 0;

      if (_polling) {
        log.d('we are currently polling - waiting to pause');
        total++;
        once(PollingEvent.pollComplete, (List<dynamic> args) async {
          log.d('pre-pause polling complete');
          if (--total == 0) await pause();
        });
      }

      if (!writable) {
        log.d('we are currently writing - waiting to pause');
        total++;
        once(TransportEvent.drain, (List<dynamic> args) async {
          log.d('pre-pause writing complete');
          if (--total == 0) await pause();
        });
      }
    } else {
      await pause();
    }
  }

  Future<Null> poll() async {
    log.d('polling');
    _polling = true;
    await doPoll();
    await emit(PollingEvent.poll);
  }

  @override
  Future<Null> onData(dynamic data) => _onData(data);

  Future<Null> _onData(dynamic data) async {
    log.i('polling got data:${data.runtimeType} $data ');

    final List<Packet> packets = data is String ? Parser.decodePayload(data) : Parser.decodeBinaryPayload(data);
    for (Packet packet in packets) {
      if (readyState == TransportState.opening) await onOpen();
      if (packet.type == PacketType.close) await onClose();
      await onPacket(packet);
    }

    if (readyState != TransportState.closed) {
      _polling = false;
      await emit(PollingEvent.pollComplete);

      if (readyState == TransportState.open) {
        await poll();
      } else {
        log.i('ignoring poll - transport state "$readyState"');
      }
    }
  }

  @override
  Future<Null> doClose() async {
    Future<Null> close() async {
      log.d('writing close packet');
      try {
        await write(<Packet>[new Packet.values(PacketType.close)]);
      } catch (err) {
        throw new Exception(err);
      }
    }

    if (readyState == TransportState.open) {
      log.d('transport open - closing');
      await close();
    } else {
      // in case we're trying to close while
      // handshaking is in progress (engine.io-client GH-164)
      log.d('transport not open - deferring close');
      once(TransportEvent.open, (List<dynamic> args) async => await close());
    }
  }

  @override
  Future<Null> write(List<Packet> packets) async {
    writable = false;
    Future<Null> callback() async {
      writable = true;
      await emit(TransportEvent.drain);
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
