import 'package:socket_io/src/emitter/emitter.dart';
import 'package:socket_io/src/engine_io/client/engine_io_exception.dart';
import 'package:socket_io/src/engine_io/parser/parser.dart';
import 'package:socket_io/src/models/packet.dart';
import 'package:socket_io/src/models/transport_event.dart';
import 'package:socket_io/src/models/transport_options.dart';
import 'package:socket_io/src/models/transport_state.dart';

abstract class Transport extends Emitter {
  Transport(this.options, this.name);

  final String name;
  TransportOptions options;

  TransportState readyState;
  bool writable;

  Transport onError(String message, Exception desc) {
    final Exception err = new EngineIOException(message, desc);
    emit(TransportEvent.error.name, err);
    return this;
  }

  Transport open() {
    if (readyState == TransportState.closed || readyState == null) {
      readyState = TransportState.opening;
      doOpen();
    }

    return this;
  }

  Transport close() {
    if (readyState == TransportState.opening || readyState == TransportState.open) {
      doClose();
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

  void onData(dynamic data) {
    if (data is String) {
      onPacket(Parser.decodePacket(data));
    } else if (data is List<int>) {
      onPacket(Parser.decodeBytePacket(data));
    }
  }

  void onPacket(Packet packet) {
    emit(TransportEvent.packet.name, packet);
  }

  void onClose() {
    readyState = TransportState.closed;
    emit(TransportEvent.close.name);
  }

  void write(List<Packet> packets);

  void doOpen();

  void doClose();
}
