part of 'websocket_impl.dart';

// ignore_for_file: strong_mode_implicit_dynamic_type
int _nextServiceId = 1;

// TODO(ajohnsen): Use other way of getting a unique id.
abstract class _ServiceObject {
  int __serviceId = 0;

  int get _serviceId {
    if (__serviceId == 0) __serviceId = _nextServiceId++;
    return __serviceId;
  }

  Map<String, dynamic> _toJSON(bool ref);

  String get _servicePath => '$_serviceTypePath/$_serviceId';

  String get _serviceTypePath;

  String get _serviceTypeName;

  String _serviceType(bool ref) {
    if (ref) return '@$_serviceTypeName';
    return _serviceTypeName;
  }
}

/// The [CompressionOptions] class allows you to control
/// the options of WebSocket compression.
class CompressionOptions {
  /// Default WebSocket Compression options.
  /// Compression will be enabled with the following options:
  /// clientNoContextTakeover: false
  /// serverNoContextTakeover: false
  /// clientMaxWindowBits: 15
  /// serverMaxWindowBits: 15
  static const CompressionOptions DEFAULT = const CompressionOptions();

  /// Disables WebSocket Compression.
  static const CompressionOptions OFF = const CompressionOptions(enabled: false);

  /// Control whether the client will reuse it's compression instances.
  final bool clientNoContextTakeover;

  /// Control whether the server will reuse it's compression instances.
  final bool serverNoContextTakeover;

  /// Sets the Max Window Bits for the Client.
  final int clientMaxWindowBits;

  /// Sets the Max Window Bits for the Server.
  final int serverMaxWindowBits;

  /// Enables or disables WebSocket compression.
  final bool enabled;

  const CompressionOptions(
      {this.clientNoContextTakeover: false,
      this.serverNoContextTakeover: false,
      this.clientMaxWindowBits,
      this.serverMaxWindowBits,
      this.enabled: true});

  /// Parses list of requested server headers to return server compression
  /// response headers. Uses [serverMaxWindowBits] value if set, otherwise will
  /// attempt to use value from headers. Defaults to
  /// [WebSocket.DEFAULT_WINDOW_BITS]. Returns a [_CompressionMaxWindowBits]
  /// object which contains the response headers and negotiated max window bits.
  _CompressionMaxWindowBits _createServerResponseHeader(HeaderValue requested) {
    final _CompressionMaxWindowBits info = new _CompressionMaxWindowBits();

    int mwb;
    String part;
    if (requested?.parameters != null) {
      part = requested.parameters[_serverMaxWindowBits];
    }
    if (part != null) {
      if (part.length >= 2 && part.startsWith('0')) {
        throw new ArgumentError('Illegal 0 padding on value.');
      } else {
        mwb = serverMaxWindowBits == null
            ? int.parse(part, onError: (String source) => WebSocketImpl.DEFAULT_WINDOW_BITS)
            : serverMaxWindowBits;
        info.headerValue = '; server_max_window_bits=$mwb';
        info.maxWindowBits = mwb;
      }
    } else {
      info.headerValue = '';
      info.maxWindowBits = WebSocketImpl.DEFAULT_WINDOW_BITS;
    }
    return info;
  }

  /// Returns default values for client compression request headers.
  String _createClientRequestHeader(HeaderValue requested, int size) {
    String info = '';

    // If responding to a valid request, specify size
    if (requested != null) {
      info = '; client_max_window_bits=$size';
    } else {
      // Client request. Specify default
      if (clientMaxWindowBits == null) {
        info = '; client_max_window_bits';
      } else {
        info = '; client_max_window_bits=$clientMaxWindowBits';
      }
      if (serverMaxWindowBits != null) {
        info += '; server_max_window_bits=$serverMaxWindowBits';
      }
    }

    return info;
  }

  /// Create a Compression Header. If [requested] is null or contains
  /// client request headers, returns Client compression request headers with
  /// default settings for `client_max_window_bits` header value.
  /// If [requested] contains server response headers this method returns
  /// a Server compression response header negotiating the max window bits
  /// for both client and server as requested server_max_window_bits value.
  /// This method returns a [_CompressionMaxWindowBits] object with the
  /// response headers and negotiated maxWindowBits value.
  _CompressionMaxWindowBits _createHeader([HeaderValue requested]) {
    final _CompressionMaxWindowBits info = new _CompressionMaxWindowBits('', 0);
    if (!enabled) {
      return info;
    }

    info.headerValue = WebSocketImpl.PER_MESSAGE_DEFLATE;

    if (clientNoContextTakeover &&
        (requested == null || (requested != null && requested.parameters.containsKey(_clientNoContextTakeover)))) {
      info.headerValue += '; client_no_context_takeover';
    }

    if (serverNoContextTakeover &&
        (requested == null || (requested != null && requested.parameters.containsKey(_serverNoContextTakeover)))) {
      info.headerValue += '; server_no_context_takeover';
    }

    final _CompressionMaxWindowBits headerList = _createServerResponseHeader(requested);
    info.headerValue += headerList.headerValue;
    info.maxWindowBits = headerList.maxWindowBits;

    info.headerValue += _createClientRequestHeader(requested, info.maxWindowBits);

    return info;
  }
}

class _StreamSinkImpl<T> implements StreamSink<T> {
  final StreamConsumer<T> _target;

  final Completer _doneCompleter = new Completer();
  StreamController<T> _controllerInstance;
  Completer _controllerCompleter;
  bool _isClosed = false;
  bool _isBound = false;
  bool _hasError = false;

  _StreamSinkImpl(this._target);

  void _reportClosedSink() {
    stderr.writeln('StreamSink is closed and adding to it is an error.');
    stderr.writeln('  See http://dartbug.com/29554.');
    stderr.writeln(StackTrace.current);
  }

  @override
  void add(T data) {
    if (_isClosed) {
      _reportClosedSink();
      return;
    }
    _controller.add(data);
  }

  @override
  void addError(dynamic error, [StackTrace stackTrace]) {
    if (_isClosed) {
      _reportClosedSink();
      return;
    }
    _controller.addError(error, stackTrace);
  }

  @override
  Future<dynamic> addStream(Stream<T> stream) {
    if (_isBound) {
      throw new StateError('StreamSink is already bound to a stream');
    }
    _isBound = true;
    if (_hasError) return done;
    // Wait for any sync operations to complete.
    Future targetAddStream() {
      return _target.addStream(stream).whenComplete(() {
        _isBound = false;
      });
    }

    if (_controllerInstance == null) return targetAddStream();
    final Future future = _controllerCompleter.future;
    _controllerInstance.close();
    return future.then<dynamic>((dynamic _) => targetAddStream());
  }

  Future<dynamic> flush() {
    if (_isBound) {
      throw new StateError('StreamSink is bound to a stream');
    }

    if (_controllerInstance == null) return new Future.value(this);
    // Adding an empty stream-controller will return a future that will complete
    // when all data is done.
    _isBound = true;
    final Future future = _controllerCompleter.future;
    _controllerInstance.close();
    return future.whenComplete(() {
      _isBound = false;
    });
  }

  @override
  Future<dynamic> close() {
    if (_isBound) {
      throw new StateError('StreamSink is bound to a stream');
    }
    if (!_isClosed) {
      _isClosed = true;
      if (_controllerInstance != null) {
        _controllerInstance.close();
      } else {
        _closeTarget();
      }
    }
    return done;
  }

  void _closeTarget() {
    _target.close().then(_completeDoneValue, onError: _completeDoneError);
  }

  @override
  Future<dynamic> get done => _doneCompleter.future;

  void _completeDoneValue(dynamic value) {
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete(value);
    }
  }

  void _completeDoneError(dynamic error, StackTrace stackTrace) {
    if (!_doneCompleter.isCompleted) {
      _hasError = true;
      _doneCompleter.completeError(error, stackTrace);
    }
  }

  StreamController<T> get _controller {
    if (_isBound) {
      throw new StateError('StreamSink is bound to a stream');
    }
    if (_isClosed) {
      throw new StateError('StreamSink is closed');
    }
    if (_controllerInstance == null) {
      _controllerInstance = new StreamController<T>(sync: true);
      _controllerCompleter = new Completer();
      _target.addStream(_controller.stream).then((dynamic _) {
        if (_isBound) {
          // A new stream takes over - forward values to that stream.
          _controllerCompleter.complete(this);
          _controllerCompleter = null;
          _controllerInstance = null;
        } else {
          // No new stream, .close was called. Close _target.
          _closeTarget();
        }
      }, onError: (dynamic error, StackTrace stackTrace) {
        if (_isBound) {
          // A new stream takes over - forward errors to that stream.
          _controllerCompleter.completeError(error, stackTrace);
          _controllerCompleter = null;
          _controllerInstance = null;
        } else {
          // No new stream. No need to close target, as it has already
          // failed.
          _completeDoneError(error, stackTrace);
        }
      });
    }
    return _controllerInstance;
  }
}
