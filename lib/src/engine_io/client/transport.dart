import 'dart:async';

import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/engine_io/client/engine_io_error.dart';
import 'package:engine_io_client/src/engine_io/parser/parser.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/packet.dart';
import 'package:engine_io_client/src/models/transport_event.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/models/transport_state.dart';

abstract class Transport extends Emitter {
  static final Log log = Log('EngineIo.Transport');

  Transport(this.options, this.name);

  final String name;
  TransportOptions options;

  String readyState;
  bool writable = false;

  Future<void> onError(String message, dynamic desc) async {
    await emit(TransportEvent.error, <Error>[EngineIOError(message, desc)]);
  }

  Future<void> open() async {
    if (readyState == TransportState.closed || readyState == null) {
      readyState = TransportState.opening;
      await doOpen();
    }
  }

  Future<void> close() async {
    if (readyState == TransportState.opening || readyState == TransportState.open) {
      await doClose();
      await onClose();
    }
  }

  Future<void> send<T>(List<Packet<T>> packets) async {
    if (readyState == TransportState.open) {
      try {
        await write(packets);
      } catch (err) {
        log.d(err);
        throw StateError(err?.toString());
      }
    } else {
      throw StateError('Transport not open');
    }
  }

  Future<void> onOpen() async {
    log.d('onOpen: ');
    readyState = TransportState.open;
    writable = true;
    await emit(TransportEvent.open);
  }

  Future<void> onData(dynamic data) async {
    if (data is String) {
      await onPacket(Parser.decodePacket(data));
    } else if (data is List<int>) {
      await onPacket(Parser.decodeBytePacket(data));
    }
  }

  Future<void> onPacket<T>(Packet<T> packet) async => await emit(TransportEvent.packet, <Packet<T>>[packet]);

  Future<void> onClose() async {
    readyState = TransportState.closed;
    await emit(TransportEvent.close);
  }

  Future<void> write<T>(List<Packet<T>> packets);

  Future<void> doOpen();

  Future<void> doClose();
}
