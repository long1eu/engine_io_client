import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  const Duration duration = const Duration(milliseconds: 500);

  test('on', () {
    final Emitter emitter = new Emitter();

    final Observable<dynamic> events$ = new Observable<List<dynamic>>.merge(<Observable<List<dynamic>>>[
      emitter.on('foo').map<List<dynamic>>((Event event) => <dynamic>['one', event.args[0]]),
      emitter.on('foo').map<List<dynamic>>((Event event) => <dynamic>['two', event.args[0]]),
    ]).expand<dynamic>((List<dynamic> events) => events);

    emitter.emitAfter('foo', args: <int>[1], duration: duration);
    emitter.emitAfter('bar', args: <int>[1], duration: duration);
    emitter.emitAfter('foo', args: <int>[2], duration: duration);

    expect(events$, emitsInOrder(<dynamic>['one', 1, 'two', 1, 'one', 2, 'two', 2]));
  });

  test('once', () {
    final Emitter emitter = new Emitter();

    final Observable<dynamic> event$ = emitter
        .once('foo')
        .map<List<dynamic>>((Event event) => <dynamic>['one', event.args[0]])
        .expand<dynamic>((List<dynamic> list) => list);

    emitter.emitAfter('foo', args: <dynamic>[1], duration: duration);
    emitter.emitAfter('foo', args: <dynamic>[2], duration: duration);
    emitter.emitAfter('foo', args: <dynamic>[3], duration: duration);
    emitter.emitAfter('bar', args: <dynamic>[1], duration: duration);

    expect(event$, emitsInOrder(<dynamic>['one', 1]));
  });

  test('off', () async {
    final Emitter emitter = new Emitter();

    final Observable<dynamic> events$ = new Observable<String>.merge(<Observable<String>>[
      emitter.on('foo').map((Event event) => 'one'),
      emitter.on('foo').map((Event event) => 'two'),
    ]);

    emitter.emitAfter('foo', duration: duration);
    emitter.off('foo');
    emitter.emitAfter('foo', duration: duration);
    emitter.emitAfter('bar', duration: duration);

    expect(events$, emitsInOrder(<dynamic>['one', 'two']));
  });

  test('offWithOnce', () async {
    final Emitter emitter = new Emitter();

    final Observable<String> event$ = emitter.once('foo').map((Event event) => 'one');

    emitter.off('foo');
    emitter.emitAfter('foo', duration: duration);

    expect(event$, emitsInOrder(<dynamic>[]));
  });

  test('offWhenCalledFromEvent', () async {
    final Emitter emitter = new Emitter();

    final Observable<dynamic> values$ = new Observable<dynamic>.merge(<Observable<dynamic>>[
      emitter
          .on('tobi')
          .forEach((Event event) => emitter.off('tobi'))
          .asObservable()
          .forEach((dynamic _) => emitter.emit('tobi'))
          .asObservable(),
      emitter.on('tobi').map<dynamic>((Event event) => true)
    ]);

    emitter.emitAfter('tobi', duration: duration);
    expect(values$, emitsInOrder(<bool>[true, null]));
  });

  test('offEvent', () async {
    final Emitter emitter = new Emitter();

    final Observable<dynamic> events$ = new Observable<String>.merge(<Observable<String>>[
      emitter.on('foo').map((Event event) => 'one'),
      emitter.on('foo').map((Event event) => 'two'),
    ]);

    emitter.off('foo');

    emitter.emitAfter('foo', duration: duration);
    emitter.emitAfter('foo', duration: duration);

    expect(events$, emitsInOrder(<dynamic>[]));
  });

  test('offAll', () async {
    final Emitter emitter = new Emitter();

    final Observable<dynamic> events$ = new Observable<String>.merge(<Observable<String>>[
      emitter.on('foo').map((Event event) => 'one'),
      emitter.on('bar').map((Event event) => 'two'),
    ]);

    emitter.emitAllAfter(<Event>[new Event('foo'), new Event('bar')], duration: duration);

    emitter.offAfter(duration: duration + const Duration(seconds: 1));
    emitter.emitAllAfter(<Event>[new Event('foo'), new Event('bar')], duration: duration * 1.1);

    expect(events$, emitsInOrder(<dynamic>['one', 'two']));
  });
}
