import 'package:engine_io_client/src/global/global.dart';

class ParseQS {
  ParseQS._();

  static String encode(Map<String, String> obj) {
    final StringBuffer str = StringBuffer();

    obj.forEach((String key, String value) {
      str
        ..write(str.length > 0 ? '&' : '')
        ..write(Global.encodeURIComponent(key))
        ..write('=')
        ..write(Global.encodeURIComponent(value));
    });
    return str.toString();
  }

  static Map<String, String> decode(String qs) {
    final Map<String, String> query = <String, String>{};
    final List<String> pairs = qs.split('&');
    for (String _pair in pairs) {
      final List<String> pair = _pair.split('=');
      query[Global.decodeURIComponent(pair[0])] = pair.length > 1 ? Global.decodeURIComponent(pair[1]) : '';
    }
    return query;
  }
}
