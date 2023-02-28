import 'package:get/get.dart';

import '../controllers/tc_doc_add_group_page_controller.dart';

class TcDocAddGroupPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TcDocAddGroupPageController>(
      () => TcDocAddGroupPageController(
        guildId: (Get.arguments as Map<String, String>)['guildId'],
        fileId: (Get.arguments as Map<String, String>)['fileId'],
      ),
    );
  }
}
