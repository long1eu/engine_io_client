import 'package:flutter_logger/flutter_logger.dart';
import 'package:http/http.dart';
import 'package:socket_io/src/emitter/emitter.dart';
import 'package:socket_io/src/engine_io/client/transports/polling.dart';
import 'package:socket_io/src/engine_io/client/transports/xhr/xhr_request.dart';
import 'package:socket_io/src/models/transport_event.dart';
import 'package:socket_io/src/models/transport_options.dart';
import 'package:socket_io/src/models/xhr_event.dart';
import 'package:socket_io/src/models/xhr_options.dart';

class PollingXhr extends Polling {
  static final Log log = new Log('PollingXhr');

  PollingXhr(TransportOptions options) : super(options);

  XhrRequest request([XhrOptions<dynamic> options]) {
    options = options ?? new XhrOptions<dynamic>.get(uri, null, new Client());

    final XhrRequest request = new XhrRequest(options);
    request.on(XhrEvent.requestHeaders.name, new Listener.callback((dynamic args) {
      emit(TransportEvent.requestHeaders.name, args);
    })).on(XhrEvent.responseHeaders.name, new Listener.callback((dynamic args) {
      emit(TransportEvent.responseHeaders.name, args);
    }));

    return request;
  }

  @override
  void doWrite(dynamic data, void callback()) {
    final XhrOptions<dynamic> opts = new XhrOptions<dynamic>((b) {
      b
        ..method = 'POST'
        ..data = data
        ..client = new Client();
    });

    final XhrRequest req = request(opts);
    req.on(XhrEvent.success.name, new Listener.callback((dynamic args) {
      callback();
    }));

    req.on(XhrEvent.error.name, new Listener.callback((dynamic args) {
      onError('xhr post error', args);
    }));
    req.create();
  }

  @override
  void doPoll() {
    log.d('xhr poll');
    final XhrRequest req = request();
    req.on(XhrEvent.data.name, new Listener.callback((dynamic args) => onData(args)));
    req.on(XhrEvent.error.name, new Listener.callback((dynamic args) => onError('xhr poll error', args)));
    req.create();
  }
}
