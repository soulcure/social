import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/future_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/circle/circle_setting/model/circle_management_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/ediit_string_popup.dart';
import 'package:im/widgets/fb_ui_kit/form/form_builder.dart';
import 'package:im/widgets/fb_ui_kit/form/form_fix_child_model.dart';
import 'package:oktoast/oktoast.dart';

/// - 话题管理
class CircleManagementPage extends StatefulWidget {
  final CircleInfoDataModel circleInfoDataModel;

  const CircleManagementPage(this.circleInfoDataModel, {Key key})
      : super(key: key);

  @override
  _CircleManagementPageState createState() => _CircleManagementPageState();
}

class _CircleManagementPageState extends State<CircleManagementPage> {
  CircleInfoModel _circleInfoState;
  TopicsModel _topicModel;
  StreamSubscription _subscription;
  final bgColor = appThemeData.scaffoldBackgroundColor;

  @override
  void initState() {
    super.initState();
    _circleInfoState = CircleInfoModel(widget.circleInfoDataModel);
    _topicModel = TopicsModel(
      _circleInfoState.channelId,
      _circleInfoState.guildId,
    );
    _topicModel.fetchTopics();
    _subscription = _circleInfoState.circleStream.listen((_) {
      CircleController.to?.refreshWidget();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FbAppBar.custom(
        '圈子设置'.tr,
        backgroundColor: bgColor,
      ),
      backgroundColor: bgColor,
      body: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFirstLabel(),
              _buildBasicInfo(),
              _buildSecondLabel(),
              _buildTopicList(),
              sizeHeight16,
            ],
          ),
        ),
      ),
    );
  }

  /// - 基础信息label
  Widget _buildFirstLabel() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 0, 6),
        child: Text(
          '基础信息'.tr,
          style: appThemeData.textTheme.bodyText2.copyWith(
            fontSize: 14,
            color: appThemeData.dividerColor.withOpacity(1),
          ),
        ));
  }

  /// - 圈子名称和ID
  Widget _buildBasicInfo() => Column(
        children: [
          StreamBuilder<String>(
            stream: _circleInfoState.circleNameStream,
            builder: (context, snapshot) => FbForm.common(
              "圈子名称".tr,
              position: FbFormPosition.top,
              suffixChildModel: FbFormLabelSuffixChild(
                snapshot.data ?? '',
                color: appThemeData.dividerColor.withOpacity(1),
              ),
              onTap: _editCircleName,
            ),
          ),
          FbForm.common(
            "圈子ID".tr,
            position: FbFormPosition.bottom,
            suffixChildModel: FbFormLabelSuffixChild(
              _circleInfoState.channelId ?? '',
              color: appThemeData.dividerColor.withOpacity(1),
            ),
            tailIcon: IconFont.buffChatCopy,
            onTap: () {
              Clipboard.setData(ClipboardData(text: _circleInfoState.channelId))
                  .unawaited;
              showToast("复制成功".tr);
            },
          ),
        ],
      );

  /// - 频道管理label
  Widget _buildSecondLabel() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
        child: Row(
          children: [
            Expanded(
                child: Text(
              '频道管理'.tr,
              style: appThemeData.textTheme.bodyText2.copyWith(
                fontSize: 14,
                color: appThemeData.dividerColor.withOpacity(1),
              ),
            )),
            GestureDetector(
                onTap: () async {
                  final index = await showCustomActionSheet([
                    Text(
                      '创建圈子频道'.tr,
                      style: appThemeData.textTheme.bodyText2
                          .copyWith(fontSize: 16),
                    ),
                    Text(
                      '圈子频道排序'.tr,
                      style: appThemeData.textTheme.bodyText2
                          .copyWith(fontSize: 16),
                    ),
                  ]);
                  if (index == 0) {
                    unawaited(_editTopicName());
                  } else if (index == 1) {
                    unawaited(Routes.pushTopicEditorPage(context, _topicModel));
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  alignment: Alignment.center,
                  child: Icon(
                    IconFont.buffMoreHorizontal,
                    color: appThemeData.iconTheme.color,
                    size: 18,
                  ),
                )),
          ],
        ));
  }

  Future _editCircleName() async {
    unawaited(showEditStringPopup(context,
        title: '设置名称'.tr,
        initContent: _circleInfoState.circleName,
        placeholder: '请输入圈子名称'.tr,
        maxLength: 30, saveAction: (str) async {
      if (str.trim().noValue) {
        showToast("圈子名称不能为空".tr);
        return;
      }
      try {
        await _circleInfoState.updateCircleName(str.trim());
        Get.back();
      } catch (e) {
        logger.warning("编辑圈子名称失败");
      }
    }));
  }

  Future<void> _editTopicName() async {
    unawaited(showEditStringPopup(context,
        title: '创建圈子频道'.tr,
        placeholder: '请输入圈子频道名称'.tr,
        maxLength: 30, saveAction: (str) async {
      if (!str.hasValue) {
        showToast("圈子频道名称不能为空".tr);
        return;
      }

      // 编辑存在相同话题,提示已存在
      if (_topicModel.hasTopic(str.trim())) {
        showToast("圈子频道已存在".tr);
        return;
      }

      try {
        // 创建话题接口
        await _topicModel.addTopic(str.trim(), _topicModel.guildId);
        Get.back();
      } catch (e) {
        print(e);
      }
    }));
  }

  /// - 话题频道列表
  Widget _buildTopicList() => StreamBuilder<List<CircleTopicDataModel>>(
        stream: _topicModel.topicsStream,
        builder: (context, snapshot) {
          //  - 没有数据就不展示
          if (snapshot.connectionState == ConnectionState.waiting ||
              _topicModel.topics == null) {
            return sizedBox;
          }
          //  - 遍历数据
          final List<CircleTopicDataModel> topics = _topicModel.topics
              .where((e) => e.type != CircleTopicType.all)
              .toList();
          //  - 创建表单
          final List<FbForm> forms = [];
          for (var i = 0; i < topics.length; i++) {
            final CircleTopicDataModel topic = topics[i];
            forms.add(FbForm.common(
              topic.topicName,
              position: topics.length == 1
                  ? FbFormPosition.singleLine
                  : i == 0
                      ? FbFormPosition.top
                      : i == topics.length - 1
                          ? FbFormPosition.bottom
                          : FbFormPosition.middle,
              onTap: () => Routes.pushTopicNameEditorPage(
                context,
                _topicModel,
                topicIndex: i + 1,
              ),
            ));
          }
          return Column(
            children: forms,
          );
        },
      );

  @override
  void dispose() {
    super.dispose();
    _circleInfoState?.dispose();
    _topicModel?.dispose();
    _subscription?.cancel();
  }
}
