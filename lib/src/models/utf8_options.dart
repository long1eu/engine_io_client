library utf8_options;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'utf8_options.g.dart';

abstract class UTF8Options implements Built<UTF8Options, UTF8OptionsBuilder> {
  factory UTF8Options([UTF8OptionsBuilder updates(UTF8OptionsBuilder b)]) = _$UTF8Options;

  UTF8Options._();

  bool get strict;

  static UTF8Options notStrict = new UTF8Options((UTF8OptionsBuilder b) {
    b.strict = false;
  });

  static Serializer<UTF8Options> get serializer => _$uTF8OptionsSerializer;
}
