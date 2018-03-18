class TransportState {
  const TransportState._();

  static const String opening = 'opening';
  static const String open = 'open';
  static const String closed = 'closed';
  static const String paused = 'paused';

  static List<String> get values => const <String>[opening, open, closed, paused];
}
