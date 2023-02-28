import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/common/extension/string_extension.dart';

class OnlineDocumentController extends GetxController {
  String _guildId;
  EntryType entryType = EntryType.view;
  TabController tabController;

  static OnlineDocumentController to() {
    OnlineDocumentController c;
    if (Get.isRegistered<OnlineDocumentController>()) {
      c = Get.find<OnlineDocumentController>();
    } else {
      c = Get.put(OnlineDocumentController());
    }
    return c;
  }

  void tabChoose(TabController c) {
    assert(c != null);
    tabController = c;
  }

  void selectTab(EntryType entryType) {
    if (tabController != null) {
      tabController.animateTo(entryType.index);
    }
  }

  String get guildId {
    if (_guildId.noValue) {
      _guildId = Get.arguments;
    }
    return _guildId;
  }

  int get curIndex => entryType.index;

  @override
  void onInit() {
    super.onInit();
    _guildId = Get.arguments;
  }
}
