library xhr_event;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'xhr_event.g.dart';

class XhrEvent extends EnumClass {
  const XhrEvent._(String name) : super(name);

  static const XhrEvent success = _$success;
  static const XhrEvent data = _$data;
  static const XhrEvent error = _$error;
  static const XhrEvent requestHeaders = _$requestHeaders;
  static const XhrEvent responseHeaders = _$responseHeaders;

  static BuiltSet<XhrEvent> get values => _$XhrEventValues;

  static XhrEvent valueOf(String name) => _$XhrEventValueOf(name);

  static Serializer<XhrEvent> get serializer => _$xhrEventSerializer;
}
