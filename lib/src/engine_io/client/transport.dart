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

  TransportState readyState;
  bool writable = false;

  void onError(String message, dynamic desc) {
    emit(TransportEvent.error.name, <Error>[new EngineIOException(message, desc)]);
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
      onClose();
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

  void onOpen() {
    log.d('onOpen: ');
    readyState = TransportState.open;
    writable = true;
    emit(TransportEvent.open.name);
  }

  Future<Null> onData(dynamic data) async {
    if (data is String) {
      onPacket(Parser.decodePacket(data));
    } else if (data is List<int>) {
      onPacket(Parser.decodeBytePacket(data));
    }
  }

  void onPacket(Packet packet) => emit(TransportEvent.packet.name, <Packet>[packet]);

  void onClose() {
    readyState = TransportState.closed;
    emit(TransportEvent.close.name);
  }

  Future<Null> write(List<Packet> packets);

  Future<Null> doOpen();

  Future<Null> doClose();
}
