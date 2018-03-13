typedef void Listener(dynamic args);

class Emitter {
  final Map<String, List<Listener>> _callbacks = <String, List<Listener>>{};
  final Map<String, List<Listener>> _onceCallbacks = <String, List<Listener>>{};

  /// Listens on the event.
  /// @param event event name.
  /// @param callback must not be null
  /// @return a reference to this object.
  Emitter on(String event, Listener callback) {
    assert(callback != null);
    List<Listener> callbacks = _callbacks[event];
    if (callbacks == null) {
      callbacks = <Listener>[];
      final List<Listener> tempCallbacks = _callbacks.putIfAbsent(event, () => callbacks);
      if (tempCallbacks != null) {
        callbacks = tempCallbacks;
      }
    }
    callbacks.add(callback);
    return this;
  }

  /// Adds a one time listener for the event.
  ///
  /// @param event an event name.
  /// @param callback must not be null
  /// @return a reference to this object.
  Emitter once(final String event, final Listener callback) {
    assert(callback != null);
    List<Listener> callbacks = _onceCallbacks[event];
    if (callbacks == null) {
      callbacks = <Listener>[];
      final List<Listener> tempCallbacks = _onceCallbacks.putIfAbsent(event, () => callbacks);
      if (tempCallbacks != null) {
        callbacks = tempCallbacks;
      }
    }
    callbacks.add(callback);

    return this;
  }

  /// If event both [event] and [callback] are provided, it will remove the listener.
  /// If only [event] is provided, it will remove all listeners of the specified [event]
  /// If neither one are specified, it will remove all registered listeners.
  /// [event] an event name.
  /// [callback]
  Emitter off([String event, Listener callback]) {
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
    return this;
  }

  /// Executes each of listeners with the given args.
  ///
  /// @param event an event name.
  /// @param args
  /// @return a reference to this object.
  Emitter emit(String event, [dynamic args]) {
    _onceCallbacks?.remove(event)?.forEach((Listener listener) => listener(args));
    _callbacks[event]?.forEach((Listener listener) => listener(args));

    return this;
  }

  /// Returns a list of listeners for the specified event.
  ///
  /// @param event an event name.
  /// @return a reference to this object.
  List<Listener> listeners(String event) => _callbacks[event] ?? new List<Listener>(0);

  /// Check if this emitter has listeners for the specified event.
  ///
  /// @param event an event name.
  /// @return a reference to this object.
  bool hasListeners(String event) {
    final List<Listener> callbacks = _callbacks[event];
    return callbacks != null && callbacks.isNotEmpty;
  }
}
