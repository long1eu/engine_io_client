class EngineIOException implements Exception {
  EngineIOException(this.transport, this.code);

  final String transport;
  final dynamic code;
}
