import 'dart:io' as io;

import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/engine_io/client/transport.dart';
import 'package:engine_io_client/src/engine_io/parser/parser.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/packet.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/parse_qs/parse_qs.dart';
import 'package:engine_io_client/src/yeast/yeast.dart';
import 'package:rxdart/rxdart.dart';

class WebSocket extends Transport {
  static const String NAME = 'websocket';
  static final Log log = new Log('EngineIo.WebSocket');

  WebSocket(TransportOptions options) : super(options, NAME);

  io.WebSocket socket;

  @override
  Observable<Event> get doOpen$ => new Observable<Map<String, List<String>>>.just(<String, List<String>>{})
      .doOnData((Map<String, List<String>> headers) => emit(Transport.eventRequestHeaders, <Map<String, List<String>>>[headers]))
      .delay(const Duration(milliseconds: 2))
      .flatMap((Map<String, List<String>> h) => new Observable<io.WebSocket>.fromFuture(io.WebSocket.connect(uri, headers: h)))
      .doOnData((io.WebSocket socket) => this.socket = socket)
      .flatMap<Event>((io.WebSocket socket) => new Observable<Event>.merge(<Observable<Event>>[
            onOpen$,
            new Observable<dynamic>(socket)
                .where((dynamic event) => event != null)
                .doOnData((dynamic event) => log.d('onMessage: $event'))
                .flatMap((dynamic event) => onData(event))
                .doOnError((dynamic e) => onError('websocket error', e))
                .doOnDone(() => onClose$.listen(null)),
          ]));

  //.where((Event event) => event.name == Transport.eventOpen);

  @override
  Observable<void> get doClose$ => new Observable<Null>.fromFuture(socket?.close(1000, '')).map((Null _) => socket = null);

  @override
  Observable<Event> write(List<Packet<dynamic>> packets) => new Observable<Packet<dynamic>>.fromIterable(packets)
      .where((Packet<dynamic> _) => readyState != Transport.stateOpening && readyState != Transport.stateOpen)
      .map<dynamic>((Packet<dynamic> packet) => Parser.encodePacket(packet))
      .forEach((dynamic encoded) => socket.add(encoded))
      .asObservable();

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
