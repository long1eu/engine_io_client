class EngineIOError extends Error {
  EngineIOError(this.transport, this.code);

  final String transport;
  final dynamic code;

  @override
  String toString() => 'EngineIOError{transport: $transport, code: $code}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EngineIOError && runtimeType == other.runtimeType && transport == other.transport && code == other.code;

  @override
  int get hashCode => transport.hashCode ^ code.hashCode;
}
