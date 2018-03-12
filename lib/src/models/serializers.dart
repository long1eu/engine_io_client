library serializers;

import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:socket_io/src/models/packet.dart';
import 'package:socket_io/src/models/packet_type.dart';

part 'serializers.g.dart';

@SerializersFor(const <Type>[
  Packet,
  PacketType,
])
final Serializers serializers = (_$serializers.toBuilder()..addPlugin(new StandardJsonPlugin())).build();
