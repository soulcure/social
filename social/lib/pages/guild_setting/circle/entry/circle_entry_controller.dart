import 'package:get/get.dart';
import 'package:im/pages/guild_setting/circle/entry/circle_entry_handler.dart';

///圈子入口 Controller
class CircleEntryController extends GetxController {
  static CircleEntryController to() {
    try {
      return Get.find<CircleEntryController>();
    } catch (_) {
      // print('getChat controller to error: $e');
    }
    return null;
  }

  String guildId;

  CircleEntryBean bean;

  CircleEntryController(this.guildId) {
    bean = circleEntryCache[guildId];
  }

  ///更新 guildId 和 bean
  void updateData(String gId, {bool isUpdate = true}) {
    try {
      guildId = gId;
      bean = circleEntryCache[gId];
      if (isUpdate) update();
    } catch (_) {
      // debugPrint('getChat updateData --> error: $e');
    }
  }
}

///圈子入口信息 bean
class CircleEntryBean {
  final String title;
  final String content;
  final String contentV2;
  final String postType;
  final String channelId;

  ///新的动态数量
  int newPostTotal;

  CircleEntryBean({
    this.title,
    this.postType,
    this.content,
    this.contentV2,
    this.channelId,
    this.newPostTotal,
  });

  factory CircleEntryBean.fromJson(Map<String, dynamic> json) {
    return CircleEntryBean(
      title: json['title'],
      postType: json['post_type'],
      content: json['content'],
      contentV2: json['content_v2'],
      channelId: json['channel_id'],
    );
  }
}
