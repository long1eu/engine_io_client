library serializers;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:socket_io_engine/src/models/handshake_data.dart';
import 'package:socket_io_engine/src/models/packet.dart';
import 'package:socket_io_engine/src/models/packet_type.dart';
import 'package:socket_io_engine/src/models/transport_state.dart';
import 'package:socket_io_engine/src/models/socket_event.dart';
import 'package:socket_io_engine/src/models/socket_options.dart';
import 'package:socket_io_engine/src/models/transport_event.dart';
import 'package:socket_io_engine/src/models/transport_options.dart';
import 'package:socket_io_engine/src/models/xhr_event.dart';
import 'package:socket_io_engine/src/models/xhr_options.dart';

part 'serializers.g.dart';

@SerializersFor(const <Type>[
  HandshakeData,
  Packet,
  PacketType,
  TransportState,
  SocketEvent,
  SocketOptions,
  TransportEvent,
  TransportOptions,
  XhrEvent,
  XhrOptions,
])
final Serializers serializers = (_$serializers.toBuilder()..addPlugin(new StandardJsonPlugin())).build();
