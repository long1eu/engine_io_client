import 'dart:convert';

import 'package:engine_io_client/src/logger.dart';
import 'package:meta/meta.dart';

class HandshakeData {
  HandshakeData({@required this.sessionId, @required this.upgrades, @required this.pingInterval, @required this.pingTimeout})
      : assert(sessionId != null),
        assert(upgrades != null),
        assert(pingInterval != null),
        assert(pingTimeout != null);

  factory HandshakeData.fromJson(dynamic data) {
    Map<String, dynamic> map;
    if (data is String) {
      map = json.decode(data);
    } else {
      map = data;
    }
    print('HandshakeData: $data');

    final List upgrades = map['upgrades'];

    return new HandshakeData(
      sessionId: map['sid'],
      upgrades: upgrades.isEmpty ? <String>[] : upgrades.cast<String>(),
      pingInterval: map['pingInterval'],
      pingTimeout: map['pingTimeout'],
    );
  }

  final String sessionId;

  final List<String> upgrades;

  final int pingInterval;

  final int pingTimeout;

  HandshakeData copyWith({String sessionId, List<String> upgrades, int pingInterval, int pingTimeout}) {
    return new HandshakeData(
      sessionId: sessionId ?? this.sessionId,
      upgrades: upgrades ?? this.upgrades,
      pingInterval: pingTimeout ?? this.pingInterval,
      pingTimeout: pingTimeout ?? this.pingTimeout,
    );
  }

  @override
  String toString() {
    return (new ToStringHelper('HandshakeData')
          ..add('sessionId', '$sessionId')
          ..add('upgrades', '$upgrades')
          ..add('pingInterval', '$pingInterval')
          ..add('pingTimeout', '$pingTimeout'))
        .toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HandshakeData &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          upgrades == other.upgrades &&
          pingInterval == other.pingInterval &&
          pingTimeout == other.pingTimeout;

  @override
  int get hashCode => sessionId.hashCode ^ upgrades.hashCode ^ pingInterval.hashCode ^ pingTimeout.hashCode;
}
