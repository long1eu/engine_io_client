library transport;

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';

import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/engine_io/client/engine_io_error.dart';
import 'package:engine_io_client/src/engine_io/custom/websocket_impl.dart';
import 'package:engine_io_client/src/engine_io/parser/parser.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/packet.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/models/xhr_options.dart';
import 'package:engine_io_client/src/parse_qs/parse_qs.dart';
import 'package:engine_io_client/src/yeast/yeast.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

part 'transports/polling.dart';
part 'transports/web_socket.dart';
part 'transports/xhr/polling_xhr.dart';
part 'transports/xhr/request_xhr.dart';

abstract class Transport extends Emitter {
  static final Log log = new Log('EngineIo.Transport');

  static const String eventOpen = 'open';
  static const String eventClose = 'close';
  static const String eventPacket = 'packet';
  static const String eventDrain = 'drain';
  static const String eventError = 'error';
  static const String eventResponseHeaders = 'responseHeaders';
  static const String eventCanClose = 'canClose';
  static const String eventPaused = 'paused';

  static const String stateOpening = 'opening';
  static const String stateOpen = 'open';
  static const String stateClosed = 'closed';
  static const String statePaused = 'paused';

  Transport(this.options, this.name);

  final String name;

  TransportOptions options;
  String readyState;
  bool writable = false;

  void _doOpen();

  Observable<Event> _doClose();

  Observable<Event> _write(List<Packet> packets);

  void open() {
    if (readyState == Transport.stateClosed || readyState == null) {
      readyState = Transport.stateOpening;
      _doOpen();
    }
  }

  void close(String caller) {
    log.d('caller: $caller');
    if (readyState == Transport.stateOpening || readyState == Transport.stateOpen) {
      _doClose().listen((Event event) => _onClose());
    }
  }

  Observable<Event> send(List<Packet> packets) {
    if (readyState == Transport.stateOpen) {
      writable = false;
      return _write(packets).doOnData((Event event) => writable = true).doOnData((Event event) => emit(Transport.eventDrain));
    } else {
      throw new StateError('Transport not open');
    }
  }

  void canClose() {
    if (!writable) {
      log.d('we are currently writing - waiting to pause');
      once(Transport.eventDrain).listen((Event event) => emit(Transport.eventCanClose));
    } else {
      emit(Transport.eventCanClose);
    }
  }

  void _onOpen() {
    log.d('onOpen');
    readyState = Transport.stateOpen;
    writable = true;
    emit(Transport.eventOpen);
    log.d('emit open');
  }

  void _onClose() {
    readyState = Transport.stateClosed;
    emit(Transport.eventClose);
  }

  @visibleForTesting
  void onError(String message, dynamic desc) {
    emit(Transport.eventError, <Error>[new EngineIOError(message, desc)]);
  }

  void _onData(dynamic data) {
    log.e('transport opened $data');
    final Packet packet = data is String ? Parser.decodePacket(data) : Parser.decodeBytePacket(data);
    _onPacket(packet);
  }

  void _onPacket(Packet packet) {
    emit(Transport.eventPacket, <Packet>[packet]);
  }

  @override
  String toString() {
    return (new ToStringHelper(name)..add('options', '$options')..add('readyState', '$readyState')..add('writable', '$writable'))
        .toString();
  }
}
