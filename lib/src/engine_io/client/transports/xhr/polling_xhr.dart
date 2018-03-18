import 'dart:async';

import 'package:engine_io_client/src/engine_io/client/transports/polling.dart';
import 'package:engine_io_client/src/engine_io/client/transports/xhr/request_xhr.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/transport_event.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/models/xhr_event.dart';
import 'package:engine_io_client/src/models/xhr_options.dart';
import 'package:http/http.dart';

class PollingXhr extends Polling {
  static final Log log = new Log('EngineIo.PollingXhr');

  PollingXhr(TransportOptions options) : super(options);

  RequestXhr request([XhrOptions options]) {
    options = options ?? new XhrOptions.get(uri, null, new Client());

    final RequestXhr request = new RequestXhr(options);
    request
      ..on(XhrEvent.requestHeaders.name, (List<dynamic> args) => emit(TransportEvent.requestHeaders.name, args))
      ..on(XhrEvent.responseHeaders.name, (List<dynamic> args) => emit(TransportEvent.responseHeaders.name, args));

    return request;
  }

  @override
  Future<Null> doWrite(dynamic data, void callback()) async {
    final XhrOptions opts = new XhrOptions((XhrOptionsBuilder b) {
      b
        ..method = 'POST'
        ..data = data
        ..client = new Client()
        ..uri = uri;
    });

    final RequestXhr req = request(opts);
    req.on(XhrEvent.success.name, (List<dynamic> args) => callback());

    req.on(XhrEvent.error.name, (List<dynamic> args) => onError('xhr post error', args));
    await req.create();
  }

  @override
  Future<Null> doPoll() async {
    log.d('xhr poll');
    final RequestXhr req = request();
    req.on(XhrEvent.data.name, (List<dynamic> args) => onData(args.isNotEmpty ? args[0] : null));
    req.on(XhrEvent.error.name, (List<dynamic> args) => onError('xhr poll error', args));
    await req.create();
  }
}
