library engine_io_client;

export 'package:cookie_jar/cookie_jar.dart';

export 'src/emitter/emitter.dart';
export 'src/engine_io/client/engine_io_error.dart';
export 'src/engine_io/client/socket.dart';
export 'src/engine_io/client/transport.dart';
export 'src/engine_io/custom/websocket_impl.dart';
export 'src/engine_io/parser/parser.dart';
export 'src/models/packet.dart';
export 'src/models/socket_options.dart';
export 'src/models/transport_options.dart';

class LoggerOptions {
  static bool shouldLog = true;
}
