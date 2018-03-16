import 'package:engine_io_client/src/yeast/yeast.dart';
import 'package:test/test.dart';

void main() {
  void _waitUntilNextMillisecond() {
    final int now = new DateTime.now().millisecondsSinceEpoch;
    while (new DateTime.now().millisecondsSinceEpoch == now) {}
  }

  test('prependsIteratedSeedWhenSamePreviousId', () {
    _waitUntilNextMillisecond();

    final List<String> ids = <String>[Yeast.yeast(), Yeast.yeast(), Yeast.yeast(), Yeast.yeast()];
    print(ids);
    expect(ids[0].contains('.'), isFalse);
    expect(ids[3].contains('.'), isTrue);
  });

  test('resetsTheSeed', () {
    _waitUntilNextMillisecond();

    List<String> ids = <String>[Yeast.yeast(), Yeast.yeast(), Yeast.yeast()];
    expect(ids[0], isNot(contains('.')));
    expect(ids[1], contains('.0'));
    expect(ids[2], contains('.1'));

    _waitUntilNextMillisecond();

    ids = <String>[Yeast.yeast(), Yeast.yeast(), Yeast.yeast()];

    expect(ids[0], isNot(contains('.')));
    expect(ids[1], contains('.0'));
    expect(ids[2], contains('.1'));
  });

  test('doesNotCollide', () {
    final int length = 30000;
    final List<String> ids = new List<String>(length);

    for (int i = 0; i < length; i++) ids[i] = Yeast.yeast();

    ids.sort();

    for (int i = 0; i < length - 1; i++) {
      expect(ids[i], isNot(equals(ids[i + 1])));
    }
  });

  test('canConvertIdToTimestamp', () {
    _waitUntilNextMillisecond();

    final int now = new DateTime.now().millisecondsSinceEpoch;
    final String id = Yeast.yeast();

    expect(Yeast.encode(now), equals(id));
    expect(Yeast.decode(id), equals(now));
  });
}
