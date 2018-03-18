class XhrEvent {
  const XhrEvent._();

  static const String success = 'success';
  static const String data = 'data';
  static const String error = 'error';
  static const String requestHeaders = 'requestHeaders';
  static const String responseHeaders = 'responseHeaders';

  static List<String> values = const <String>[success, data, error, requestHeaders, responseHeaders];
}
