import 'dart:async';

import 'package:collection/collection.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:rxdart/rxdart.dart';

class Emitter {
  static final Log log = new Log('Emitter');

  StreamController<Event> _events = new StreamController<Event>.broadcast();
  Observable<Event> _observable;

  Emitter() {
    _observable = new Observable<Event>(_events.stream);
  }

  /// Listens for the event with the [event] name. It will return an [Observable<Event>] that you can listen to.
  Observable<Event> on(final String event) {
    return _observable.doOnData(log.d).where((Event e) => e.name == event).takeWhile((Event event) => event is! _CancelEvent);
  }

  /// Listens for the event only once. It returns an [Observable<Event>] that you can listen to.
  Observable<Event> once(final String event) =>
      _observable.where((Event e) => e.name == event).take(1).takeWhile((Event event) => event is! _CancelEvent);

  /// Unsubscribe from the [event] or if [event] is null it will unsubscribe for all events.
  void off([String event]) {
    if (event != null) {
      _events.add(new _CancelEvent(event));
    } else {
      _events.close();
      _events = new StreamController<Event>.broadcast();
    }
  }

  void offAll([List<String> events]) => events.forEach(off);

  void offAfter({String event, Duration duration = Duration.zero}) {
    if (event != null) {
      new Observable<String>.just(event).delay(duration).forEach((String event) => _events.add(new _CancelEvent(event)));
    } else {
      new Observable<String>.just('').delay(duration).forEach((String _) {
        _events.close();
        _events = new StreamController<Event>.broadcast();
      });
    }
  }

  /// Emits an [Event] with the [event] name and [args] parameters.
  void emit(String event, [List<dynamic> args]) => _events.add(new Event(event, args));

  void emitAll(List<Event> events) => new Observable<Event>.fromIterable(events).forEach(_events.add);

  /// Emits an [Event] with the [event] name and [args] parameters after [duration] has passed. If duration is not provided
  /// this acts exactly as [emit]
  void emitAfter(String event, {List<dynamic> args, Duration duration = Duration.zero}) =>
      new Observable<String>.just(event).delay(duration).listen((String event) => _events.add(new Event(event, args)));

  void emitAllAfter(List<Event> events, {Duration duration}) =>
      new Observable<Event>.fromIterable(events).delay(duration).forEach(_events.add);
}

class _CancelEvent extends Event {
  _CancelEvent(String name) : super(name);
}

class Event {
  Event(this.name, [this.args]);

  final String name;

  final List<dynamic> args;

  @override
  String toString() => 'Event{name: $name, args: $args}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          const DeepCollectionEquality().equals(args, other.args);

  @override
  int get hashCode => name.hashCode ^ args.hashCode;
}
