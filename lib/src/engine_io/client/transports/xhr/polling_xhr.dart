import 'dart:async';
import 'dart:io';

import 'package:engine_io_client/src/engine_io/client/transport.dart';
import 'package:engine_io_client/src/engine_io/client/transports/polling.dart';
import 'package:engine_io_client/src/engine_io/client/transports/xhr/request_xhr.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/models/xhr_options.dart';

class PollingXhr extends Polling {
  static final Log log = new Log('EngineIo.PollingXhr');

  PollingXhr(TransportOptions options) : super(options);

  RequestXhr request([XhrOptions options]) {
    options = options ?? new XhrOptions(uri: uri, client: new HttpClient(context: this.options.securityContext));

    final RequestXhr request = new RequestXhr(options);
    request
      ..on(RequestXhr.eventRequestHeaders, (List<dynamic> args) async => await emit(Transport.eventRequestHeaders, args))
      ..on(RequestXhr.eventResponseHeaders, (List<dynamic> args) async => await emit(Transport.eventResponseHeaders, args));

    return request;
  }

  @override
  Future<Null> doWrite(dynamic data, void callback()) async {
    final XhrOptions opts = new XhrOptions(
      method: 'POST',
      data: data,
      client: new HttpClient(context: options.securityContext),
      uri: uri,
    );

    final RequestXhr req = request(opts);
    req.on(RequestXhr.eventSuccess, (List<dynamic> args) async => callback());

    req.on(RequestXhr.eventError, (List<dynamic> args) async => await onError('xhr post error', args));
    await req.create();
  }

  @override
  Future<Null> doPoll() async {
    log.d('xhr poll');
    final RequestXhr req = request();
    req.on(RequestXhr.eventData, (List<dynamic> args) async => await onData(args.isNotEmpty ? args[0] : null));
    req.on(RequestXhr.eventError, (List<dynamic> args) async => await onError('xhr poll error', args));
    await req.create();
  }
}
