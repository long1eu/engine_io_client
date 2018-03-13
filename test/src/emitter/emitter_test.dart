import 'package:socket_io/src/emitter/emitter.dart';
import 'package:test/test.dart';

void main() {
  test('on', () {
    final Emitter emitter = new Emitter();
    final List<dynamic> calls = <dynamic>[];

    emitter.on('foo', (dynamic args) {
      calls.add('one');
      calls.add(args);
    });

    emitter.on('foo', (dynamic args) {
      calls.add('two');
      calls.add(args);
    });

    emitter.emit('foo', 1);
    emitter.emit('bar', 1);
    emitter.emit('foo', 2);

    expect(calls, equals(<dynamic>['one', 1, 'two', 1, 'one', 2, 'two', 2]));
  });

  test('once', () {
    final Emitter emitter = new Emitter();
    final List<dynamic> calls = <dynamic>[];

    emitter.once('foo', (dynamic args) {
      calls.add('one');
      calls.add(args);
    });

    emitter.emit('foo', 1);
    emitter.emit('foo', 2);
    emitter.emit('foo', 3);
    emitter.emit('bar', 1);

    expect(calls, equals(<dynamic>['one', 1]));
  });

  test('off', () {
    final Emitter emitter = new Emitter();
    final List<dynamic> calls = <dynamic>[];

    void one(dynamic args) => calls.add('one');
    void two(dynamic args) => calls.add('two');

    emitter.on('foo', one);
    emitter.on('foo', two);
    emitter.off('foo', two);

    emitter.emit('foo');

    expect(calls, equals(<dynamic>['one']));
  });

  test('offWithOnce', () {
    final Emitter emitter = new Emitter();
    final List<dynamic> calls = <dynamic>[];

    void one(dynamic args) => calls.add('one');

    emitter.once('foo', one);
    emitter.off('foo', one);

    emitter.emit('foo');

    expect(calls, equals(<dynamic>[]));
  });

  test('offWhenCalledFromEvent', () {
    final Emitter emitter = new Emitter();
    bool called = false;

    void b(dynamic args) => called = true;

    emitter.on('tobi', (dynamic args) => emitter.off('tobi', b));
    emitter.once('tobi', b);
    emitter.emit('tobi');

    expect(called, isTrue);

    called = false;
    emitter.emit('tobi');
    expect(called, isFalse);
  });

  test('offEvent', () {
    final Emitter emitter = new Emitter();
    final List<dynamic> calls = <dynamic>[];

    void one(dynamic args) => calls.add('one');
    void two(dynamic args) => calls.add('two');

    emitter.on('foo', one);
    emitter.on('foo', two);
    emitter.off('foo');

    emitter.emit('foo');
    emitter.emit('foo');

    expect(calls, equals(<dynamic>[]));
  });

  test('offAll', () {
    final Emitter emitter = new Emitter();
    final List<dynamic> calls = <dynamic>[];

    void one(dynamic args) => calls.add('one');
    void two(dynamic args) => calls.add('two');

    emitter.on('foo', one);
    emitter.on('bar', two);

    emitter.emit('foo');
    emitter.emit('bar');

    emitter.off();

    emitter.emit('foo');
    emitter.emit('bar');

    expect(calls, equals(<dynamic>['one', 'two']));
  });

  test('listeners', () {
    final Emitter emitter = new Emitter();
    void foo(dynamic args) {}

    emitter.on('foo', foo);

    expect(emitter.listeners('foo'), equals(<Listener>[foo]));
  });

  test('listenersWithoutHandlers', () {
    final Emitter emitter = new Emitter();
    expect(emitter.listeners('foo'), equals(<Listener>[]));
  });

  test('hasListeners', () {
    final Emitter emitter = new Emitter();
    void foo(dynamic args) {}

    emitter.on('foo', foo);

    expect(emitter.hasListeners('foo'), isTrue);
  });

  test('hasListenersWithoutHandlers', () {
    final Emitter emitter = new Emitter();
    expect(emitter.hasListeners('foo'), isFalse);
  });
}
