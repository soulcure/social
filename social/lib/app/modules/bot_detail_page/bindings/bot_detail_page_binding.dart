import 'package:get/get.dart';
import '../controllers/bot_detail_page_controller.dart';

class BotDetailPageBinding extends Bindings {
  String guildId;
  String botId;

  @override
  void dependencies() {
    if (Get.arguments is BotDetailPageParams) {
      guildId = (Get.arguments as BotDetailPageParams).guildId;
      botId = (Get.arguments as BotDetailPageParams).botId;
    }
    Get.put<BotDetailPageController>(
      BotDetailPageController(guildId: guildId, botId: botId),
      tag: botId,
    );
  }
}

class BotDetailPageParams {
  final String guildId;
  final String botId;

  BotDetailPageParams({this.guildId, this.botId});
}
