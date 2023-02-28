import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/controllers/circle_topic_controller.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/modules/mute/controllers/mute_listener_controller.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/stick/landscape_circle_stick_create_dialog.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_item.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/utils/confirm_dialog/message_box.dart';
import 'package:im/widgets/toast.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

import '../stick/circle_pin_create_dialog.dart';
import 'menu_button.dart';

/// * 圈子详情页 和 沉浸式 - 右上角菜单
class MenuButtonModel extends ChangeNotifier {
  final CirclePostDataModel data;
  final Function(MenuButtonType type, {List param}) onRequestSuccess;
  final Function(int code, MenuButtonType type) onRequestError;
  final VoidCallback updateLoading;

  MenuButtonModel({
    this.data,
    this.onRequestSuccess,
    this.onRequestError,
    this.updateLoading,
  }) {
    if (circlePermission) {
      refreshStickList();
    }
  }

  bool _loading = false;

  bool get loading => _loading;

  void setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
    if (updateLoading != null) updateLoading();
  }

  ///是否有'管理圈子权限'
  bool get circlePermission {
    final GuildPermission gp = PermissionModel.getPermission(guildId);
    if (gp != null) {
      return PermissionUtils.oneOf(gp, [Permission.MANAGE_CIRCLES]);
    }
    return false;
  }

  ///是否作者
  bool get isAuthor => data?.userDataModel?.userId == Global.user.id;

  bool get canReport => !isAuthor;

  bool get canDel => isAuthor || circlePermission;

  bool get canStick => circlePermission && !isPinnedDynamic();

  bool get canUnStick => circlePermission && isPinnedDynamic();

  bool get canModify => _hasPostMomentPermission() && isAuthor;

  ///修改所属频道
  bool get canModifyTopic => circlePermission && !isAuthor;

  String get guildId => data?.postInfoDataModel?.guildId ?? '';

  String get channelId => data?.postInfoDataModel?.channelId ?? '';

  String get postId => data?.postInfoDataModel?.postId;

  /// * 置顶的动态列表
  List<CirclePinedPostDataModel> pinnedList = [];

  /// * 圈子所有频道
  List<CircleTopicDataModel> allCircleTopicList = [];

  /// * 刷新置顶动态列表
  Future refreshStickList() async {
    try {
      final res = await CircleApi.circleDynamicPinList(guildId, channelId,
          showToast: false);
      final List records = res['records'] ?? [];
      pinnedList =
          records.map((e) => CirclePinedPostDataModel.fromJson(e)).toList();
    } catch (e) {
      logger.severe('refreshPinnedList error', e);
    }
  }

  /// * 动态是否置顶
  bool isPinnedDynamic() {
    for (final dataModel in pinnedList) {
      if (dataModel.postId == postId) {
        return true;
      }
    }
    return false;
  }

  /// * 从服务端获取topic列表
  Future<List<CircleTopicDataModel>> getTopicList(BuildContext context) async {
    Timer timer;
    try {
      timer = Timer(2.seconds, () {
        Loading.show(context);
      });
      final List topicRes =
          await CircleApi.getTopics(guildId, channelId: channelId);
      allCircleTopicList =
          topicRes.map((e) => CircleTopicDataModel.fromJson(e)).toList();
    } catch (_) {}
    timer?.cancel();
    Loading.hide();
    return allCircleTopicList;
  }

  /// - 是否有发布动态的权限
  bool _hasPostMomentPermission() {
    if (PermissionUtils.isGuildOwner(guildId: guildId)) return true;
    if (guildId.noValue) return true;
    final GuildPermission gp = PermissionModel.getPermission(guildId);
    if (gp == null) return true;

    final permission = PermissionUtils.oneOf(gp, [Permission.CIRCLE_POST],
        channelId: data.postInfo['topic_id'] ?? '');
    return permission;
  }

  ///显示动态详情的菜单
  Future showCircleDetailMenu(BuildContext context) async {
    final List<String> actions = [
      if (canUnStick) "unpin",
      if (canStick) "pin",
      if (canModify) "modify",
      if (canModifyTopic) "modifyTopic",
      if (canDel) "del",
      if (canReport) "report",
    ];
    final List<Widget> actionWidgets = [
      if (canUnStick)
        Text("取消置顶".tr,
            style: const TextStyle(fontSize: 17, color: Color(0xff1F2125))),
      if (canStick)
        Text("置顶动态".tr,
            style: const TextStyle(fontSize: 17, color: Color(0xff1F2125))),
      if (canModify)
        Text("编辑动态".tr,
            style: const TextStyle(fontSize: 17, color: Color(0xff1F2125))),
      if (canModifyTopic)
        Text("修改所属频道".tr,
            style: const TextStyle(fontSize: 17, color: Color(0xff1F2125))),
      if (canDel)
        Text("删除动态".tr,
            style:
                const TextStyle(fontSize: 17, color: DefaultTheme.dangerColor)),
      if (canReport)
        Text("举报".tr,
            style: const TextStyle(fontSize: 17, color: Color(0xff1F2125))),
    ];
    final index = await showCustomActionSheet(actionWidgets,
        routeDuration: const Duration(milliseconds: 150));
    if (index == null || index < 0) return;
    switch (actions[index]) {
      case "unpin":
        unStickMessage(context);
        break;
      case "pin":
        // 这个等待是因为，showCustomActionSheet的pop时间，如果不等待，直接弹出dialog，背景就会闪烁
        await Future.delayed(const Duration(milliseconds: 150));
        unawaited(stickMessage(context));
        break;
      case "report":
        reportMessage(context);
        break;
      case "del":
        if (isAuthor) {
          ///作者：直接删除
          deleteMessage(context);
        } else {
          ///非作者：打开删除理由页面
          final topicId = data?.postInfoDataModel?.topicId ?? data.topicId;
          final postId = data?.postInfoDataModel?.postId ?? data.postId;
          unawaited(Routes.pushCircleDeletePage(
              context, channelId, topicId, postId,
              onSuccess: onRequestSuccess, onError: onRequestError));
        }
        break;
      case "modify":
        unawaited(modifyMessage(context));
        break;
      case "modifyTopic":
        unawaited(showTopicPopup(context));
        break;
      default:
    }
  }

  /// * 置顶动态
  Future<void> stickMessage(BuildContext context) async {
    final data = this.data.postInfoDataModel;
    final title = data.title != null && data.title.isNotEmpty
        ? subRichString(data.title, 30)
        : null;
    final result = OrientationUtil.portrait
        ? await showCirclePinCreateDialog(context, title: title)
        : await showLandscapeCircleStickCreateDialog(context, title: title);
    if (result != null &&
        result.containsKey('title') &&
        result.containsKey('type')) {
      //审核置顶标题
      final name = result['title'];
      //审核文字
      final textRes = await CheckUtil.startCheck(
          TextCheckItem(name, TextChannelType.FB_CIRCLE_POST_TEXT),
          toastError: false);
      if (!textRes) {
        showToast('此内容包含违规信息,请修改后重试'.tr);
        return;
      }

      setLoading(true);
      try {
        await CircleApi.pinCircleDynamic(
            data.channelId,
            data.topicId,
            data.postId,
            result['title'],
            "${int.tryParse(result['type'] ?? "0") + 1}",
            showToast: false);
        showToast('置顶成功'.tr);
        refreshCirclePinnedList();
      } catch (e) {
        if (e is RequestArgumentError) {
          refreshCirclePinnedList();
          onRequestError?.call(e.code, MenuButtonType.pin);
        } else
          showToast('网络异常，请检查后重试'.tr);
      }
      setLoading(false);
    }
  }

  // void copyPostId() {
  //   Clipboard.setData(
  //       ClipboardData(text: data?.postInfoDataModel?.postId ?? ''));
  //   showToast('动态ID已复制'.tr);
  // }

  /// * 取消置顶动态
  void unStickMessage(BuildContext context) {
    Future<void> _unStickMessage() async {
      setLoading(true);
      final data = this.data.postInfoDataModel;
      try {
        await CircleApi.unpinCircleDynamic(
            data.channelId, data.topicId, data.postId,
            showToast: false);
        showToast('已取消置顶'.tr);
        refreshCirclePinnedList();
      } catch (e) {
        if (e is RequestArgumentError) {
          refreshCirclePinnedList();
          onRequestError?.call(e.code, MenuButtonType.unpin);
        } else
          showToast('网络异常，请检查后重试'.tr);
      }
      setLoading(false);
    }

    final theme = Theme.of(context);
    if (OrientationUtil.portrait)
      showCustomActionSheet([
        Text(
          "确定".tr,
          style: theme.textTheme.bodyText1
              .copyWith(color: DefaultTheme.dangerColor),
        )
      ], title: "确定取消这条置顶吗？\n取消后，圈子首页将不再显示这条动态".tr)
          .then((index) {
        if (0 == index) unawaited(_unStickMessage());
      });
    else
      showWebMessageBox(
          title: '提示'.tr,
          content: '确定取消这条置顶吗？\n取消后，圈子首页将不再显示这条动态'.tr,
          onConfirm: () {
            _unStickMessage();
            Get.back();
          });
  }

  /// * 刷新两个页面的置顶列表
  void refreshCirclePinnedList() {
    try {
      unawaited(refreshStickList().then((value) {
        if (Get.isRegistered<CircleController>()) {
          if (CircleController.to.guildId == guildId)
            CircleController.to.refreshPinnedList(list: pinnedList);
        }
      }));
    } catch (_) {}
  }

  void reportMessage(BuildContext context) {
    final user = data.userDataModel;
    Routes.pushToTipOffPage(
      context,
      guildId: guildId,
      accusedUserId: user?.userId,
      accusedName: user?.nickName,
    );
  }

  /// - 编辑动态
  Future modifyMessage(BuildContext context) async {
    if (MuteListenerController.to.isMuted) {
      // 是否被禁言
      showToast('你已被禁言，无法操作'.tr);
      return;
    }

    unawaited(MediaChannelApi.init(
        logEvent: (actionId, actionSubId, actionEventSubParam, extJson) {
      DLogManager.getInstance().customEvent(
          actionEventId: actionId,
          actionEventSubId: actionSubId,
          actionEventSubParam: actionEventSubParam,
          extJson: {"guild_id": guildId});
    }));
    final content = data.postInfoDataModel.postContent() ??
        RichEditorUtils.defaultDoc.encode();
    final tcDoc =
        data.docItem != null ? json.encode(data.docItem.toJson()) : '';
    final backTopicId = data.postInfoDataModel.topicId;

    final topList = await getTopicList(context);
    if (topList == null || topList.isEmpty) return;

    final model = await Routes.pushCreateMomentPage(context,
        data.postInfoDataModel.guildId, data.postInfoDataModel.channelId,
        circleDraft: CirclePostInfoDataModel(
          guildId: data.postInfoDataModel.guildId,
          channelId: data.postInfoDataModel.channelId,
          content: content,
          title: data.postInfoDataModel.title,
          topicId: data.postInfoDataModel.topicId,
          postId: data.postInfoDataModel.postId,
          tcDocContent: tcDoc,
        ),
        topics: topList);
    if (model != null) {
      final topic = topList.firstWhere(
          (element) => element.topicId == model.topicId,
          orElse: () => null);
      if (topic != null) {
        model.topicName = topic.topicName;
      } else if (model.topicName.noValue)
        model.topicName = data.postInfoDataModel.topicName;
      data.postInfoDataModel = model;
      model.updatedAt = '${DateTime.now().millisecondsSinceEpoch}';
      try {
        if (backTopicId == data.postInfoDataModel.topicId)
          CircleController.to.updateItem(data.postInfoDataModel.topicId, data);
        else {
          // 改动后，topicId 发生了变化
          CircleController.to
              .removeItem(backTopicId, data.postInfoDataModel.postId);
          CircleTopicController.to(topicId: data.postInfoDataModel.topicId)
              .insertItem(0, data);

          /// 最新(全部)的topicId就是channelId
          final allTopicId = data.postInfoDataModel.channelId;

          // 如果全部里面有该item就更新，没有就插入
          if (CircleTopicController.to(topicId: allTopicId).list.indexWhere(
                  (element) =>
                      element.postId == data.postInfoDataModel.postId) >=
              0) {
            CircleController.to.updateItem(allTopicId, data);
          } else {
            CircleTopicController.to(topicId: allTopicId).insertItem(0, data);
          }
        }
        // 如果不是从圈子首页进入，这里的controller都寻不到，throw exception是正常的
        // ignore: empty_catches
      } catch (e) {}
      onRequestSuccess?.call(MenuButtonType.modify);
    }

    return model;
  }

  /// * 直接删除动态
  void deleteMessage(BuildContext context) {
    Future<void> _deleteMessage() async {
      setLoading(true);
      try {
        await CircleApi.circlePostDelete(data.postInfoDataModel.postId,
            data.postInfoDataModel.channelId, data.postInfoDataModel.topicId,
            showToast: false);
        Toast.iconToast(icon: ToastIcon.success, label: "动态已删除".tr);
        final postInfo = postInfoMap[data.postInfoDataModel.postId];
        postInfo?.setData(deleted: true);
        try {
          if (Get.isRegistered<CircleController>()) {
            CircleController.to
              ..removeItem(
                  data.postInfoDataModel.topicId, data.postInfoDataModel.postId)
              ..loadSubscriptionList();
            if (isPinnedDynamic()) refreshCirclePinnedList();
          }
        } catch (_) {}
        setLoading(false);
        onRequestSuccess?.call(MenuButtonType.del);
      } catch (e) {
        setLoading(false);
        if (e is RequestArgumentError) {
          onRequestError?.call(e.code, MenuButtonType.del);
          if (isPinnedDynamic()) refreshCirclePinnedList();
        } else
          showToast('网络异常，请检查后重试'.tr);
      }
    }

    if (OrientationUtil.landscape) {
      showWebMessageBox(
          title: '提示'.tr,
          content: '确认删除此动态'.tr,
          onConfirm: () async {
            await _deleteMessage();
            Get.back();
          });
    } else {
      showCustomActionSheet([
        Text(
          "确认删除此动态".tr,
          style: Theme.of(context)
              .textTheme
              .bodyText1
              .copyWith(color: DefaultTheme.dangerColor),
        )
      ]).then((value) {
        if (value == 0) _deleteMessage();
      });
    }
  }

  ///修改所属频道弹窗
  Future<String> showTopicPopup(BuildContext context) async {
    var topics = await getTopicList(context);
    topics = topics?.where((e) => e.type == CircleTopicType.common)?.toList();
    if (topics == null || topics.isEmpty) {
      showToast('没有可用的圈子频道'.tr);
      return null;
    }
    final preTopicId = data?.postInfoDataModel?.topicId;
    final selTopicId = await showBottomModal(
      context,
      builder: (c, s) => _buildTopicSelector(context, topics, preTopicId),
      maxHeight: 0.5,
      backgroundColor: CustomColor(context).backgroundColor6,
      resizeToAvoidBottomInset: false,
      scrollSpec: const ScrollSpec(physics: AlwaysScrollableScrollPhysics()),
      headerBuilder: (c, s) => Column(
        children: [
          sizeHeight16,
          Text(
            '选择圈子频道'.tr,
            style: Theme.of(context)
                .textTheme
                .bodyText2
                .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          sizeHeight22,
        ],
      ),
    );
    if (selTopicId != null && selTopicId != preTopicId) {
      setLoading(true);
      try {
        final selTopic =
            topics?.firstWhereOrNull((e) => e.topicId == selTopicId);
        final topicName = selTopic?.topicName;
        final res = await CircleApi.circleTopicUp(
          data.postInfoDataModel.guildId,
          data.postInfoDataModel.channelId,
          data.postInfoDataModel.postId,
          preTopicId,
          selTopicId,
        );
        Toast.iconToast(icon: ToastIcon.success, label: "修改成功".tr);
        final updatedAt = res['updated_at']?.toString();
        data.postInfoDataModel.topicId = selTopicId;
        data.postInfoDataModel.topicName = topicName;
        data.postInfoDataModel.updatedAt =
            updatedAt ?? '${DateTime.now().millisecondsSinceEpoch}';

        /// 最新(全部)的topicId就是channelId
        final allTopicId = data.postInfoDataModel.channelId;
        _updateListItem(
            allTopicId: allTopicId,
            backTopicId: preTopicId,
            selTopicId: selTopicId);
        onRequestSuccess
            ?.call(MenuButtonType.modifyTopic, param: [selTopicId, topicName]);
        setLoading(false);
        return selTopicId;
      } catch (e) {
        setLoading(false);
        if (e is RequestArgumentError) {
          onRequestError?.call(e.code, MenuButtonType.modify);
        } else {
          showToast('网络异常，请检查后重试'.tr);
        }
      }
    }
    return null;
  }

  ///更新圈子列表的动态
  void _updateListItem(
      {String allTopicId, String backTopicId, String selTopicId}) {
    try {
      CircleController.to;

      /// 改动后，topicId 发生了变化
      // 原有tab要删除
      CircleTopicController.to(topicId: backTopicId).removeItem(postId);
      // 新tab要更新
      CircleTopicController.to(topicId: selTopicId).loadData();
      // 全部tab要更新
      CircleTopicController.to(topicId: allTopicId).updateItem(postId, data);
    } catch (e) {
      // print('getChat _updateListItem e: $e');
    }
  }

  Widget _buildTopicSelector(BuildContext context,
      List<CircleTopicDataModel> topics, String preSelTopicId) {
    if (topics == null || topics.isEmpty) {
      return Center(
          child: Text('暂无圈子频道，请联系管理员创建'.tr,
              style: TextStyle(
                  color: CustomColor(context).disableColor, fontSize: 14)));
    }

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 5, 17, 17),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: Global.mediaInfo.size.height * 0.4),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: topics.map((e) {
                  final isSelected = preSelTopicId == e.topicId;
                  return ChoiceChip(
                    pressElevation: 1,
                    selectedColor: primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16))),
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconFont.buffPoundSign,
                          size: 14,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyText2.color,
                        ),
                        sizeWidth3,
                        Flexible(
                          child: Text(
                            e.topicName,
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
                                height: 1.2),
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      Routes.pop(context, e.topicId);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
