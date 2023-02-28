import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:im/community/interactive_entity/entity/interactive_entity.dart';
import 'package:im/community/interactive_entity/entity/channel_dialog_entity.dart';
import 'package:im/community/unity_bridge_controller.dart';

class InteractiveEntityController extends GetxController {
  Rx<InteractiveEntity> currentEntity = Rx<InteractiveEntity>(null);

  final UnityBridgeController unityBridgeController;

  static InteractiveEntityController create(
      UnityBridgeController unityBridgeController) {
    return Get.put<InteractiveEntityController>(
        InteractiveEntityController(unityBridgeController));
  }

  static InteractiveEntityController get() {
    InteractiveEntityController c;
    try {
      c = Get.find<InteractiveEntityController>();
    } catch (e) {
      print(e);
    }
    return c;
  }

  InteractiveEntityController(this.unityBridgeController);

  Future<void> destroy() async {
    await Get.delete<InteractiveEntityController>();
  }

  void showEntity(InteractiveEntityType type, String data) {
    InteractiveEntity entity;
    switch (type) {
      case InteractiveEntityType.ChannelDialog:
        entity = ChannelDialogEntity(data);
        break;
      default:
        break;
    }
    currentEntity.value = entity;
  }

  void hideEntity() {
    currentEntity.value = null;
  }
}
