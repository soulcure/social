import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel connectImpl(
  String url, {
  Iterable<String> protocols,
}) {
  /// 解决苹果无法及时收到onDone事件，需要几十秒，所以加入 pingInterval
  return IOWebSocketChannel.connect(url,
      protocols: ['janus-protocol'], pingInterval: const Duration(seconds: 5));
}
