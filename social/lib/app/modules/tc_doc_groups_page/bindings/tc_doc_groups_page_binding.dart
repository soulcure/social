import 'package:get/get.dart';

import '../controllers/tc_doc_groups_page_controller.dart';

class TcDocGroupsPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TcDocGroupsPageController>(
      () => TcDocGroupsPageController(
        guildId: (Get.arguments as Map<String, String>)['guildId'],
        fileId: (Get.arguments as Map<String, String>)['fileId'],
      ),
    );
  }
}
