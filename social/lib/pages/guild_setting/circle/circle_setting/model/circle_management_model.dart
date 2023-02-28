import 'dart:async';

import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';

class CircleInfoModel {
  final CircleInfoDataModel _circleDataModel;

  String get guildId => _circleDataModel.guildId;

  String get channelId => _circleDataModel.channelId;

  String get circleIcon => _circleDataModel.circleIcon;

  String get circleName => _circleDataModel.circleName;

  String get description => _circleDataModel.description;

  BehaviorSubject<CircleInfoDataModel> _circleSubject;

  Stream<CircleInfoDataModel> circleStream;

  Stream<String> circleIconStream;
  Stream<String> circleBannerStream;
  Stream<String> circleNameStream;
  Stream<String> circleDescStream;
  Stream<String> circleSortTypeStream;

  CircleInfoModel(this._circleDataModel) {
    _circleSubject =
        BehaviorSubject<CircleInfoDataModel>.seeded(_circleDataModel);
    circleIconStream = _map2Data((model) => model.circleIcon);
    circleNameStream = _map2Data((model) => model.circleName);
    circleDescStream = _map2Data((model) => model.description);
    circleBannerStream = _map2Data((model) => model.circleBanner);
    circleSortTypeStream = _map2Data((model) => model.sortType);
    circleStream = _circleSubject.stream;
  }

  Stream<T> _map2Data<T>(T Function(CircleInfoDataModel model) convert) {
    return _circleSubject.stream
        .map((data) => convert(data))
        .skipWhile((data) => data == null)
        .distinct((p, n) => p == n);
  }

  Future updateCircleName(String name) async {
    await CircleApi.updateCircle(
      _circleDataModel.channelId,
      _circleDataModel.guildId,
      name: name,
    );
    _circleDataModel.circleName = name;
    _circleSubject.add(_circleDataModel);
    updateTargetInfo(name: name);
  }

  Future updateCircleDesc(String desc) async {
    await CircleApi.updateCircle(
      _circleDataModel.channelId,
      _circleDataModel.guildId,
      description: desc,
    );
    _circleDataModel.description = desc;
    _circleSubject.add(_circleDataModel);
    updateTargetInfo(desc: desc);
  }

  Future updateCircleIcon(String url) async {
    await CircleApi.updateCircle(
      _circleDataModel.channelId,
      _circleDataModel.guildId,
      icon: url,
    );
    _circleDataModel.circleIcon = url;
    _circleSubject.add(_circleDataModel);
    updateTargetInfo(icon: url);
  }

  ///更新圈子背景图（CDN地址）
  Future updateCircleBanner(String url) async {
    await CircleApi.updateCircle(
      _circleDataModel.channelId,
      _circleDataModel.guildId,
      banner: url,
    );
    _circleDataModel.circleBanner = url;
    _circleSubject.add(_circleDataModel);
    updateTargetInfo(banner: url);
  }

  Future updateCircleOrderType(String type) async {
    await CircleApi.updateCircle(
      _circleDataModel.channelId,
      _circleDataModel.guildId,
      sortType: type,
    );
    _circleDataModel.sortType = type;
    _circleSubject.add(_circleDataModel);
  }

  void updateTargetInfo(
      {String name, String icon, String banner, String desc}) {
    final target = ChatTargetsModel.instance.getGuild(guildId);
    if (target != null && target.circleData != null) {
      if (name.hasValue) target.circleData['name'] = name;
      if (icon.hasValue) target.circleData['icon'] = icon;
      if (banner.hasValue) target.circleData['banner'] = banner;
      if (desc.hasValue) target.circleData['description'] = desc;
    }
  }

  void dispose() {
    _circleSubject.close();
  }
}

class TopicsModel {
  String guildId;
  String channelId;
  List<CircleTopicDataModel> topics;
  Set<String> _topicsName;
  BehaviorSubject<List<CircleTopicDataModel>> _topicsSubject;
  Stream<List<CircleTopicDataModel>> topicsStream;
  Stream<bool> hasTopicStream;

  TopicsModel(this.channelId, this.guildId) {
    _topicsSubject = BehaviorSubject();
    topicsStream =
        _topicsSubject.stream.takeWhile((element) => element != null);
    hasTopicStream = topicsStream.map((topics) => topics.isNotEmpty);
  }

  Future fetchTopics() async {
    final rawTopics = await CircleApi.getTopics(guildId, channelId: channelId);
    _topicsName = {};
    topics = rawTopics.map((t) {
      final topic = CircleTopicDataModel.fromJson(t);
      _topicsName.add(topic.topicName);
      return topic;
    }).toList();

    // 更新话题权限
    PermissionModel.updateGuildCircleOverridePermission(guildId, rawTopics);

    _topicsSubject.add(topics);
  }

  Future deleteTopic(CircleTopicDataModel topic) async {
    await CircleApi.deleteTopic(topic.topicId, channelId, guildId);
    topics.remove(topic);
    _topicsName.remove(topic.topicName);
    _topicsSubject.add(topics);
    _updateTopicsModel();
  }

  Future addTopic(String topicName, String guildId) async {
    final rawTopic = await CircleApi.addTopic(channelId, guildId, topicName);
    final topic = CircleTopicDataModel.fromJson(rawTopic);
    topic.guildId = guildId;
    topics.add(topic);
    _topicsName.add(topicName);
    _topicsSubject.add(topics);
    _updateTopicsModel();

    // 刷新服务台话题的权限，因为创建话题之后马上进入话题的权限设置会找不到，所以刷新一下
    unawaited(PermissionModel.fetchGuildTopicPermission(guildId));
  }

  Future setupViewStyleTopic(
    int index,
    String topicId,
    int showType,
  ) async {
    await CircleApi.setupViewStyleTopic(
      channelId,
      guildId,
      showType,
      topicId: topicId,
    );
    // final _topic = CircleTopicDataModel.fromJson(_rawTopic);
    // if (index < topics.length) {
    //   topics[index] = _topic;
    // } else {
    //   topics.add(_topic);
    // }
    // _topicsSubject.add(topics);
    _updateTopicsModel();
  }

  Future renameTopic(int index, String topicId, String topicName,
      {int listDisplay = 1}) async {
    final _rawTopic = await CircleApi.addTopic(
      channelId,
      guildId,
      topicName,
      topicId: topicId,
      listDisplay: listDisplay,
    );
    final _topic = CircleTopicDataModel.fromJson(_rawTopic);
    _topic.listDisplay = listDisplay;
    _topicsName.add(topicName);
    if (index < topics.length) {
      _topicsName.remove(topics[index].topicName);
      topics[index] = _topic;
    } else {
      topics.add(_topic);
    }
    _topicsSubject.add(topics);
    _updateTopicsModel();
  }

  // 话题重新排序
  Future reorderTopics(List<CircleTopicDataModel> reorderTopics) async {
    final reordered = reorderTopics
        .map<Map<String, dynamic>>((t) => {
              'channel_id': t.channelId,
              'topic_id': t.topicId,
              'guild_id': t.guildId,
              'name': t.topicName,
            })
        .toList();
    await CircleApi.reorderTopics(channelId, guildId, reordered);
    topics = reorderTopics;
    _topicsSubject.add(topics);
    _updateTopicsModel();
  }

  // 刷新圈子主页的话题数据
  void _updateTopicsModel() {
    try {
      CircleController.to?.updateCircleTopics();
      // ignore: empty_catches
    } catch (e) {
      logger.info('未从圈子首页进入');
    }
  }

  bool hasTopics() {
    return topics != null && topics.isNotEmpty;
  }

  bool hasTopic(String topicName) {
    if (_topicsName == null) return false;
    return _topicsName.contains(topicName);
  }

  void dispose() {
    _topicsSubject.close();
  }
}
