class PollingEvent {
  const PollingEvent._();

  static const String poll = 'poll';
  static const String pollComplete = 'pollComplete';

  static List<String> values = const <String>[poll, pollComplete];
}
