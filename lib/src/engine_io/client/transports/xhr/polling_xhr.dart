import 'dart:async';
import 'dart:io';

import 'package:engine_io_client/src/engine_io/client/transports/polling.dart';
import 'package:engine_io_client/src/engine_io/client/transports/xhr/request_xhr.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/models/xhr_event.dart';
import 'package:engine_io_client/src/models/xhr_options.dart';

class PollingXhr extends Polling {
  static final Log log = Log('EngineIo.PollingXhr');

  PollingXhr(TransportOptions options) : super(options);

  RequestXhr request([XhrOptions options]) {
    options = options ?? XhrOptions.get(uri, null, HttpClient(context: this.options.securityContext));
    return RequestXhr(options, this.options.onResponseHeaders, this.options.onRequestHeaders);
  }

  @override
  Future<void> doWrite(dynamic data, void callback()) async {
    final XhrOptions opts = XhrOptions.post(uri, data, HttpClient(context: options.securityContext));
    final RequestXhr req = request(opts);
    req.on(XhrEvent.success, (List<dynamic> args) async => callback());

    req.on(XhrEvent.error, (List<dynamic> args) async => await onError('xhr post error', args));
    await req.create();
  }

  @override
  Future<void> doPoll() async {
    log.d('xhr poll');
    final RequestXhr req = request();
    req.on(XhrEvent.data, (List<dynamic> args) async => await onData(args.isNotEmpty ? args[0] : null));
    req.on(XhrEvent.error, (List<dynamic> args) async => await onError('xhr poll error', args));
    await req.create();
  }
}
