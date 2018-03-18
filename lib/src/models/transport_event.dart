class TransportEvent {
  const TransportEvent._();

  static const String open = 'open';
  static const String close = 'close';
  static const String packet = 'packet';
  static const String drain = 'drain';
  static const String error = 'error';
  static const String requestHeaders = 'requestHeaders';
  static const String responseHeaders = 'responseHeaders';

  static List<String> values = const <String>[open, close, packet, drain, error, requestHeaders, responseHeaders];
}
