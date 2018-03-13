import 'dart:io';

import 'package:flutter_logger/flutter_logger.dart';

class Connection {
  static final Log log = new Log('Connection');

  static const int TIMEOUT = 10000;
  static const int PORT = 3000;

  Process process;

  void startServer() async {
    log.d('Starting server ...');

    process = await Process.start(
      'node',
      new List(),
      workingDirectory: Directory.current.path,
      environment: createEnv(),
    );

    process.stdout.listen((data) {
      log.d(data);
    });

    log.d('Server started');
  }

  void stopServer() {
    log.d('Stopping server ...');
    process.kill();
  }

  Map<String, String> createEnv() {
    final Map<String, String> env = <String, String>{};
    env.addAll(Platform.environment);
    env['DEBUG'] = 'engine*';
    env['PORT'] = PORT.toString();
    return env;
  }

  List<String> createEnvList() {
    final Map<String, String> env = createEnv();
    final List<String> _env = <String>[];

    env.forEach((String key, String value) => _env.add('$key=$value'));
    return _env;
  }
}
