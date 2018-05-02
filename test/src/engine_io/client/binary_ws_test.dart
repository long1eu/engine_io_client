import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/engine_io/client/socket.dart';
import 'package:engine_io_client/src/engine_io/client/transports/web_socket.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() async {
  final Log log = new Log('EngineIo.binary_ws_connection');

  test('receiveBinaryData', () async {
    final List<int> binaryData = new List<int>.generate(5, (int i) => i);

    final SocketOptions opts = new SocketOptions(port: Connection.PORT, transports: <String>[WebSocket.NAME]);
    final Socket socket = new Socket(opts);

    final Observable<Event> onMessage$ =
        socket.on(Socket.eventMessage).doOnData(log.e).map<dynamic>((Event event) => event.args[0]).take(2);

    socket.open$.flatMap((Event event) => socket.send$(binaryData)).listen(null);

    expect(onMessage$, emitsInOrder(<dynamic>['hi', binaryData, emitsDone]));
  });

  test('receiveBinaryDataAndMultibyteUTF8String', () async {
    final List<int> binaryData = new List<int>.generate(5, (int i) => i);

    final SocketOptions opts = new SocketOptions(port: Connection.PORT, transports: <String>[WebSocket.NAME]);
    final Socket socket = new Socket(opts);

    final Observable<Event> onMessage$ = socket
        .on(Socket.eventMessage)
        .doOnData(log.e)
        .where((Event event) => event.args[0] != 'hi')
        .map<dynamic>((Event event) => event.args[0])
        .take(4);

    socket.open$
        .flatMap((Event event) => new Observable<Event>.merge(<Observable<Event>>[
              socket.send$(binaryData),
              socket.send$('cash money €€€'),
              socket.send$('cash money ss €€€'),
              socket.send$('20["getAckBinary",""]'),
            ]))
        .listen(null);

    expect(
        onMessage$,
        emitsInOrder(<dynamic>[
          binaryData,
          'cash money €€€',
          'cash money ss €€€',
          '20["getAckBinary",""]',
          emitsDone,
        ]));
  });
}
