class SocketState {
  const SocketState._();

  static const String opening = 'opening';
  static const String open = 'open';
  static const String closing = 'closing';
  static const String closed = 'closed';

  static List<String> values = const <String>[opening, open, closing, closed];
}
