import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/widgets/web_form_detector/web_form_detector_model.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';

class TopicsModel extends ChangeNotifier {
  BuildContext context;
  String guildId;
  String channelId;
  List<CircleTopicDataModel> topics = [];
  List<CircleTopicDataModel> originTopics = [];
  ScrollController _scrollController;

  /// '全部' 圈子频道，不能编辑：移动、删除等
  CircleTopicDataModel theAllTopic;

  ScrollController get scrollController => _scrollController;

  TopicsModel(this.context, this.channelId, this.guildId) {
    _scrollController = ScrollController();
    fetchTopics();
  }

  Future fetchTopics() async {
    final rawTopics = await CircleApi.getTopics(guildId, channelId: channelId);
    rawTopics.forEach((t) {
      final topic = CircleTopicDataModel.fromJson(t);
      if (topic.channelId == topic.topicId) {
        // '全部' 圈子频道的channelId == topicId
        theAllTopic = topic;
      } else {
        topics.add(topic);
        originTopics.add(topic);
      }
    });
    notifyListeners();
  }

  bool get formChanged {
    if (topics.length != originTopics.length) return true;
    bool flag = false;
    for (int i = 0; i < topics.length; i++) {
      if (topics[i].topicName != originTopics[i].topicName ||
          topics[i].topicId != originTopics[i].topicId) {
        flag = true;
        break;
      }
    }
    return flag;
  }

  Future deleteTopic(int index) async {
    topics.removeAt(index);
    checkFormChanged();
    notifyListeners();
  }

  Future addTopic() async {
    final topic = CircleTopicDataModel(
      guildId: guildId,
      channelId: channelId,
      type: CircleTopicType.common,
    );
    topics.add(topic);

    unawaited(delay(() {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeIn,
      );
    }, 100));
    checkFormChanged();
    notifyListeners();
  }

  Future renameTopic(int index, String topicName) async {
    final topic = topics[index];
    topic.topicName = topicName;
    checkFormChanged();
  }

  // 圈子频道重新排序
  void onReorder(int oldIndex, int newIndex) {
    final topic = topics.removeAt(oldIndex);
    topics.insert(newIndex, topic);
    checkFormChanged();
    notifyListeners();
  }

  void checkFormChanged() {
    Provider.of<WebFormDetectorModel>(context, listen: false)
        .toggleChanged(formChanged);

    final has = topics.any((element) =>
        element.topicName.trim().characters.length > 6 ||
        element.topicName.isEmpty);
    Provider.of<WebFormDetectorModel>(context, listen: false)
        .confirmEnabled(!has);
  }

  // 刷新圈子主页的圈子频道数据
  // void _updateTopicsModel() {
  //   if (CircleDataModel.instance != null) {
  //     CircleDataModel.instance.updateCircleTopics();
  //   }
  // }FormChanged

  // bool hasTopics() {
  //   return topics != null && topics.isNotEmpty;
  // }
  //
  // bool hasTopic(String topicName) {
  //   if (_topicsName == null) return false;
  //   return _topicsName.contains(topicName);
  // }
  void onReset() {
    topics.clear();
    topics.addAll([
      ...originTopics.map((e) => CircleTopicDataModel(
            topicId: e.topicId,
            guildId: e.guildId,
            channelId: e.channelId,
            topicName: e.topicName,
          ))
    ]);
    checkFormChanged();
    notifyListeners();
  }

  Future<void> onConfirm() async {
    if (topics.any((element) => element.topicName.isEmpty)) {
      showToast('请输入圈子频道名称'.tr);
      return;
    }
    if (topics.any((element) => element.topicName.trim().length > 6)) {
      showToast('圈子频道名称不能超过6个字符'.tr);
      return;
    }
    final newTopics = topics
        .map<Map<String, dynamic>>((t) => {
              'channel_id': t.channelId,
              'topic_id': t.topicId,
              'guild_id': t.guildId,
              'name': t.topicName,
            })
        .toList();
    // 将'全部' 圈子频道插入到第一个
    if (theAllTopic != null) {
      newTopics.insert(0, {
        'channel_id': theAllTopic.channelId,
        'topic_id': theAllTopic.topicId,
        'guild_id': theAllTopic.guildId,
        'name': theAllTopic.topicName,
      });
    }
    await CircleApi.reorderTopics(channelId, guildId, newTopics);
    originTopics = topics
        .map((e) => CircleTopicDataModel(
              topicId: e.topicId,
              guildId: e.guildId,
              channelId: e.channelId,
              topicName: e.topicName,
            ))
        .toList();
    unawaited(CircleController.to.initFromNet());
    checkFormChanged();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
