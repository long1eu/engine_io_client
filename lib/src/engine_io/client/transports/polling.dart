import 'package:built_collection/built_collection.dart';
import 'package:flutter_logger/flutter_logger.dart';
import 'package:socket_io/src/emitter/emitter.dart';
import 'package:socket_io/src/engine_io/client/transport.dart';
import 'package:socket_io/src/engine_io/parser/parser.dart';
import 'package:socket_io/src/models/packet.dart';
import 'package:socket_io/src/models/packet_type.dart';
import 'package:socket_io/src/models/polling_event.dart';
import 'package:socket_io/src/models/ready_state.dart';
import 'package:socket_io/src/models/transport_event.dart';
import 'package:socket_io/src/models/transport_options.dart';
import 'package:socket_io/src/parse_qs/parse_qs.dart';
import 'package:socket_io/src/yeast/yeast.dart';

abstract class Polling extends Transport {
  static final Log log = new Log('Polling');

  Polling(TransportOptions options) : super(options, 'Polling');

  bool _polling;

  @override
  void doOpen() {
    poll();
  }

  void pause(void onPause()) {
    readyState = ReadyState.paused;

    void pause() {
      log.d('paused');
      readyState = ReadyState.paused;
      onPause();
    }

    if (_polling || !writable) {
      int total = 0;

      if (_polling) {
        log.d('we are currently polling - waiting to pause');
        total++;
        once(PollingEvent.pollComplete.name, new Listener.callback((dynamic args) {
          log.d('pre-pause polling complete');
          if (--total == 0) {
            pause();
          }
        }));
      }

      if (!writable) {
        log.d('we are currently writing - waiting to pause');
        total++;
        once(TransportEvent.drain.name, new Listener.callback((dynamic args) {
          log.d('pre-pause writing complete');
          if (--total == 0) {
            pause();
          }
        }));
      }
    } else {
      pause();
    }
  }

  void poll() {
    log.d('polling');
    _polling = true;
    doPoll();
    emit(PollingEvent.poll.name);
  }

  @override
  void onData(dynamic data) => _onData(data);

  void _onData(dynamic data) {
    log.i('polling got data $data');

    final DecodePayloadCallback<dynamic> callback =
        new DecodePayloadCallback<dynamic>((Packet<dynamic> packet, int index, int total) {
      if (readyState == ReadyState.open) {
        onOpen();
      }

      if (packet.type == PacketType.close) {
        onClose();
        return false;
      }

      onPacket(packet);
      return true;
    });

    if (data is String) {
      Parser.decodePayload(data, callback);
    } else if (data is List<int>) {
      Parser.decodeBinaryPayload(data, callback);
    }

    if (readyState != ReadyState.closed) {
      _polling = false;
      emit(PollingEvent.pollComplete.name);

      if (readyState == ReadyState.open) {
        poll();
      } else {
        log.i('ignoring poll - transport state "$readyState"');
      }
    }
  }

  @override
  void doClose() {
    final Polling self = this;

    final Listener close = new Listener.callback((dynamic args) {
      log.d('writing close packet');
      try {
        self.write(<Packet<dynamic>>[new Packet<dynamic>.values(PacketType.close)]);
      } catch (err) {
        throw new Exception(err);
      }
    });

    if (readyState == ReadyState.open) {
      log.d('transport open - closing');
      close.call();
    } else {
      // in case we're trying to close while
      // handshaking is in progress (engine.io-client GH-164)
      log.d('transport not open - deferring close');
      once(TransportEvent.open.name, close);
    }
  }

  @override
  void write(List<Packet<dynamic>> packets) {
    writable = false;
    void callback() {
      writable = true;
      emit(TransportEvent.drain.name);
    }

    Parser.encodePayload(packets, new EncodeCallback<dynamic>((dynamic data) {
      if (data is List<int> || data is String) {
        doWrite(data, callback);
      } else {
        log.w('Unexpected data: $data');
      }
    }));
  }

  String get uri {
    BuiltMap<String, String> query = options.query ?? new BuiltMap<String, String>();
    final String schema = options.secure ? 'https' : 'http';

    String port = '';
    if (options.port > 0 && ((schema == 'https' && options.port != 443) || (schema == 'http' && options.port != 80))) {
      port = ':${options.port}';
    }

    if (options.timestampRequests) {
      query = (query.toBuilder()..putIfAbsent(options.timestampParam, () => Yeast.yeast())).build();
    }

    String derivedQuery = ParseQS.encode(query);
    if (derivedQuery.isNotEmpty) {
      derivedQuery = '?$derivedQuery';
    }

    final String hostname = options.hostname.contains(':') ? '[${options.hostname}]' : options.hostname;

    return '$schema://$hostname$port${options.path}$derivedQuery';
  }

  void doWrite(dynamic data, void callback());

  void doPoll();
}
