import 'dart:convert';

class HandshakeData {
  // sid
  final String sessionId;
  final List<String> upgrades;
  final int pingInterval;
  final int pingTimeout;

  HandshakeData({this.sessionId, this.upgrades, this.pingInterval, this.pingTimeout});

  factory HandshakeData.fromJson(Map<String, dynamic> json) {
    return HandshakeData(
      sessionId: json['sid'] as String,
      upgrades: (json['upgrades'] as List).cast<String>(),
      pingInterval: json['pingInterval'] as int,
      pingTimeout: json['pingTimeout'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sid': sessionId,
      'upgrades': upgrades,
      'pingInterval': pingInterval,
      'pingTimeout': pingTimeout,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}
