import 'dart:async';

import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/engine_io/client/socket.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/socket_options.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() {
  final Log log = new Log('EngineIo.connection_test');

  final SocketOptions opts = new SocketOptions(port: Connection.PORT);

  test('connectToLocalhost', () {
    final Socket socket = new Socket(opts);
    final Observable<Event> onMessage$ = socket.on(Socket.eventMessage).map((Event event) => event.args[0]);

    socket.open$.listen(null);

    expect(onMessage$, emitsInOrder(<dynamic>['hi']));
  });

  test('receiveMultibyteUTF8StringsWithPolling', () {
    final Socket socket = new Socket(opts);

    final Observable<Event> onMessage$ = socket.on(Socket.eventMessage).map((Event event) => event.args[0]);

    socket.open$.flatMap((Event event) => socket.send$('cash money €€€')).listen(null);

    expect(onMessage$, emitsInOrder(<String>['hi', 'cash money €€€']));
  });

  test('receiveEmoji', () async {
    final Socket socket = new Socket(opts);
    final Observable<Event> onMessage$ = socket.on(Socket.eventMessage).map((Event event) => event.args[0]);

    socket.open$
        .flatMap((Event event) => socket.send$('\uD800\uDC00-\uDB7F\uDFFF\uDB80\uDC00-\uDBFF\uDFFF\uE000-\uF8FF'))
        .listen(null);

    expect(onMessage$, emitsInOrder(<String>['hi', '\uD800\uDC00-\uDB7F\uDFFF\uDB80\uDC00-\uDBFF\uDFFF\uE000-\uF8FF']));
  });

  test('notSendPacketsIfSocketCloses', () {
    final Socket socket = new Socket(opts);

    final Observable<Event> stream$ = new Observable<Event>.race(<Observable<Event>>[
      socket.open$.flatMap((Event event) => new Observable<Event>.merge(<Observable<Event>>[
            socket.on(Socket.eventPacketCreate),
            socket.close$.flatMap((Event event) => socket.send$('dddd')),
          ])),
      new Observable<String>.just('')
          .delay(const Duration(seconds: 3))
          .flatMap((String _) => new Observable<Event>.just(new Event('empty'))),
    ]);

    expect(stream$, emits(new Event('empty')));
  });

  test('deferCloseWhenUpgrading', () async {
    final Socket socket = new Socket(opts);

    final Observable<Event> events$ =
        socket.on(Socket.eventOpen).flatMap((Event _) => new Observable<Event>.merge(<Observable<Event>>[
              socket.on(Socket.eventUpgrade).map((Event event) => new Event(Socket.eventUpgrade)),
              socket.on(Socket.eventUpgrading).flatMap((Event event) => socket.close$),
            ]));

    socket.open$.listen(log.e);

    expect(events$, emits(new Event(Socket.eventUpgrade)));
  });

  /*
  test('closeOnUpgradeErrorIfClosingIsDeferred', () async {
    final Socket socket = new Socket(opts);

    new Observable.merge([
      socket.on(Socket.eventUpgrade).doOnData((Event e) => log.w(e)),
      socket.on(Socket.eventUpgradeError).map((Event event) => new Event(Socket.eventUpgradeError)).doOnData(log.w),
      socket.on(Socket.eventUpgrading).flatMap((Event event) => new Observable<Event>.merge(<Observable<Event>>[
            socket.close$.doOnData(log.w),
            socket.transport.onError('upgrade error', new Exception()).ignoreElements(),
          ])),
    ])
      ..listen(null);

    final Observable<Event> events$ = socket.on(Socket.eventOpen).doOnData(log.i);

    socket.open$.listen(log.e);
    await new Future<Null>.delayed(const Duration(seconds: Connection.TIMEOUT), () {});
    //expect(events$, emitsAnyOf(<dynamic>[new Event(Socket.eventClose)]));
  });
  */

  test('notSendPacketsIfClosingIsDeferred', () async {
    bool noPacket = true;
    final Socket socket = new Socket(opts);

    final Observable<Event> events$ = socket
        .on(Socket.eventOpen)
        .flatMap((Event event) => socket.on(Socket.eventUpgrade))
        .flatMap((Event event) => new Observable<Event>.merge(<Observable<Event>>[
              socket.on(Socket.eventPacketCreate).map((Event event) => new Event(event.name)),
              socket.close$.flatMap((Event event) => socket.send$('hi')),
            ]));

    socket.open$
        .doOnData(log.w)
        //.flatMap((Event event) => socket.on(Socket.eventUpgrade))
        //.doOnData(log.w)
        .flatMap((Event event) => new Observable<Event>.merge(<Observable<Event>>[
              socket.on(Socket.eventPacketCreate).map((Event event) => new Event(event.name)),
              socket.close$.flatMap((Event event) => socket.send$('hi')),
            ]))
          ..listen(log.w);

    await new Future<Null>.delayed(const Duration(seconds: 5), () {});

    //expect(noPacket, isTrue);
  });
/*
  test('sendAllBufferedPacketsIfClosingIsDeferred', () async {
    int length;

    final Socket socket = new Socket(opts);
    socket.on(Socket.eventOpen, (List<dynamic> args) {
      socket
        ..on(Socket.eventUpgrading, (List<dynamic> args) async {
          await socket.send$('hsi');
          await socket.close$();
        })
        ..on(Socket.eventClose, (List<dynamic> args) {
          log.d('close.name');
          length = socket.writeBuffer.length;
        });
    });
    await socket.open$();
    await new Future<Null>.delayed(const Duration(milliseconds: Connection.TIMEOUT), () {});

    expect(length, 0);
  });*/
}
