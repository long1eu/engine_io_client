import 'dart:async';

import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/engine_io/client/engine_io_exception.dart';
import 'package:engine_io_client/src/engine_io/parser/parser.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/packet.dart';
import 'package:engine_io_client/src/models/transport_options.dart';

abstract class Transport extends Emitter {
  static final Log log = new Log('EngineIo.Transport');

  static const String eventOpen = 'open';
  static const String eventClose = 'close';
  static const String eventPacket = 'packet';
  static const String eventDrain = 'drain';
  static const String eventError = 'error';
  static const String eventRequestHeaders = 'requestHeaders';
  static const String eventResponseHeaders = 'responseHeaders';

  static const String stateOpening = 'opening';
  static const String stateOpen = 'open';
  static const String stateClosed = 'closed';
  static const String statePaused = 'paused';

  Transport(this.options, this.name);

  final String name;
  TransportOptions options;

  String readyState;
  bool writable = false;

  Future<Null> onError(String message, dynamic desc) async {
    await emit(Transport.eventError, <Error>[new EngineIOError(message, desc)]);
  }

  Future<Null> open() async {
    if (readyState == Transport.stateClosed || readyState == null) {
      readyState = Transport.stateOpening;
      await doOpen();
    }
  }

  Future<Null> close() async {
    if (readyState == Transport.stateOpening || readyState == Transport.stateOpen) {
      await doClose();
      await onClose();
    }
  }

  Future<Null> send(List<Packet<dynamic>> packets) async {
    if (readyState == Transport.stateOpen) {
      try {
        await write(packets);
      } catch (err) {
        throw new StateError(err);
      }
    } else {
      throw new StateError('Transport not open');
    }
  }

  Future<Null> onOpen() async {
    log.d('onOpen: ');
    readyState = Transport.stateOpen;
    writable = true;
    await emit(Transport.eventOpen);
  }

  Future<Null> onData(dynamic data) async {
    if (data is String) {
      await onPacket(Parser.decodePacket(data));
    } else if (data is List<int>) {
      await onPacket(Parser.decodeBytePacket(data));
    }
  }

  Future<Null> onPacket(Packet<dynamic> packet) async => await emit(Transport.eventPacket, <Packet<dynamic>>[packet]);

  Future<Null> onClose() async {
    readyState = Transport.stateClosed;
    await emit(Transport.eventClose);
  }

  Future<Null> write(List<Packet<dynamic>> packets);

  Future<Null> doOpen();

  Future<Null> doClose();
}
