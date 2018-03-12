class Emitter {
  final Map<String, List<Listener>> _callbacks = <String, List<Listener>>{};

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
    on(event, new _OnceListener(this, event, callback));
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
    } else if (event != null) {
      _callbacks.remove(event);
    } else {
      _callbacks.clear();
    }
    return this;
  }

  /// Executes each of listeners with the given args.
  ///
  /// @param event an event name.
  /// @param args
  /// @return a reference to this object.
  Emitter emit(String event, [dynamic args]) {
    final List<Listener> callbacks = _callbacks[event]?.toList();
    if (callbacks != null) {
      callbacks.removeWhere((Listener callback) => callback.call(args));
      _callbacks[event] = callbacks;
    }

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

class Listener {
  Listener._();

  factory Listener.callback(void callback(dynamic args)) {
    return new Listener._()
      ..call = (dynamic args) {
        callback(args);
        return false;
      };
  }

  Function call;
}

class _OnceListener implements Listener {
  _OnceListener(this.emitter, this.event, this.callback);

  final String event;
  final Listener callback;
  final Emitter emitter;

  @override
  Function get call => (dynamic args) {
        callback.call(args);
        return true;
      };

  @override
  set call(Function _call) {
    call = _call;
  }

  @override
  bool operator ==(Object other) {
    if (callback == other) {
      return true;
    } else if (other is _OnceListener) {
      return callback == other.callback;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => event.hashCode;
}
