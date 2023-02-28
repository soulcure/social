import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/ws/ws.dart';

// 处理文档协作者权限变更和在线用户变更通知
void tcDocHandler(String action, Map data) {
  final guildId = data['guild_id'].toString();
  final fileId = data['file_id'].toString();
  if (guildId == null || fileId == null) return;
  WsMessage wsMessage;
  if (action == MessageAction.tcDocGroupUp) {
    wsMessage = WsMessage(
        MessageAction.tcDocGroupUp, TcDocGroupUpEvent(guildId, fileId));
  } else if (action == MessageAction.tcDocViewUp) {
    wsMessage =
        WsMessage(MessageAction.tcDocViewUp, TcDocViewUpEvent(guildId, fileId));
  }
  if (wsMessage != null) {
    Ws.instance.fire(wsMessage);
  }
}

class TcDocGroupUpEvent {
  final String guildId;
  final String fileId;
  TcDocGroupUpEvent(this.guildId, this.fileId);
}

class TcDocViewUpEvent {
  final String guildId;
  final String fileId;
  TcDocViewUpEvent(this.guildId, this.fileId);
}
