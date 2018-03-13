import 'dart:async';

import 'package:flutter_logger/flutter_logger.dart';
import 'package:socket_io/src/emitter/emitter.dart';
import 'package:socket_io/src/engine_io/client/engine_io_exception.dart';
import 'package:socket_io/src/engine_io/parser/parser.dart';
import 'package:socket_io/src/models/packet.dart';
import 'package:socket_io/src/models/transport_event.dart';
import 'package:socket_io/src/models/transport_options.dart';
import 'package:socket_io/src/models/transport_state.dart';

abstract class Transport extends Emitter {
  static final Log log = new Log('Transport');

  Transport(this.options, this.name);

  final String name;
  TransportOptions options;

  TransportState readyState;
  bool writable = false;

  Transport onError(String message, dynamic desc) {
    emit(TransportEvent.error.name, new EngineIOException(message, desc));
    return this;
  }

  Future<Transport> open() async {
    if (readyState == TransportState.closed || readyState == null) {
      readyState = TransportState.opening;
      await doOpen();
    }

    return this;
  }

  Future<Transport> close() async {
    if (readyState == TransportState.opening || readyState == TransportState.open) {
      await doClose();
      onClose();
    }

    return this;
  }

  void send(List<Packet> packets) {
    if (readyState == TransportState.open) {
      try {
        write(packets);
      } catch (err) {
        throw new StateError(err);
      }
    } else {
      throw new StateError('Transport not open');
    }
  }

  void onOpen() {
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

  void onPacket(Packet packet) => emit(TransportEvent.packet.name, packet);

  void onClose() {
    readyState = TransportState.closed;
    emit(TransportEvent.close.name);
  }

  Future<Null> write(List<Packet> packets);

  Future<Null> doOpen();

  Future<Null> doClose();
}
