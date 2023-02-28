import 'package:im/community/interactive_entity/controllers/interactive_entity_controller.dart';
import 'package:im/community/interactive_entity/entity/interactive_entity.dart';
import 'package:im/community/unity_bridge_controller.dart';

class UnityBridgeWithInteractiveEntity extends UnityBridgeWithPartial {
  final InteractiveEntityController _interactiveEntityController;

  UnityBridgeWithInteractiveEntity(UnityBridgeController controller)
      : _interactiveEntityController =
            InteractiveEntityController.create(controller),
        super(controller);

  @override
  Future<void> destroy() async {
    await _interactiveEntityController?.destroy();
  }

  @override
  bool handleUnityMessage(
      String messageId, String method, Map<String, String> parameters) {
    switch (method) {
      case "ShowInteractiveEntity":
        switch (parameters["entityType"]) {
          case "ChannelDialog":
            _interactiveEntityController.showEntity(
                InteractiveEntityType.ChannelDialog, parameters["content"]);
            break;
          default:
            break;
        }
        break;
      case "HideInteractiveEntity":
        _interactiveEntityController.hideEntity();
        break;
      default:
        return false;
    }
    return true;
  }
}
