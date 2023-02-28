import 'package:get/get.dart';
import 'package:im/app/modules/create_guide_select_template/controllers/create_guild_select_template_page_controller.dart';

class CreateGuildSelectTemplatePageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateGuildSelectTemplatePageController>(
      () => CreateGuildSelectTemplatePageController(),
    );
  }
}
