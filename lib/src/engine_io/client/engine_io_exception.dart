class EngineIOException extends Error {
  EngineIOException(this.transport, this.code);

  final String transport;
  final dynamic code;

  @override
  String toString() {
    return 'EngineIOException{transport: $transport, code: $code}';
  }
}
