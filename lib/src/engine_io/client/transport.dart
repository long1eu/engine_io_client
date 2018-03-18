import 'dart:async';

import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/engine_io/client/engine_io_exception.dart';
import 'package:engine_io_client/src/engine_io/parser/parser.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/packet.dart';
import 'package:engine_io_client/src/models/transport_event.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/models/transport_state.dart';

abstract class Transport extends Emitter {
  static final Log log = new Log('EngineIo.Transport');

  Transport(this.options, this.name);

  final String name;
  TransportOptions options;

  String readyState;
  bool writable = false;

  Future<Null> onError(String message, dynamic desc) async {
    await emit(TransportEvent.error, <Error>[new EngineIOException(message, desc)]);
  }

  Future<Null> open() async {
    if (readyState == TransportState.closed || readyState == null) {
      readyState = TransportState.opening;
      await doOpen();
    }
  }

  Future<Null> close() async {
    if (readyState == TransportState.opening || readyState == TransportState.open) {
      await doClose();
      await onClose();
    }
  }

  Future<Null> send(List<Packet> packets) async {
    if (readyState == TransportState.open) {
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
    readyState = TransportState.open;
    writable = true;
    await emit(TransportEvent.open);
  }

  Future<Null> onData(dynamic data) async {
    if (data is String) {
      await onPacket(Parser.decodePacket(data));
    } else if (data is List<int>) {
      await onPacket(Parser.decodeBytePacket(data));
    }
  }

  Future<Null> onPacket(Packet packet) async => await emit(TransportEvent.packet, <Packet>[packet]);

  Future<Null> onClose() async {
    readyState = TransportState.closed;
    await emit(TransportEvent.close);
  }

  Future<Null> write(List<Packet> packets);

  Future<Null> doOpen();

  Future<Null> doClose();
}
