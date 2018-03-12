library polling_event;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'polling_event.g.dart';

class PollingEvent extends EnumClass {
  const PollingEvent._(String name) : super(name);

  static const PollingEvent poll = _$poll;
  static const PollingEvent pollComplete = _$pollComplete;

  static BuiltSet<PollingEvent> get values => _$PollingEventValues;

  static PollingEvent valueOf(String name) => _$PollingEventValueOf(name);

  static Serializer<PollingEvent> get serializer => _$pollingEventSerializer;
}
