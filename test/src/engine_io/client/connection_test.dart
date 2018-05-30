import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/engine_io/client/engine_io_error.dart';
import 'package:engine_io_client/src/engine_io/client/socket.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() {
  final Log log = new Log('EngineIo.connection_test');

  const SocketOptions opts = const SocketOptions(port: Connection.PORT);

  test('connectToLocalhost', () {
    final Socket socket = new Socket(opts);
    final Observable<Event> onMessage$ = socket.on(Socket.eventMessage).map((Event event) => event.args[0]);

    socket.open();

    expect(onMessage$, emitsInOrder(<dynamic>['hi']));
  });

  test('receiveMultibyteUTF8StringsWithPolling', () {
    final Socket socket = new Socket(opts);

    final Observable<Event> onMessage$ = socket.on(Socket.eventMessage).map((Event event) => event.args[0]);
    socket.on(Socket.eventOpen).flatMap((Event event) => socket.write$('cash money €€€')).listen(null);
    socket.open();

    expect(onMessage$, emitsInOrder(<String>['hi', 'cash money €€€']));
  });

  test('receiveEmoji', () async {
    final Socket socket = new Socket(opts);
    final Observable<Event> onMessage$ = socket.on(Socket.eventMessage).map((Event event) => event.args[0]);

    socket
        .on(Socket.eventOpen)
        .flatMap((Event event) => socket.write$('\uD800\uDC00-\uDB7F\uDFFF\uDB80\uDC00-\uDBFF\uDFFF\uE000-\uF8FF'))
        .listen(null);

    socket.open();

    expect(onMessage$, emitsInOrder(<String>['hi', '\uD800\uDC00-\uDB7F\uDFFF\uDB80\uDC00-\uDBFF\uDFFF\uE000-\uF8FF']));
  });

  test('notSendPacketsIfSocketCloses', () async {
    final Socket socket = new Socket(opts);

    final Observable<Event> events$ = new Observable<Event>.race(<Observable<Event>>[
      socket.on(Socket.eventPacketCreate),
      socket.on(Socket.eventUpgradeError).map((Event event) => throw event.args[0]),
    ]);

    socket.on(Socket.eventOpen).listen((Event event) {
      log.d(event);
      socket.close();
      socket.send('dddd');
    });

    socket.open();

    expect(
      events$,
      emitsError(new EngineIOError('websocket', 'probe error: Bad state: socket closed')),
    );
  });

  test('deferCloseWhenUpgrading', () async {
    final Socket socket = new Socket(opts);

    final Observable<Event> events$ = new Observable<Event>.merge(<Observable<Event>>[
      socket.on(Socket.eventUpgrade).map((Event event) => new Event(Socket.eventUpgrade)),
      socket.on(Socket.eventUpgrading).doOnData((Event event) => socket.close()).ignoreElements(),
    ]);

    socket.open();

    expect(events$, emits(new Event(Socket.eventUpgrade)));
  });

  test('closeOnUpgradeErrorIfClosingIsDeferred', () async {
    final Socket socket = new Socket(opts);

    final Observable<Event> events$ = new Observable<Event>.merge(<Observable<Event>>[
      socket.on(Socket.eventUpgrade),
      socket.on(Socket.eventUpgradeError).map((Event event) => throw event.args[0]),
      socket.on(Socket.eventUpgrading).doOnData((Event event) {
        socket.transport.onError('upgrade error', new Exception());
        socket.close();
      }).ignoreElements(),
    ]);

    socket.open();

    expect(
      events$,
      emitsError(new EngineIOError('websocket', 'probe error: Bad state: socket closed')),
    );
  });

  test('notSendPacketsIfClosingIsDeferred', () async {
    final Socket socket = new Socket(opts);

    final Observable<Event> events$ = new Observable<Event>.merge(<Observable<Event>>[
      socket
          .on(Socket.eventUpgrading)
          .doOnData((Event event) {
            socket.close();
            socket.send('hi');
          })
          .delay(const Duration(seconds: 1))
          .map((Event event) => new Event(Socket.eventClose)),
      socket.on(Socket.eventPacketCreate),
    ]);

    socket.open();

    expect(events$, emits(new Event(Socket.eventClose)));
  });

  test('sendAllBufferedPacketsIfClosingIsDeferred', () async {
    final Socket socket = new Socket(opts);

    final Observable<Event> events$ = new Observable<Event>.merge(<Observable<Event>>[
      socket.on(Socket.eventUpgrading).flatMap((Event event) => socket.write$('his')).doOnData((Event event) => socket.close()),
      socket.on(Socket.eventClose)
    ]);

    socket.open();

    expect(events$, emits(new Event(Socket.eventFlush)));
  });
}
