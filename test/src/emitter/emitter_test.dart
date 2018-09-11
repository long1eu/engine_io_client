import 'dart:async';

import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:test/test.dart';

void main() {
  test('on', () async {
    final Emitter emitter = Emitter();
    final List<dynamic> calls = <dynamic>[];

    emitter.on('foo', (List<dynamic> args) {
      calls.add('one');
      calls.add(args[0]);
    });

    emitter.on('foo', (List<dynamic> args) {
      calls.add('two');
      calls.add(args[0]);
    });

    await emitter.emit('foo', <int>[1]);
    await emitter.emit('bar', <int>[1]);
    await emitter.emit('foo', <int>[2]);

    expect(calls, equals(<dynamic>['one', 1, 'two', 1, 'one', 2, 'two', 2]));
  });

  test('once', () async {
    final Emitter emitter = Emitter();
    final List<dynamic> calls = <dynamic>[];

    emitter.once('foo', (List<dynamic> args) {
      calls.add('one');
      calls.add(args[0]);
    });

    await emitter.emit('foo', <dynamic>[1]);
    await emitter.emit('foo', <dynamic>[2]);
    await emitter.emit('foo', <dynamic>[3]);
    await emitter.emit('bar', <dynamic>[1]);

    expect(calls, equals(<dynamic>['one', 1]));
  });

  test('off', () async {
    final Emitter emitter = Emitter();
    final List<dynamic> calls = <dynamic>[];

    Future<void> one(List<dynamic> args) async => calls.add('one');
    Future<void> two(List<dynamic> args) async => calls.add('two');

    emitter.on('foo', one);
    emitter.on('foo', two);
    emitter.off('foo', two);

    await emitter.emit('foo');

    expect(calls, equals(<dynamic>['one']));
  });

  test('offWithOnce', () async {
    final Emitter emitter = Emitter();
    final List<dynamic> calls = <dynamic>[];

    Future<void> one(List<dynamic> args) async => calls.add('one');

    emitter.once('foo', one);
    emitter.off('foo', one);

    await emitter.emit('foo');

    expect(calls, equals(<dynamic>[]));
  });

  test('offWhenCalledFromEvent', () async {
    final Emitter emitter = Emitter();
    bool called = false;

    Future<void> b(List<dynamic> args) async {
      called = true;
    }

    emitter.on('tobi', (List<dynamic> args) async => emitter.off('tobi', b));
    emitter.once('tobi', b);
    await emitter.emit('tobi');

    expect(called, isTrue);

    called = false;
    await emitter.emit('tobi');
    expect(called, isFalse);
  });

  test('offEvent', () async {
    final Emitter emitter = Emitter();
    final List<dynamic> calls = <dynamic>[];

    Future<void> one(List<dynamic> args) async => calls.add('one');
    Future<void> two(List<dynamic> args) async => calls.add('two');

    emitter.on('foo', one);
    emitter.on('foo', two);
    emitter.off('foo');

    await emitter.emit('foo');
    await emitter.emit('foo');

    expect(calls, equals(<dynamic>[]));
  });

  test('offAll', () async {
    final Emitter emitter = Emitter();
    final List<dynamic> calls = <dynamic>[];

    Future<void> one(List<dynamic> args) async => calls.add('one');
    Future<void> two(List<dynamic> args) async => calls.add('two');

    emitter.on('foo', one);
    emitter.on('bar', two);

    await emitter.emit('foo');
    await emitter.emit('bar');

    emitter.off();

    await emitter.emit('foo');
    await emitter.emit('bar');

    expect(calls, equals(<dynamic>['one', 'two']));
  });

  test('listeners', () {
    final Emitter emitter = Emitter();
    Future<void> foo(List<dynamic> args) async {}

    emitter.on('foo', foo);

    expect(emitter.listeners('foo'), equals(<Listener>[foo]));
  });

  test('listenersWithoutHandlers', () {
    final Emitter emitter = Emitter();
    expect(emitter.listeners('foo'), equals(<Listener>[]));
  });

  test('hasListeners', () {
    final Emitter emitter = Emitter();
    Future<void> foo(List<dynamic> args) async {}

    emitter.on('foo', foo);

    expect(emitter.hasListeners('foo'), isTrue);
  });

  test('hasListenersWithoutHandlers', () {
    final Emitter emitter = Emitter();
    expect(emitter.hasListeners('foo'), isFalse);
  });
}
