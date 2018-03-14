import 'package:socket_io_engine/src/global/global.dart';
import 'package:test/test.dart';

void main() {
  test('encodeURIComponent', () {
    expect(Global.encodeURIComponent(" ~'()! "), equals("%20~'()!%20"));
    expect(Global.encodeURIComponent('+:;'), equals('%2B%3A%3B'));
  });

  test('decodeURIComponent', () {
    expect(Global.decodeURIComponent('%20%7E%27%28%29%21%20'), equals(" ~'()! "));
    expect(Global.decodeURIComponent('%2B%3A%3B'), equals('+:;'));
  });
}
