

import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/widgets/custom_route_page/custom_route_model.dart';

class MainRouteModel extends CustomRouteModel {

  static MainRouteModel instance = MainRouteModel();

  String channelId;

  MainRouteModel() {
    channelId = GlobalState.selectedChannel?.value?.id;
    GlobalState.selectedChannel.addListener(() {
      if (channelId != GlobalState.selectedChannel?.value?.id) {
        channelId = ChatTargetsModel.instance?.selectedChatTarget?.id;
        MainRouteModel.instance.goBack();
      }
    });
  }

}