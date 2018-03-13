import 'dart:async';

import 'package:socket_io/src/engine_io/client/socket.dart';
import 'package:socket_io/src/models/socket_event.dart';
import 'package:socket_io/src/models/socket_options.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() {
  final SocketOptions opts = new SocketOptions((SocketOptionsBuilder b) {
    b..port = Connection.PORT;
  });

  test('openAndClose', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = new Socket(opts);
    socket
        .on(SocketEvent.open.name, (dynamic args) => values.add('onOpen'))
        .on(SocketEvent.close.name, (dynamic args) => values.add('onClose'));

    socket.open();
    await new Future.delayed(const Duration(milliseconds: 500), () {});
    expect(values.first, 'onOpen');
    await socket.close();
    await new Future.delayed(const Duration(milliseconds: 2000), () {});
    expect(values.length, 2);
    expect(values.last, 'onClose');
  });
}
