import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/dark_theme.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';

import 'model/circle_management_model.dart';

/// - 圈子频道编辑
class TopicEditorPage extends StatefulWidget {
  final TopicsModel topicsModel;

  const TopicEditorPage(this.topicsModel, {Key key}) : super(key: key);

  @override
  _TopicEditorPageState createState() => _TopicEditorPageState();
}

class _TopicEditorPageState extends State<TopicEditorPage> {
  CircleTopicDataModel topicAll; //话题 全部
  bool _canSave = false;
  List<CircleTopicDataModel> _topics = [];

  @override
  void initState() {
    super.initState();
    _fetchTopics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FbAppBar.custom(
        '圈子频道排序'.tr,
        backgroundColor: appThemeData.scaffoldBackgroundColor,
        actions: [
          AppBarTextPrimaryActionModel(
            '保存'.tr,
            isEnable: widget.topicsModel.hasTopics() && _canSave,
            actionBlock: _onEditComplete,
          )
        ],
      ),
      body: ReorderableListView.builder(
          header: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              '长按可拖动排序，让精彩内容优先展示。',
              style: appThemeData.textTheme.headline2.copyWith(fontSize: 14),
            ),
          ),
          itemBuilder: (_, index) {
            return _buildTopicItem(_topics[index],
                isTop: index == 0, isBottom: index == _topics.length - 1);
          },
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          itemCount: _topics.length,
          onReorder: _onReorder),
    );
  }

  Widget _buildTopicItem(CircleTopicDataModel topic,
      {bool showButton = true, bool isTop = false, bool isBottom = false}) {
    final color1 = darkTheme.textTheme.bodyText1.color;
    return Container(
      key: ValueKey('topicReorder${topic.topicId}'),
      height: 56,
      padding: const EdgeInsets.only(left: 18, right: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
              top: isTop ? const Radius.circular(8) : Radius.zero,
              bottom: isBottom ? const Radius.circular(8) : Radius.zero)),
      child: Row(
        children: [
          Expanded(
            child:
                Text(topic.topicName, style: appThemeData.textTheme.bodyText2),
          ),
          if (showButton)
            Icon(
              IconFont.buffChannelMoveEditLarge,
              size: 20,
              color: color1,
            ),
        ],
      ),
    );
  }

  Future _fetchTopics() async {
    _topics = List.from(await widget.topicsModel.topicsStream.first);
    topicAll = _topics.isNotEmpty ? _topics[0] : null;
    // 将 全部 圈子频道从集合中移除掉
    if (topicAll != null) {
      _topics.remove(topicAll);
    }
    setState(() {});
  }

  Future _onEditComplete() async {
    try {
      Loading.show(context);
      if (topicAll != null) {
        _topics.insert(0, topicAll);
      }
      await widget.topicsModel.reorderTopics(_topics);
      Get.back();
      Loading.hide();
    } catch (e) {
      print(e);
      Loading.hide();
    }
  }

  bool hasChange() {
    final topics = widget.topicsModel.topics
        .where((e) => e.type == CircleTopicType.common)
        .toList();
    if (topics.length != _topics.length) return true;
    for (int i = 0; i < topics.length; i++) {
      if (topics[i].topicId != _topics[i].topicId) return true;
    }
    return false;
  }

  void _onReorder(oldIndex, newIndex) {
    // 如果是向下拖动，newIndex的值比实际位置大1
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final topic = _topics.removeAt(oldIndex);
    _topics.insert(newIndex, topic);
    _canSave = hasChange();
    setState(() {});
  }
}
