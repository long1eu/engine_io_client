import 'dart:async';

typedef Future<void> Listener(List<dynamic> args);

class Emitter {
  final Map<String, Set<Listener>> _callbacks = <String, Set<Listener>>{};
  final Map<String, Set<Listener>> _onceCallbacks = <String, Set<Listener>>{};

  /// Listens on the event.
  /// @param event event name.
  /// @param callback must not be null
  /// @return a reference to this object.
  void on(String event, Listener callback) {
    assert(callback != null);
    final Set<Listener> callbacks = _callbacks[event] ?? Set<Listener>();
    callbacks.add(callback);
    _callbacks[event] = callbacks;
  }

  /// Adds a one time listener for the event.
  ///
  /// @param event an event name.
  /// @param callback must not be null
  /// @return a reference to this object.
  void once(final String event, final Listener callback) {
    assert(callback != null);
    final Set<Listener> callbacks = _onceCallbacks[event] ?? Set<Listener>();
    callbacks.add(callback);
    _onceCallbacks[event] = callbacks;
  }

  /// If event both [event] and [callback] are provided, it will remove the listener.
  /// If only [event] is provided, it will remove all listeners of the specified [event]
  /// If neither one are specified, it will remove all registered listeners.
  /// [event] an event name.
  /// [callback]
  void off([String event, Listener callback]) {
    if (event != null && callback != null) {
      _callbacks[event]?.removeWhere((Listener it) => it == callback);
      _onceCallbacks[event]?.removeWhere((Listener it) => it == callback);
    } else if (event != null) {
      _callbacks.remove(event);
      _onceCallbacks.remove(event);
    } else {
      _callbacks.clear();
      _onceCallbacks.clear();
    }
  }

  /// Executes each of listeners with the given args.
  ///
  /// @param event an event name.
  /// @param args
  /// @return a reference to this object.
  Future<void> emit(String event, [List<dynamic> args]) async {
    final List<Listener> removed = _onceCallbacks?.remove(event)?.toList();
    if (removed != null) for (Listener listener in removed) await listener(args);

    final List<Listener> listeners = _callbacks[event]?.toList();
    if (listeners != null) for (Listener listener in listeners) await listener(args);
  }

  /// Returns a list of listeners for the specified event.
  ///
  /// @param event an event name.
  /// @return a reference to this object.
  Set<Listener> listeners(String event) => _callbacks[event] ?? Set<Listener>();

  /// Check if this emitter has listeners for the specified event.
  ///
  /// @param event an event name.
  /// @return a reference to this object.
  bool hasListeners(String event) {
    final Set<Listener> callbacks = _callbacks[event];
    return callbacks != null && callbacks.isNotEmpty;
  }
}
