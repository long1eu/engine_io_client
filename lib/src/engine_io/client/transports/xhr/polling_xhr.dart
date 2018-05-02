import 'dart:io';

import 'package:engine_io_client/src/emitter/emitter.dart';
import 'package:engine_io_client/src/engine_io/client/transport.dart';
import 'package:engine_io_client/src/engine_io/client/transports/polling.dart';
import 'package:engine_io_client/src/engine_io/client/transports/xhr/request_xhr.dart';
import 'package:engine_io_client/src/logger.dart';
import 'package:engine_io_client/src/models/transport_options.dart';
import 'package:engine_io_client/src/models/xhr_options.dart';
import 'package:rxdart/rxdart.dart';

class PollingXhr extends Polling {
  static final Log log = new Log('EngineIo.PollingXhr');

  PollingXhr(TransportOptions options) : super(options);

  Observable<RequestXhr> request([XhrOptions options]) => new Observable<XhrOptions>.just(
        options ?? new XhrOptions(uri: uri, client: new HttpClient(context: this.options.securityContext)),
      )
          .map((XhrOptions options) => new RequestXhr(options))
          .flatMap<dynamic>((RequestXhr request) => new Observable<dynamic>.merge(<Observable<dynamic>>[
                request
                    .on(RequestXhr.eventRequestHeaders)
                    .doOnData((Event event) => emit(Transport.eventRequestHeaders, event.args)),
                request
                    .on(RequestXhr.eventResponseHeaders)
                    .doOnData((Event event) => emit(Transport.eventResponseHeaders, event.args)),
                new Observable<RequestXhr>.just(request),
              ]))
          .where((dynamic event) => event is RequestXhr)
          .cast<RequestXhr>();

  @override
  Observable<Event> doWrite$(dynamic data) => new Observable<XhrOptions>.just(new XhrOptions(
        method: 'POST',
        data: data,
        client: new HttpClient(context: options.securityContext),
        uri: uri,
      ))
          .flatMap((XhrOptions options) => request(options))
          .flatMap((RequestXhr request) => new Observable<Event>.merge(<Observable<Event>>[
                request.on(RequestXhr.eventError).flatMap((Event event) => onError('xhr post error', event.args)),
                request.create$,
              ]))
          .where((Event event) => event.name == RequestXhr.eventSuccess);

  //.where((Event event) => event.name == RequestXhr.eventSuccess);

  @override
  Observable<Event> get poll$ => request()
      .doOnData((RequestXhr _) => log.d('xhr poll'))
      .doOnData((RequestXhr _) => polling = true)
      .flatMap((RequestXhr request) => new Observable<Event>.merge(<Observable<Event>>[
            request
                .on(RequestXhr.eventData)
                .flatMap((Event event) => onData(event.args.isNotEmpty ? event.args[0] : null)),
            request.on(RequestXhr.eventError).flatMap((Event event) => onError('xhr poll error', event.args)),
            request.create$.map<Event>((Event _) => new Event(Polling.eventPoll))
          ]));

//.where((Event event) => event.name == Polling.eventPoll);
}
