class SocketEvent {
  const SocketEvent._();

  static const String open = 'open';
  static const String close = 'close';
  static const String message = 'message';
  static const String error = 'error';
  static const String upgradeError = 'upgradeError';
  static const String flush = 'flush';
  static const String drain = 'drain';
  static const String handshake = 'handshake';
  static const String upgrading = 'upgrading';
  static const String upgrade = 'upgrade';
  static const String packet = 'packet';
  static const String packetCreate = 'packetCreate';
  static const String heartbeat = 'heartbeat';
  static const String data = 'data';
  static const String ping = 'ping';
  static const String pong = 'pong';
  static const String transport = 'transport';

  static List<String> get values => const <String>[
        open,
        close,
        message,
        error,
        upgradeError,
        flush,
        drain,
        handshake,
        upgrading,
        upgrade,
        packet,
        packetCreate,
        heartbeat,
        data,
        ping,
        pong,
        transport
      ];
}
