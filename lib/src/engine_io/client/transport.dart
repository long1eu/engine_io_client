import 'package:socket_io/src/emitter/emitter.dart';
import 'package:socket_io/src/engine_io/client/engine_io_exception.dart';
import 'package:socket_io/src/engine_io/parser/parser.dart';
import 'package:socket_io/src/models/packet.dart';
import 'package:socket_io/src/models/ready_state.dart';
import 'package:socket_io/src/models/transport_event.dart';
import 'package:socket_io/src/models/transport_options.dart';

abstract class Transport extends Emitter {
  Transport(this.options, this.name);

  final TransportOptions options;
  final String name;

  ReadyState readyState;
  bool writable;

  Transport onError(String message, Exception desc) {
    final Exception err = new EngineIOException(message, desc);
    emit(TransportEvent.error.name, err);
    return this;
  }

  Transport open() {
    if (readyState == ReadyState.closed || readyState == null) {
      readyState = ReadyState.opening;
      doOpen();
    }

    return this;
  }

  Transport close() {
    if (readyState == ReadyState.opening || readyState == ReadyState.open) {
      doClose();
      onClose();
    }

    return this;
  }

  void send(List<Packet> packets) {
    if (readyState == ReadyState.open) {
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
    readyState = ReadyState.open;
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
    readyState = ReadyState.closed;
    emit(TransportEvent.close.name);
  }

  void write(List<Packet> packets);

  void doOpen();

  void doClose();
}
