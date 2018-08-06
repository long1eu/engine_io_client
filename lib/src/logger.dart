// ignore_for_file: strong_mode_implicit_dynamic_parameter,
// ignore_for_file: avoid_function_literals_in_foreach_calls,
// ignore_for_file: always_specify_types, prefer_single_quotes
import 'package:engine_io_client/engine_io_client.dart';

class Log {
  Log(String tag, {bool formatTags: true}) {
    if (formatTags) {
      _tag = tag.padRight(30);
    } else
      _tag = tag;
  }

  String _tag;

  String get tag => '${new DateTime.now().toIso8601String()}||$_tag';

  Log addTag(String tag) => new Log('${this.tag}-$tag', formatTags: false);

  void i(Object message) {
    if (!LoggerOptions.shouldLog) return;
    if (message is List) {
      message.forEach((it) {
        print("I/$tag: $it");
      });
    } else
      print("I/$tag: $message");
  }

  void d(Object message) {
    if (!LoggerOptions.shouldLog) return;
    if (message is List) {
      message.forEach((it) {
        print("D/$tag: $it");
      });
    } else
      print("D/$tag: $message");
  }

  void w(Object message) {
    if (!LoggerOptions.shouldLog) return;
    print("W/$tag: WARNING-------------------------------------------------------------------");
    if (message is List) {
      message.forEach((it) {
        print("W/$tag: $it");
      });
    } else
      print("W/$tag: $message");
    print("W/$tag: ==========================================================================");
  }

  void e(Object message) {
    if (!LoggerOptions.shouldLog) return;
    print("E/$tag: +----------------------------------ERROR---------------------------------+");
    if (message is List) {
      message.forEach((it) {
        print("E/$tag: $it");
      });
    } else
      print("E/$tag: $message");
    print("E/$tag: ==========================================================================");
  }
}

class ToStringHelper {
  int _toStringHelperIndent = 0;

  StringBuffer _result = new StringBuffer();

  ToStringHelper(String className) {
    _result..write(className)..write(' {\n');
    _toStringHelperIndent += 2;
  }

  void add(String field, Object value) {
    if (value != null) {
      _result..write(' ' * _toStringHelperIndent)..write(field)..write('=')..write(value)..write(',\n');
    }
  }

  @override
  String toString() {
    _toStringHelperIndent -= 2;
    _result..write(' ' * _toStringHelperIndent)..write('}');
    final stringResult = _result.toString();
    _result = null;
    return stringResult;
  }
}
