import 'package:get/get.dart';
import 'package:im/pages/bot_market/model/bot_market_controller.dart';

class BotMarketPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(BotMarketPageController());
  }
}
