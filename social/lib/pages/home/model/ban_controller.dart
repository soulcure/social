import 'package:get/get.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

class BanController extends GetxController {
  String guildId;

  BanController(this.guildId);

  bool isBan() {
    final gt = ChatTargetsModel.instance.getChatTarget(guildId) as GuildTarget;
    if (gt != null) {
      return gt.isBan;
    }
    return false;
  }
}
