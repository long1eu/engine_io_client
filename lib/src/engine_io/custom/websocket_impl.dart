// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';

part 'crypto.dart';

part 'helpers.dart';

const String _webSocketGUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
const String _clientNoContextTakeover = 'client_no_context_takeover';
const String _serverNoContextTakeover = 'server_no_context_takeover';
const String _clientMaxWindowBits = 'client_max_window_bits';
const String _serverMaxWindowBits = 'server_max_window_bits';

// Matches _WebSocketOpcode.
class _WebSocketMessageType {
  static const int NONE = 0;
  static const int TEXT = 1;
  static const int BINARY = 2;
}

class _WebSocketOpcode {
  static const int CONTINUATION = 0;
  static const int TEXT = 1;
  static const int BINARY = 2;
  static const int RESERVED_3 = 3;
  static const int RESERVED_4 = 4;
  static const int RESERVED_5 = 5;
  static const int RESERVED_6 = 6;
  static const int RESERVED_7 = 7;
  static const int CLOSE = 8;
  static const int PING = 9;
  static const int PONG = 10;
  static const int RESERVED_B = 11;
  static const int RESERVED_C = 12;
  static const int RESERVED_D = 13;
  static const int RESERVED_E = 14;
  static const int RESERVED_F = 15;
}

class _EncodedString {
  final List<int> bytes;

  _EncodedString(this.bytes);
}

/// Stores the header and integer value derived from negotiation of
/// client_max_window_bits and server_max_window_bits. headerValue will be
/// set in the Websocket response headers.
class _CompressionMaxWindowBits {
  String headerValue;
  int maxWindowBits;

  _CompressionMaxWindowBits([this.headerValue, this.maxWindowBits]);

  @override
  String toString() => headerValue;
}

/// The web socket protocol transformer handles the protocol byte stream
/// which is supplied through the `handleData`. As the protocol is processed,
/// it'll output frame data as either a List<int> or String.
///
/// Important information about usage: Be sure you use cancelOnError, so the
/// socket will be closed when the processor encounter an error. Not using it
/// will lead to undefined behaviour.
class _WebSocketProtocolTransformer extends StreamTransformerBase<List<int>, dynamic /*List<int>|_WebSocketPing|_WebSocketPong*/ >
    implements EventSink<List<int>> {
  static const int START = 0;
  static const int LEN_FIRST = 1;
  static const int LEN_REST = 2;
  static const int MASK = 3;
  static const int PAYLOAD = 4;
  static const int CLOSED = 5;
  static const int FAILURE = 6;
  static const int FIN = 0x80;
  static const int RSV1 = 0x40;
  static const int RSV2 = 0x20;
  static const int RSV3 = 0x10;
  static const int OPCODE = 0xF;

  int _state = START;
  bool _fin = false;
  bool _compressed = false;
  int _opcode = -1;
  int _len = -1;
  bool _masked = false;
  int _remainingLenBytes = -1;
  int _remainingMaskingKeyBytes = 4;
  int _remainingPayloadBytes = -1;
  int _unmaskingIndex = 0;
  int _currentMessageType = _WebSocketMessageType.NONE;
  int closeCode = WebSocketStatus.noStatusReceived;
  String closeReason = '';

  EventSink<dynamic /*List<int>|_WebSocketPing|_WebSocketPong*/ > _eventSink;

  final bool _serverSide;
  final List<int> _maskingBytes = List<int>(4);
  final BytesBuilder _payload = BytesBuilder(copy: false);

  _WebSocketPerMessageDeflate _deflate;

  _WebSocketProtocolTransformer([this._serverSide = false, this._deflate]);

  @override
  Stream<dynamic /*List<int>|_WebSocketPing|_WebSocketPong*/ > bind(Stream<List<int>> stream) {
    return Stream<dynamic>.eventTransformed(stream, (EventSink<dynamic> eventSink) {
      if (_eventSink != null) {
        throw StateError('WebSocket transformer already used.');
      }
      _eventSink = eventSink;
      return this;
    });
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    _eventSink.addError(error, stackTrace);
  }

  @override
  void close() {
    _eventSink.close();
  }

  /// Process data received from the underlying communication channel.
  @override
  void add(List<int> bytes) {
    final Uint8List buffer = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    int index = 0;
    final int lastIndex = buffer.length;
    if (_state == CLOSED) {
      throw const WebSocketException('Data on closed connection');
    }
    if (_state == FAILURE) {
      throw const WebSocketException('Data on failed connection');
    }
    while ((index < lastIndex) && _state != CLOSED && _state != FAILURE) {
      final int byte = buffer[index];
      if (_state <= LEN_REST) {
        if (_state == START) {
          _fin = (byte & FIN) != 0;

          if ((byte & (RSV2 | RSV3)) != 0) {
            // The RSV2, RSV3 bits must both be zero.
            throw const WebSocketException('Protocol error');
          }

          _opcode = byte & OPCODE;

          if (_opcode != _WebSocketOpcode.CONTINUATION) {
            if ((byte & RSV1) != 0) {
              _compressed = true;
            } else {
              _compressed = false;
            }
          }

          if (_opcode <= _WebSocketOpcode.BINARY) {
            if (_opcode == _WebSocketOpcode.CONTINUATION) {
              if (_currentMessageType == _WebSocketMessageType.NONE) {
                throw const WebSocketException('Protocol error');
              }
            } else {
              assert(_opcode == _WebSocketOpcode.TEXT || _opcode == _WebSocketOpcode.BINARY);
              if (_currentMessageType != _WebSocketMessageType.NONE) {
                throw const WebSocketException('Protocol error');
              }
              _currentMessageType = _opcode;
            }
          } else if (_opcode >= _WebSocketOpcode.CLOSE && _opcode <= _WebSocketOpcode.PONG) {
            // Control frames cannot be fragmented.
            if (!_fin) throw const WebSocketException('Protocol error');
          } else {
            throw const WebSocketException('Protocol error');
          }
          _state = LEN_FIRST;
        } else if (_state == LEN_FIRST) {
          _masked = (byte & 0x80) != 0;
          _len = byte & 0x7F;
          if (_isControlFrame() && _len > 125) {
            throw const WebSocketException('Protocol error');
          }
          if (_len == 126) {
            _len = 0;
            _remainingLenBytes = 2;
            _state = LEN_REST;
          } else if (_len == 127) {
            _len = 0;
            _remainingLenBytes = 8;
            _state = LEN_REST;
          } else {
            assert(_len < 126);
            _lengthDone();
          }
        } else {
          assert(_state == LEN_REST);
          _len = _len << 8 | byte;
          _remainingLenBytes--;
          if (_remainingLenBytes == 0) {
            _lengthDone();
          }
        }
      } else {
        if (_state == MASK) {
          _maskingBytes[4 - _remainingMaskingKeyBytes--] = byte;
          if (_remainingMaskingKeyBytes == 0) {
            _maskDone();
          }
        } else {
          assert(_state == PAYLOAD);
          // The payload is not handled one byte at a time but in blocks.
          final int payloadLength = min(lastIndex - index, _remainingPayloadBytes);
          _remainingPayloadBytes -= payloadLength;
          // Unmask payload if masked.
          if (_masked) {
            _unmask(index, payloadLength, buffer);
          }
          // Control frame and data frame share _payloads.
          _payload.add(Uint8List.view(buffer.buffer, index, payloadLength));
          index += payloadLength;
          if (_isControlFrame()) {
            if (_remainingPayloadBytes == 0) _controlFrameEnd();
          } else {
            if (_currentMessageType != _WebSocketMessageType.TEXT && _currentMessageType != _WebSocketMessageType.BINARY) {
              throw const WebSocketException('Protocol error');
            }
            if (_remainingPayloadBytes == 0) _messageFrameEnd();
          }

          // Hack - as we always do index++ below.
          index--;
        }
      }

      // Move to the next byte.
      index++;
    }
  }

  void _unmask(int index, int length, Uint8List buffer) {
    const int BLOCK_SIZE = 16;
    // Skip Int32x4-version if message is small.
    if (length >= BLOCK_SIZE) {
      // Start by aligning to 16 bytes.
      final int startOffset = BLOCK_SIZE - (index & 15);
      final int end = index + startOffset;
      for (int i = index; i < end; i++) {
        buffer[i] ^= _maskingBytes[_unmaskingIndex++ & 3];
      }
      index += startOffset;
      length -= startOffset;
      final int blockCount = length ~/ BLOCK_SIZE;
      if (blockCount > 0) {
        // Create mask block.
        int mask = 0;
        for (int i = 3; i >= 0; i--) {
          mask = (mask << 8) | _maskingBytes[(_unmaskingIndex + i) & 3];
        }
        final Int32x4 blockMask = Int32x4(mask, mask, mask, mask);
        final Int32x4List blockBuffer = Int32x4List.view(buffer.buffer, index, blockCount);
        for (int i = 0; i < blockBuffer.length; i++) {
          blockBuffer[i] ^= blockMask;
        }
        final int bytes = blockCount * BLOCK_SIZE;
        index += bytes;
        length -= bytes;
      }
    }
    // Handle end.
    final int end = index + length;
    for (int i = index; i < end; i++) {
      buffer[i] ^= _maskingBytes[_unmaskingIndex++ & 3];
    }
  }

  void _lengthDone() {
    if (_masked) {
      if (!_serverSide) {
        throw const WebSocketException('Received masked frame from server');
      }
      _state = MASK;
    } else {
      if (_serverSide) {
        throw const WebSocketException('Received unmasked frame from client');
      }
      _remainingPayloadBytes = _len;
      _startPayload();
    }
  }

  void _maskDone() {
    _remainingPayloadBytes = _len;
    _startPayload();
  }

  void _startPayload() {
    // If there is no actual payload perform perform callbacks without
    // going through the PAYLOAD state.
    if (_remainingPayloadBytes == 0) {
      if (_isControlFrame()) {
        switch (_opcode) {
          case _WebSocketOpcode.CLOSE:
            _state = CLOSED;
            _eventSink.close();
            break;
          case _WebSocketOpcode.PING:
            _eventSink.add(_WebSocketPing());
            break;
          case _WebSocketOpcode.PONG:
            _eventSink.add(_WebSocketPong());
            break;
        }
        _prepareForNextFrame();
      } else {
        _messageFrameEnd();
      }
    } else {
      _state = PAYLOAD;
    }
  }

  void _messageFrameEnd() {
    if (_fin) {
      List<int> bytes = _payload.takeBytes();
      if (_deflate != null && _compressed) {
        bytes = _deflate.processIncomingMessage(bytes);
      }

      switch (_currentMessageType) {
        case _WebSocketMessageType.TEXT:
          _eventSink.add(utf8.decode(bytes));
          break;
        case _WebSocketMessageType.BINARY:
          _eventSink.add(bytes);
          break;
      }
      _currentMessageType = _WebSocketMessageType.NONE;
    }
    _prepareForNextFrame();
  }

  void _controlFrameEnd() {
    switch (_opcode) {
      case _WebSocketOpcode.CLOSE:
        closeCode = WebSocketStatus.noStatusReceived;
        final List<int> payload = _payload.takeBytes();
        if (payload.isNotEmpty) {
          if (payload.length == 1) {
            throw const WebSocketException('Protocol error');
          }
          closeCode = payload[0] << 8 | payload[1];
          if (closeCode == WebSocketStatus.noStatusReceived) {
            throw const WebSocketException('Protocol error');
          }
          if (payload.length > 2) {
            closeReason = utf8.decode(payload.sublist(2));
          }
        }
        _state = CLOSED;
        _eventSink.close();
        break;

      case _WebSocketOpcode.PING:
        _eventSink.add(_WebSocketPing(_payload.takeBytes()));
        break;

      case _WebSocketOpcode.PONG:
        _eventSink.add(_WebSocketPong(_payload.takeBytes()));
        break;
    }
    _prepareForNextFrame();
  }

  bool _isControlFrame() {
    return _opcode == _WebSocketOpcode.CLOSE || _opcode == _WebSocketOpcode.PING || _opcode == _WebSocketOpcode.PONG;
  }

  void _prepareForNextFrame() {
    if (_state != CLOSED && _state != FAILURE) _state = START;
    _fin = false;
    _opcode = -1;
    _len = -1;
    _remainingLenBytes = -1;
    _remainingMaskingKeyBytes = 4;
    _remainingPayloadBytes = -1;
    _unmaskingIndex = 0;
  }
}

class _WebSocketPing {
  final List<int> payload;

  _WebSocketPing([this.payload]);
}

class _WebSocketPong {
  final List<int> payload;

  _WebSocketPong([this.payload]);
}

class _WebSocketPerMessageDeflate {
  bool serverNoContextTakeover;
  bool clientNoContextTakeover;
  int clientMaxWindowBits;
  int serverMaxWindowBits;
  bool serverSide;

  RawZLibFilter decoder;
  RawZLibFilter encoder;

  _WebSocketPerMessageDeflate(
      {this.clientMaxWindowBits: _WebSocketImpl.DEFAULT_WINDOW_BITS,
      this.serverMaxWindowBits: _WebSocketImpl.DEFAULT_WINDOW_BITS,
      this.serverNoContextTakeover: false,
      this.clientNoContextTakeover: false,
      this.serverSide: false});

  void _ensureDecoder() {
    decoder ??= RawZLibFilter.inflateFilter(windowBits: serverSide ? clientMaxWindowBits : serverMaxWindowBits, raw: true);
  }

  void _ensureEncoder() {
    encoder ??= RawZLibFilter.deflateFilter(windowBits: serverSide ? serverMaxWindowBits : clientMaxWindowBits, raw: true);
  }

  Uint8List processIncomingMessage(List<int> msg) {
    _ensureDecoder();

    final List<int> data = <int>[];
    data.addAll(msg);
    data.addAll(const <int>[0x00, 0x00, 0xff, 0xff]);

    decoder.process(data, 0, data.length);
    final List<int> result = <int>[];
    List<int> out;

    while ((out = decoder.processed()) != null) {
      result.addAll(out);
    }

    if ((serverSide && clientNoContextTakeover) || (!serverSide && serverNoContextTakeover)) {
      decoder = null;
    }

    return Uint8List.fromList(result);
  }

  List<int> processOutgoingMessage(List<int> msg) {
    _ensureEncoder();
    List<int> result = <int>[];
    Uint8List buffer;

    if (msg is! Uint8List) {
      for (int i = 0; i < msg.length; i++) {
        if (msg[i] < 0 || 255 < msg[i]) {
          throw ArgumentError('List element is not a byte value '
              '(value ${msg[i]} at index $i)');
        }
      }
      buffer = Uint8List.fromList(msg);
    } else {
      buffer = msg as Uint8List;
    }

    encoder.process(buffer, 0, buffer.length);

    List<int> out;
    while ((out = encoder.processed()) != null) {
      result.addAll(out);
    }

    if ((!serverSide && clientNoContextTakeover) || (serverSide && serverNoContextTakeover)) {
      encoder = null;
    }

    if (result.length > 4) {
      result = result.sublist(0, result.length - 4);
    }

    return result;
  }
}

// TODO(ajohnsen): Make this transformer reusable.
class _WebSocketOutgoingTransformer extends StreamTransformerBase<dynamic, List<int>> implements EventSink<dynamic> {
  final _WebSocketImpl webSocket;
  EventSink<List<int>> _eventSink;

  _WebSocketPerMessageDeflate _deflateHelper;

  _WebSocketOutgoingTransformer(this.webSocket) {
    _deflateHelper = webSocket._deflate;
  }

  @override
  Stream<List<int>> bind(Stream<dynamic> stream) {
    return Stream<List<int>>.eventTransformed(stream, (EventSink<List<int>> eventSink) {
      if (_eventSink != null) {
        throw StateError('WebSocket transformer already used');
      }
      _eventSink = eventSink;
      return this;
    });
  }

  @override
  void add(dynamic message) {
    if (message is _WebSocketPong) {
      addFrame(_WebSocketOpcode.PONG, message.payload);
      return;
    }
    if (message is _WebSocketPing) {
      addFrame(_WebSocketOpcode.PING, message.payload);
      return;
    }
    List<int> data;
    int opcode;
    if (message != null) {
      if (message is String) {
        opcode = _WebSocketOpcode.TEXT;
        data = utf8.encode(message);
      } else if (message is List<int>) {
        opcode = _WebSocketOpcode.BINARY;
        data = message;
      } else if (message is _EncodedString) {
        opcode = _WebSocketOpcode.TEXT;
        data = message.bytes;
      } else {
        throw ArgumentError(message);
      }

      if (_deflateHelper != null) {
        data = _deflateHelper.processOutgoingMessage(data);
      }
    } else {
      opcode = _WebSocketOpcode.TEXT;
    }
    addFrame(opcode, data);
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    _eventSink.addError(error, stackTrace);
  }

  @override
  void close() {
    final int code = webSocket._outCloseCode;
    final String reason = webSocket._outCloseReason;
    List<int> data;
    if (code != null) {
      data = <int>[];
      data.add((code >> 8) & 0xFF);
      data.add(code & 0xFF);
      if (reason != null) {
        data.addAll(utf8.encode(reason));
      }
    }
    addFrame(_WebSocketOpcode.CLOSE, data);
    _eventSink.close();
  }

  void addFrame(int opcode, List<int> data) {
    createFrame(opcode, data, webSocket._serverSide,
            _deflateHelper != null && (opcode == _WebSocketOpcode.TEXT || opcode == _WebSocketOpcode.BINARY))
        .forEach(_eventSink.add);
  }

  static Iterable<List<int>> createFrame(int opcode, List<int> data, bool serverSide, bool compressed) {
    final bool mask = !serverSide; // Masking not implemented for server.
    final int dataLength = data == null ? 0 : data.length;
    // Determine the header size.
    int headerSize = mask ? 6 : 2;
    if (dataLength > 65535) {
      headerSize += 8;
    } else if (dataLength > 125) {
      headerSize += 2;
    }
    final Uint8List header = Uint8List(headerSize);
    int index = 0;

    // Set FIN and opcode.
    final int hoc = _WebSocketProtocolTransformer.FIN |
        (compressed ? _WebSocketProtocolTransformer.RSV1 : 0) |
        (opcode & _WebSocketProtocolTransformer.OPCODE);

    header[index++] = hoc;
    // Determine size and position of length field.
    int lengthBytes = 1;
    if (dataLength > 65535) {
      header[index++] = 127;
      lengthBytes = 8;
    } else if (dataLength > 125) {
      header[index++] = 126;
      lengthBytes = 2;
    }
    // Write the length in network byte order into the header.
    for (int i = 0; i < lengthBytes; i++) {
      header[index++] = dataLength >> (((lengthBytes - 1) - i) * 8) & 0xFF;
    }
    if (mask) {
      header[1] |= 1 << 7;
      final Uint8List maskBytes = _CryptoUtils.getRandomBytes(4);
      header.setRange(index, index + 4, maskBytes);
      index += 4;
      if (data != null) {
        Uint8List list;
        // If this is a text message just do the masking inside the
        // encoded data.
        if (opcode == _WebSocketOpcode.TEXT && data is Uint8List) {
          list = data;
        } else {
          if (data is Uint8List) {
            list = Uint8List.fromList(data);
          } else {
            list = Uint8List(data.length);
            for (int i = 0; i < data.length; i++) {
              if (data[i] < 0 || 255 < data[i]) {
                throw ArgumentError('List element is not a byte value '
                    '(value ${data[i]} at index $i)');
              }
              list[i] = data[i];
            }
          }
        }
        const int BLOCK_SIZE = 16;
        final int blockCount = list.length ~/ BLOCK_SIZE;
        if (blockCount > 0) {
          // Create mask block.
          int mask = 0;
          for (int i = 3; i >= 0; i--) {
            mask = (mask << 8) | maskBytes[i];
          }
          final Int32x4 blockMask = Int32x4(mask, mask, mask, mask);
          final Int32x4List blockBuffer = Int32x4List.view(list.buffer, 0, blockCount);
          for (int i = 0; i < blockBuffer.length; i++) {
            blockBuffer[i] ^= blockMask;
          }
        }
        // Handle end.
        for (int i = blockCount * BLOCK_SIZE; i < list.length; i++) {
          list[i] ^= maskBytes[i & 3];
        }
        data = list;
      }
    }
    assert(index == headerSize);
    if (data == null) {
      return <Uint8List>[header];
    } else {
      return <List<int>>[header, data];
    }
  }
}

class _WebSocketConsumer implements StreamConsumer<dynamic> {
  final _WebSocketImpl webSocket;
  final Socket socket;
  StreamController<dynamic> _controller;
  StreamSubscription<dynamic> _subscription;
  bool _issuedPause = false;
  bool _closed = false;
  final Completer<WebSocket> _closeCompleter = Completer<WebSocket>();
  Completer<WebSocket> _completer;

  _WebSocketConsumer(this.webSocket, this.socket);

  void _onListen() {
    if (_subscription != null) {
      _subscription.cancel();
    }
  }

  void _onPause() {
    if (_subscription != null) {
      _subscription.pause();
    } else {
      _issuedPause = true;
    }
  }

  void _onResume() {
    if (_subscription != null) {
      _subscription.resume();
    } else {
      _issuedPause = false;
    }
  }

  void _cancel() {
    if (_subscription != null) {
      final StreamSubscription<dynamic> subscription = _subscription;
      _subscription = null;
      subscription.cancel();
    }
  }

  void _ensureController() {
    if (_controller != null) return;
    _controller = StreamController<dynamic>(sync: true, onPause: _onPause, onResume: _onResume, onCancel: _onListen);
    final Stream<List<int>> stream = _controller.stream.transform(_WebSocketOutgoingTransformer(webSocket));
    socket.addStream(stream).then((_) {
      _done();
      _closeCompleter.complete(webSocket);
    }, onError: (dynamic error, StackTrace stackTrace) {
      _closed = true;
      _cancel();
      if (error is ArgumentError) {
        if (!_done(error, stackTrace)) {
          _closeCompleter.completeError(error, stackTrace);
        }
      } else {
        _done();
        _closeCompleter.complete(webSocket);
      }
    });
  }

  bool _done([dynamic error, StackTrace stackTrace]) {
    if (_completer == null) return false;
    if (error != null) {
      _completer.completeError(error, stackTrace);
    } else {
      _completer.complete(webSocket);
    }
    _completer = null;
    return true;
  }

  @override
  Future<WebSocket> addStream(Stream<dynamic> stream) {
    if (_closed) {
      stream.listen(null).cancel();
      return Future<WebSocket>.value(webSocket);
    }
    _ensureController();
    _completer = Completer<WebSocket>();
    _subscription = stream.listen((dynamic data) {
      _controller.add(data);
    }, onDone: _done, onError: _done, cancelOnError: true);
    if (_issuedPause) {
      _subscription.pause();
      _issuedPause = false;
    }
    return _completer.future;
  }

  @override
  Future<WebSocket> close() {
    _ensureController();
    Future<WebSocket> closeSocket() {
      return socket.close().catchError((_) {}).then((_) => webSocket);
    }

    _controller.close();
    return _closeCompleter.future.then((_) => closeSocket());
  }

  void add(dynamic data) {
    if (_closed) return;
    _ensureController();
    _controller.add(data);
  }

  void closeSocket() {
    _closed = true;
    _cancel();
    close();
  }
}

typedef Map<String, String> OnRequestHeaders(Map<String, String> headers);
typedef void OnResponseHeaders(Map<String, String> headers);

class QwilWebSocket {
  static Future<WebSocket> connect(
    String url, {
    Iterable<String> protocols,
    CompressionOptions compression: CompressionOptions.compressionDefault,
    HttpClient httpClient,
    CookieJar cookieJar,
    OnResponseHeaders onResponseHeaders,
    OnRequestHeaders onRequestHeaders,
  }) async {
    return _WebSocketImpl.connect(url,
        protocols: protocols,
        compression: compression,
        httpClient: httpClient,
        cookieJar: cookieJar,
        onResponseHeaders: onResponseHeaders,
        onRequestHeaders: onRequestHeaders);
  }
}

class _WebSocketImpl extends Stream<dynamic> with _ServiceObject implements WebSocket {
  // Use default Map so we keep order.
  static final Map<int, _WebSocketImpl> _webSockets = <int, _WebSocketImpl>{};
  static final Map<int, HttpClient> _httpClients = <int, HttpClient>{};

  static const int DEFAULT_WINDOW_BITS = 15;
  static const String PER_MESSAGE_DEFLATE = 'permessage-deflate';

  @override
  final String protocol;

  StreamController<dynamic> _controller;
  StreamSubscription<dynamic> _subscription;
  StreamSink<dynamic> _sink;

  final Socket _socket;
  final bool _serverSide;
  int _readyState = WebSocket.connecting;
  bool _writeClosed = false;
  int _closeCode;
  String _closeReason;
  Duration _pingInterval;
  Timer _pingTimer;
  _WebSocketConsumer _consumer;

  int _outCloseCode;
  String _outCloseReason;
  Timer _closeTimer;
  _WebSocketPerMessageDeflate _deflate;

  _WebSocketImpl._fromSocket(
    this._socket,
    this.protocol,
    CompressionOptions compression, [
    this._serverSide = false,
    _WebSocketPerMessageDeflate deflate,
  ]) {
    _consumer = _WebSocketConsumer(this, _socket);
    _sink = _StreamSinkImpl<dynamic>(_consumer);
    _readyState = WebSocket.open;
    _deflate = deflate;

    final _WebSocketProtocolTransformer transformer = _WebSocketProtocolTransformer(_serverSide, _deflate);
    _subscription = _socket.transform(transformer).listen((dynamic data) {
      if (data is _WebSocketPing) {
        if (!_writeClosed) _consumer.add(_WebSocketPong(data.payload));
      } else if (data is _WebSocketPong) {
        // Simply set pingInterval, as it'll cancel any timers.
        pingInterval = _pingInterval;
      } else {
        _controller.add(data);
      }
    }, onError: (dynamic error, StackTrace stackTrace) {
      if (_closeTimer != null) _closeTimer.cancel();
      if (error is FormatException) {
        _close(WebSocketStatus.invalidFramePayloadData);
      } else {
        _close(WebSocketStatus.protocolError);
      }
      // An error happened, set the close code set above.
      _closeCode = _outCloseCode;
      _closeReason = _outCloseReason;
      _controller.close();
    }, onDone: () {
      if (_closeTimer != null) _closeTimer.cancel();
      if (_readyState == WebSocket.open) {
        _readyState = WebSocket.closing;
        if (!_isReservedStatusCode(transformer.closeCode)) {
          _close(transformer.closeCode, transformer.closeReason);
        } else {
          _close();
        }
        _readyState = WebSocket.closed;
      }
      // Protocol close, use close code from transformer.
      _closeCode = transformer.closeCode;
      _closeReason = transformer.closeReason;
      _controller.close();
    }, cancelOnError: true);
    _subscription.pause();
    _controller = StreamController<dynamic>(
      sync: true,
      onListen: _subscription.resume,
      onCancel: () {
        _subscription.cancel();
        _subscription = null;
      },
      onPause: _subscription.pause,
      onResume: _subscription.resume,
    );

    _webSockets[_serviceId] = this;
  }

  static Future<WebSocket> connect(
    String url, {
    Iterable<String> protocols,
    CompressionOptions compression: CompressionOptions.compressionDefault,
    HttpClient httpClient,
    CookieJar cookieJar,
    OnResponseHeaders onResponseHeaders,
    OnRequestHeaders onRequestHeaders,
  }) {
    cookieJar ??= PersistCookieJar();
    Uri uri = Uri.parse(url);
    print(uri);
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      throw WebSocketException('Unsupported URL scheme "${uri.scheme}"');
    }

    final Random random = Random();
    // Generate 16 random bytes.
    final Uint8List nonceData = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      nonceData[i] = random.nextInt(256);
    }
    final String nonce = _CryptoUtils.bytesToBase64(nonceData);

    uri = Uri(
        scheme: uri.scheme == 'wss' ? 'https' : 'http',
        userInfo: uri.userInfo,
        host: uri.host,
        port: uri.port,
        path: uri.path,
        query: uri.query,
        fragment: uri.fragment);
    httpClient ??= HttpClient();

    return httpClient.openUrl('GET', uri).then((HttpClientRequest request) {
      // Setup the initial handshake.
      Map<String, String> headers = <String, String>{
        HttpHeaders.connectionHeader: 'Upgrade',
        HttpHeaders.upgradeHeader: 'websocket',
        'Sec-WebSocket-Key': nonce,
        'Cache-Control': 'no-cache',
        'Sec-WebSocket-Version': '13',
      };

      if (uri.userInfo != null && uri.userInfo.isNotEmpty) {
        // If the URL contains user information use that for basic
        // authorization.
        final String auth = _CryptoUtils.bytesToBase64(utf8.encode(uri.userInfo));
        headers[HttpHeaders.authorizationHeader] = 'Basic $auth';
      }

      headers = onRequestHeaders?.call(headers) ?? headers;
      headers.forEach((String key, dynamic value) => request.headers.add(key, value));

      if (compression.enabled) {
        request.headers.add('Sec-WebSocket-Extensions', compression._createHeader());
      }

      if (protocols != null) {
        request.headers.add('Sec-WebSocket-Protocol', protocols.toList());
      }

      request.cookies.addAll(cookieJar.loadForRequest(uri));

      return request.close();
    }).then((HttpClientResponse response) {
      void error(String message) {
        // Flush data.
        response.detachSocket().then((Socket socket) {
          socket.destroy();
        });
        throw WebSocketException(message);
      }

      cookieJar.saveFromResponse(uri, response.cookies);
      final Map<String, String> headers = <String, String>{};
      response.headers.forEach((String key, List<String> value) => headers[key] = value.join(','));
      onResponseHeaders?.call(headers);

      if (response.statusCode != HttpStatus.switchingProtocols ||
          response.headers[HttpHeaders.connectionHeader] == null ||
          !response.headers[HttpHeaders.connectionHeader].any((String value) => value.toLowerCase() == 'upgrade') ||
          response.headers.value(HttpHeaders.upgradeHeader).toLowerCase() != 'websocket') {
        error('Connection to "$uri" was not upgraded to websocket');
      }
      final String accept = response.headers.value('Sec-WebSocket-Accept');
      if (accept == null) {
        error('Response did not contain a "Sec-WebSocket-Accept" header');
      }
      final _SHA1 sha1 = _SHA1();
      sha1.add('$nonce$_webSocketGUID'.codeUnits);
      final List<int> expectedAccept = sha1.close();
      final List<int> receivedAccept = _CryptoUtils.base64StringToBytes(accept);
      if (expectedAccept.length != receivedAccept.length) {
        error('Reasponse header "Sec-WebSocket-Accept" is the wrong length');
      }
      for (int i = 0; i < expectedAccept.length; i++) {
        if (expectedAccept[i] != receivedAccept[i]) {
          error('Bad response "Sec-WebSocket-Accept" header');
        }
      }
      final String protocol = response.headers.value('Sec-WebSocket-Protocol');

      final _WebSocketPerMessageDeflate deflate = negotiateClientCompression(response, compression);

      return response.detachSocket().then<WebSocket>((Socket socket) {
        final _WebSocketImpl wsi = _WebSocketImpl._fromSocket(socket, protocol, compression, false, deflate);
        _httpClients[wsi._serviceId] = httpClient;
        return wsi;
      });
    });
  }

  static _WebSocketPerMessageDeflate negotiateClientCompression(HttpClientResponse response, CompressionOptions compression) {
    String extensionHeader = response.headers.value('Sec-WebSocket-Extensions');

    extensionHeader ??= '';

    final HeaderValue hv = HeaderValue.parse(extensionHeader, valueSeparator: ',');

    if (compression.enabled && hv.value == PER_MESSAGE_DEFLATE) {
      final bool serverNoContextTakeover = hv.parameters.containsKey(_serverNoContextTakeover);
      final bool clientNoContextTakeover = hv.parameters.containsKey(_clientNoContextTakeover);

      int getWindowBits(String type) {
        final String o = hv.parameters[type];
        if (o == null) {
          return DEFAULT_WINDOW_BITS;
        }

        return int.tryParse(o) ?? DEFAULT_WINDOW_BITS;
      }

      return _WebSocketPerMessageDeflate(
          clientMaxWindowBits: getWindowBits(_clientMaxWindowBits),
          serverMaxWindowBits: getWindowBits(_serverMaxWindowBits),
          clientNoContextTakeover: clientNoContextTakeover,
          serverNoContextTakeover: serverNoContextTakeover);
    }

    return null;
  }

  @override
  StreamSubscription<dynamic> listen(void onData(dynamic message), {Function onError, void onDone(), bool cancelOnError}) {
    return _controller.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  Duration get pingInterval => _pingInterval;

  @override
  set pingInterval(Duration interval) {
    if (_writeClosed) return;
    if (_pingTimer != null) _pingTimer.cancel();
    _pingInterval = interval;

    if (_pingInterval == null) return;

    _pingTimer = Timer(_pingInterval, () {
      if (_writeClosed) return;
      _consumer.add(_WebSocketPing());
      _pingTimer = Timer(_pingInterval, () {
        // No pong received.
        _close(WebSocketStatus.goingAway);
      });
    });
  }

  @override
  int get readyState => _readyState;

  @override
  String get extensions => null;

  @override
  int get closeCode => _closeCode;

  @override
  String get closeReason => _closeReason;

  @override
  void add(dynamic data) {
    _sink.add(data);
  }

  @override
  void addUtf8Text(List<int> bytes) {
    if (bytes is! List<int>) {
      throw ArgumentError.value(bytes, 'bytes', 'Is not a list of bytes');
    }
    _sink.add(_EncodedString(bytes));
  }

  @override
  void addError(dynamic error, [StackTrace stackTrace]) {
    _sink.addError(error, stackTrace);
  }

  @override
  Future<dynamic> addStream(Stream<dynamic> stream) => _sink.addStream(stream);

  @override
  Future<dynamic> get done => _sink.done;

  @override
  Future<dynamic> close([int code, String reason]) {
    if (_isReservedStatusCode(code)) {
      throw WebSocketException('Reserved status code $code');
    }
    if (_outCloseCode == null) {
      _outCloseCode = code;
      _outCloseReason = reason;
    }
    if (!_controller.isClosed) {
      // If a close has not yet been received from the other end then
      //   1) make sure to listen on the stream so the close frame will be
      //      processed if received.
      //   2) set a timer terminate the connection if a close frame is
      //      not received.
      if (!_controller.hasListener && _subscription != null) {
        _controller.stream.drain().catchError((dynamic _) {});
      }
      _closeTimer ??= Timer(const Duration(seconds: 5), () {
        // Reuse code and reason from the local close.
        _closeCode = _outCloseCode;
        _closeReason = _outCloseReason;
        if (_subscription != null) _subscription.cancel();
        _controller.close();
        _webSockets.remove(_serviceId);
      });
    }
    return _sink.close();
  }

  String get userAgent => _httpClients[_serviceId].userAgent;

  set userAgent(String userAgent) {
    _httpClients[_serviceId].userAgent = userAgent;
  }

  void _close([int code, String reason]) {
    if (_writeClosed) return;
    if (_outCloseCode == null) {
      _outCloseCode = code;
      _outCloseReason = reason;
    }
    _writeClosed = true;
    _consumer.closeSocket();
    _webSockets.remove(_serviceId);
    _httpClients.remove(_serviceId);
  }

  @override
  String get _serviceTypePath => 'io/websockets';

  @override
  String get _serviceTypeName => 'WebSocket';

  @override
  Map<String, dynamic> _toJSON(bool ref) {
    final String name = '${_socket.address.host}:${_socket.port}';
    final Map<String, dynamic> r = <String, dynamic>{
      'id': _servicePath,
      'type': _serviceType(ref),
      'name': name,
      'user_name': name,
    };
    if (ref) {
      return r;
    }
    try {
      r['socket'] = _socket.toString();
    } catch (_) {
      r['socket'] = <String, dynamic>{
        'id': _servicePath,
        'type': '@Socket',
        'name': 'UserSocket',
        'user_name': 'UserSocket',
      };
    }
    return r;
  }

  static bool _isReservedStatusCode(int code) {
    return code != null &&
        (code < WebSocketStatus.normalClosure ||
            code == WebSocketStatus.reserved1004 ||
            code == WebSocketStatus.noStatusReceived ||
            code == WebSocketStatus.abnormalClosure ||
            (code > WebSocketStatus.internalServerError && code < WebSocketStatus.reserved1015) ||
            (code >= WebSocketStatus.reserved1015 && code < 3000));
  }
}
