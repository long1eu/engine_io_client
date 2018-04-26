import 'dart:convert';

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
    } else
      map = data;

    return new HandshakeData(
      sessionId: map['sid'],
      upgrades: map['upgrades'],
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
}
