class EngineIOError extends Error {
  EngineIOError(this.transport, this.code);

  final String transport;
  final dynamic code;

  @override
  String toString() => 'EngineIOError{transport: $transport, code: $code}';
}
