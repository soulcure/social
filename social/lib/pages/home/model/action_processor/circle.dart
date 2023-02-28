import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/pages/home/model/chat_index_model.dart';

import '../../json/text_chat_json.dart';

///ws同步圈子设置
void syncCircle(String action, String method, Map data) {
  switch (action) {
    case MessageAction.circleCoverStatus:
      try {
        final model = CircleController.to;
        if (model != null &&
            model.guildId == data["guild_id"] &&
            model.channelId == data["channel_id"]) {
          model.updateCircleInfoDataModel(data);
        }
      } catch (_) {}

      if (data != null && data["guild_id"] != null) {
        final target =
            ChatTargetsModel.instance.getGuild(data["guild_id"] as String);
        target?.updateCircleData(data);
      }
      break;
    default:
      assert(false);
      break;
  }
}
