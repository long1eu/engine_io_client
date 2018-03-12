library transport_event;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'transport_event.g.dart';

class TransportEvent extends EnumClass {
  const TransportEvent._(String name) : super(name);

  static const TransportEvent open = _$open;

  static const TransportEvent close = _$close;

  static const TransportEvent packet = _$packet;

  static const TransportEvent drain = _$drain;

  static const TransportEvent error = _$error;

  static const TransportEvent requestHeaders = _$requestHeaders;

  static const TransportEvent responseHeaders = _$responseHeaders;

  static BuiltSet<TransportEvent> get values => _$TransportEventValues;

  static TransportEvent valueOf(String name) => _$TransportEventValueOf(name);

  static Serializer<TransportEvent> get serializer => _$transportEventSerializer;
}
