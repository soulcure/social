

import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/widgets/custom_route_page/custom_route_model.dart';

class MemberListRouteModel extends CustomRouteModel {
  static MemberListRouteModel instance = MemberListRouteModel();

  MemberListRouteModel() {
    GlobalState.selectedChannel.addListener(() {
      MemberListRouteModel.instance.goBack();
    });
  }

}