import 'package:built_collection/built_collection.dart';
import 'package:socket_io/src/parse_qs/parse_qs.dart';
import 'package:test/test.dart';

// ignore_for_file: prefer_collection_literals
void main() {
  test('decode', () {
    Map<String, String> queryObject = ParseQS.decode('foo=bar');
    expect(queryObject['foo'], 'bar');

    queryObject = ParseQS.decode('france=paris&germany=berlin');
    expect(queryObject['france'], 'paris');
    expect(queryObject['germany'], 'berlin');

    queryObject = ParseQS.decode('india=new%20delhi');
    expect(queryObject['india'], 'new delhi');

    queryObject = ParseQS.decode('woot=');
    expect(queryObject['woot'], '');

    queryObject = ParseQS.decode('woot');
    expect(queryObject['woot'], '');
  });

  test('encode', () {
    MapBuilder<String, String> obj;

    obj = new MapBuilder<String, String>();
    obj['a'] = 'b';

    expect(ParseQS.encode(obj.build()), 'a=b');

    obj.clear();
    obj['a'] = 'b';
    obj['c'] = 'd';
    expect(ParseQS.encode(obj.build()), 'a=b&c=d');

    obj.clear();

    obj['a'] = 'b';
    obj['c'] = 'nicolas is the best';

    expect(ParseQS.encode(obj.build()), 'a=b&c=nicolas%20is%20the%20best');
  });
}
