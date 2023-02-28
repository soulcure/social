import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/live_provider/live_api_provider.dart';
import 'package:im/pages/search/model/search_model.dart';

class AddAssistantsController extends GetxController {
  static const int inputChanged = 1;
  static const int selectedUsersChanged = 2;

  final searchInputModel = SearchInputModel();
  final inputController = TextEditingController();

  Set<String> selectedUserIds = {};

  Map<String, FBUserInfo> selectedUsers = {};

  @override
  void onInit() {
    searchInputModel.searchStream.listen((event) {
      update([inputChanged]);
    });

    super.onInit();
  }

  @override
  void onClose() {
    searchInputModel.dispose();
    inputController.dispose();
    super.onClose();
  }

  void cleanSelected() {
    selectedUsers.clear();
  }

  void defaultSelected(List<FBUserInfo> defaultSelected) {
    final Map<String, FBUserInfo> selected = {};
    defaultSelected.forEach((info) => selected.addIf(true, info.userId, info));
    selectedUsers.addAll(selected);
  }

  void onTapUser(String userId, UserInfo userInfo) {
    // if (selectedUserIds.contains(userId)) {
    //   selectedUserIds.remove(userId);
    // } else {
    //   selectedUserIds.add(userId);
    // }
    if (selectedUsers.containsKey(userId)) {
      selectedUsers.remove(userId);
    } else {
      final FBUserInfo fui = FBLiveApiProvider.instance.userInfo2FB(userInfo);
      // selectedUsers.addAll({userId: fui});
      selectedUsers.addIf(true, userId, fui);
    }
    update([selectedUsersChanged]);
  }
}
