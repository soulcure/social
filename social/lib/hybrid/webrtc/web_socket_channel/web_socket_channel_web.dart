
import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel connectImpl(String url, {Iterable<String> protocols,}) {
  return HtmlWebSocketChannel.connect(url, protocols: ['janus-protocol']);
}