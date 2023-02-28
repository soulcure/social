import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_publish_controller.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/utils.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

void showTopicListPopup(
    BuildContext context, List<CircleTopicDataModel> topicList) {
  showBottomModal(
    context,
    builder: (c, s) => TopicsPopup(
      topicList: topicList,
    ),
    maxHeight: 0.5,
    backgroundColor: appThemeData.backgroundColor,
    resizeToAvoidBottomInset: false,
    scrollSpec: const ScrollSpec(physics: AlwaysScrollableScrollPhysics()),
    headerBuilder: (c, s) => Column(
      children: [
        sizeHeight16,
        Text(
          '选择频道'.tr,
          style: Theme.of(context)
              .textTheme
              .bodyText2
              .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        sizeHeight22,
      ],
    ),
  );
}

class TopicsPopup extends StatefulWidget {
  final List<CircleTopicDataModel> topicList;

  const TopicsPopup({Key key, this.topicList = const []}) : super(key: key);

  @override
  _TopicsPopupState createState() => _TopicsPopupState();
}

class _TopicsPopupState extends State<TopicsPopup> {
  CirclePublishController get controller => GetInstance().find();

  List<CircleTopicDataModel> _topics = [];

  @override
  void initState() {
    _filterNoPermissionTopic();
    super.initState();
  }

  /// - 过滤掉没有发布权限的话题
  void _filterNoPermissionTopic() {
    _topics = widget.topicList
        .where((e) => e.type == CircleTopicType.common)
        .toList();
    if (PermissionUtils.isGuildOwner()) {
      return;
    }
    final GuildPermission gp = PermissionModel.getPermission(
        ChatTargetsModel.instance?.selectedChatTarget?.id);
    if (gp == null) {
      return;
    }

    final newTopics = _topics.where((element) {
      return PermissionUtils.oneOf(gp, [Permission.CIRCLE_POST],
          channelId: element.topicId);
    }).toList();
    _topics = newTopics;
  }

  @override
  Widget build(BuildContext context) {
    if (_topics.isEmpty) {
      return Center(
          child: Padding(
        padding: EdgeInsets.only(bottom: getBottomViewInset()),
        child: Text('暂无圈子频道，请联系管理员创建'.tr,
            style: TextStyle(
                color: CustomColor(context).disableColor, fontSize: 14)),
      ));
    }
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 17),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: Global.mediaInfo.size.height * 0.4),
              child: ObxValue<RxString>((selectedTopicId) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _topics.map((e) {
                    final isSelected = selectedTopicId.value == e.topicId;
                    return ChoiceChip(
                      pressElevation: 1,
                      selectedColor: appThemeData.primaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4))),
                      backgroundColor: appThemeData.scaffoldBackgroundColor,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          sizeWidth6,
                          Flexible(
                            child: Text(
                              e.type == CircleTopicType.all
                                  ? '最新'.tr
                                  : e.topicName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyText2
                                          .color,
                                  fontSize: 14,
                                  height: 1.25),
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        controller.selectedTopicId.value = e.topicId;
                        Routes.pop(context);
                      },
                    );
                  }).toList(),
                );
              }, controller.selectedTopicId),
            ),
          ),
        ],
      ),
    );
  }
}
