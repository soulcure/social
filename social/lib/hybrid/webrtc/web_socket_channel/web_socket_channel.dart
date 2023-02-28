
import 'package:web_socket_channel/web_socket_channel.dart';
import 'web_socket_channel_mobile.dart' if (dart.library.html) 'web_socket_channel_web.dart';

WebSocketChannel connectWebScoket(String url, {Iterable<String> protocols,}) {
  return connectImpl(url, protocols: ['janus-protocol']);
}