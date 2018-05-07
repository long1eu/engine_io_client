// ignore_for_file: strong_mode_implicit_dynamic_parameter,
// ignore_for_file: avoid_function_literals_in_foreach_calls,
// ignore_for_file: always_specify_types, prefer_single_quotes
class Log {
  static bool shouldLog = true;

  Log(String tag, {bool formatTags: true}) {
    if (formatTags) {
      this.tag = _formatTag(tag);
    } else
      this.tag = tag;
  }

  String tag;

  Log addTag(String tag) => new Log('${this.tag}-$tag', formatTags: false);

  void i(Object message) {
    if (!shouldLog) return;
    if (message is List) {
      message.forEach((it) {
        print("I/$tag: $it");
      });
    } else
      print("I/$tag: $message");
  }

  void d(Object message) {
    if (!shouldLog) return;
    if (message is List) {
      message.forEach((it) {
        print("D/$tag: $it");
      });
    } else
      print("D/$tag: $message");
  }

  void w(Object message) {
    if (!shouldLog) return;
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
    if (!shouldLog) return;
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

String _formatTag(String tag) {
  if (tag.length > 30)
    return tag.substring(0, 31);
  else
    return tag + "                                ".substring(tag.length);
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
