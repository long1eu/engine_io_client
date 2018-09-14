class XhrEvent {
  const XhrEvent._();

  static const String success = 'success';
  static const String data = 'data';
  static const String error = 'error';

  static List<String> values = const <String>[success, data, error];
}
