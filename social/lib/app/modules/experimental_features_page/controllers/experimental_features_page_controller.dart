import 'package:get/get.dart';
import 'package:im/db/db.dart';

enum ExperimentalFeatures {
  GifSearch,
}

class ExperimentalFeatureItem {
  final ExperimentalFeatures enumType;
  final String title;
  final String desc;
  final bool defaultValue;

  ExperimentalFeatureItem(
      this.enumType, this.defaultValue, this.title, this.desc) {
    value = RxBool(defaultValue);
    value.value = Db.experimentalFeatureBox
        .get(enumType.toString(), defaultValue: defaultValue);
  }

  RxBool value;
}

class ExperimentalFeaturesPageController extends GetxController {
  static bool isEnabled(ExperimentalFeatures feature) {
    final val = Db.experimentalFeatureBox.get(feature.toString());
    if (val != null) return val;

    try {
      return list.firstWhere((e) => e.enumType == feature).defaultValue;
    } catch (_) {
      return false;
    }
  }

  static List<ExperimentalFeatureItem> list = [
    ExperimentalFeatureItem(
      ExperimentalFeatures.GifSearch,
      false,
      "聊天表情联想".tr,
      "在聊天时，系统会根据你输入的文字展示推荐的表情".tr,
    ),
  ];

  List<ExperimentalFeatureItem> get data => list;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {}

  void changeState(ExperimentalFeatureItem item, bool value) {
    item.value.value = value;
    Db.experimentalFeatureBox.put(item.enumType.toString(), value);
  }
}
