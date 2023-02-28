import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/app/modules/accept_invite/controllers/accept_invite_param.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/app/modules/task/welcome_util.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/db.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/bot_market/model/channel_cmds_model.dart';
import 'package:im/pages/chat_index/components/ui_channel_no_permission_alert.dart';
import 'package:im/pages/guild_setting/guild/quit_guild.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/quest/fb_quest_config.dart';
import 'package:im/routes.dart';
import 'package:im/utils/deeplink_processor.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:quest_system/internal/quest.dart';
import 'package:quest_system/internal/trigger/custom_trigger.dart';
import 'package:quest_system/internal/trigger/quest_trigger.dart';

enum RequestStatus {
  waiting,
  success,
  error,
}

enum JoinGuildEnum {
  succeed,
  fail,
  joined, //  已加入服务器
  addInfo, // 需要完善个人资料
  disbanded, // 服务器已解散
  inviteExpired, // 邀请链接已失效
}

class AcceptInviteController extends GetxController {
  String guildId;
  String channelId;
  String postId;
  String inviteCode;
  DeepLinkTaskNotifier notifier;
  bool isExpire;
  String inviterId;

  final RxBool isLoading = false.obs;
  final RxString guildIcon = ''.obs;
  final RxString guildName = ''.obs;
  final RxString authenticate = '0'.obs;
  final RxInt memberNum = 0.obs;
  final RxBool joined = false.obs;
  final Rx<RequestStatus> requestStatus = RequestStatus.waiting.obs;

  final RxString inviterNickname = ''.obs;
  final RxString inviterAvatar = ''.obs;

  /// 是否是通过三方app唤起的
  bool get fromThirdPart => notifier != null;

  @override
  void onInit() {
    super.onInit();

    final AcceptInviteParam param = Get.arguments;
    if (param != null) {
      guildId = param.guildId;
      channelId = param.channelId;
      postId = param.postId;
      inviteCode = param.inviteCode;
      notifier = param.notifier;
      isExpire = param.isExpire;
      inviterId = param.inviterId;

      /// 获取邀请者的头像与昵称
      UserInfo.get(inviterId).then((res) {
        inviterNickname.value = res.showName();
        inviterAvatar.value = res.avatar;
      });

      fetchGuildInfo();
    }
  }

  Future<void> fetchGuildInfo() async {
    try {
      /// 将状态置为请求中
      requestStatus.value = RequestStatus.waiting;

      final res = await GuildApi.getGuildInfo(
        guildId: guildId,
        userId: Global.user.id,
      );

      guildIcon.value = res['icon'];
      guildName.value = res['name'];
      memberNum.value = res['memberNum'];
      authenticate.value = res['authenticate']?.toString();
      joined.value = res['join'] ?? false;

      /// 将状态置为请求成功
      requestStatus.value = RequestStatus.success;
    } catch (e, s) {
      print("fetchGuildInfo error: $e\n$s");
      requestStatus.value = RequestStatus.error;
    }
  }

  /// 接受邀请
  Future<void> onAccept() async {
    if (isLoading.value) return Future.value();
    isLoading.value = true;
    try {
      if (fromThirdPart) {
        final result = await joinGuild(
          guildId,
          inviteCode: inviteCode,
          channelId: channelId,
          postId: postId,
        );
        _joinAndEnterGuild(result);
        if (notifier != null) {
          notifier.onSuccess();
        }
      } else {
        //  清除myGuild2接口用hash，确保其他端拉取时不会出现204
        unawaited(Db.userConfigBox.delete(UserConfig.myGuild2Hash));
        final result = await joinGuild(
          guildId,
          inviteCode: inviteCode,
          channelId: channelId,
          postId: postId,
        );
        _joinAndEnterGuild(result);
      }
    } catch (e, s) {
      logger.info('onAccept error:', e, s);
      isLoading.value = false;
    }
  }

  /// 处理进入服务器后的相关业务事项
  void _joinAndEnterGuild(result) {
    /// NOTE: 2021/12/24 防止外部异步调用会影响currentContext
    final context = Global.navigatorKey.currentContext;
    switch (result) {
      case JoinGuildEnum.succeed:
        {
          Routes.backHome();
          final isEnter = _enterGuild(context);
          if (isEnter) {
            /// 新加入服务者弹出欢迎bottomSheet
            final guildInfo = ChatTargetsModel.instance?.getGuild(guildId);
            if (guildInfo?.userPending == false) {
              /// TODO: 2021/12/24 路由相关的操作未作梳理
              WelcomeUtil.welcomeInterface(guildId);
            }
          }

          /// 触发新服务器引导任务检查
          Future.delayed(const Duration(milliseconds: 400), () {
            CustomTrigger.instance.dispatch(
              const QuestTriggerData(
                condition: QuestCondition([FbQuestId.firstEntryServer]),
              ),
            );
          });
          break;
        }
        break;
      case JoinGuildEnum.joined:
        {
          // 已加入，返回Home并进入服务器
          Routes.backHome();
          _enterGuild(context);
          break;
        }
      case JoinGuildEnum.inviteExpired:
        {
          Routes.backHome();
          showConfirmDialog(
            title: '邀请链接已失效'.tr,
            content: '可能是达到有效期/最多使用次数、服务器已解散，或你已被移出服务器，请尝试获取新的邀请链接再加入'.tr,
            showCancelButton: false,
            confirmText: '知道了'.tr,
          );
          break;
        }
      //不做处理，停留在该页面
      case JoinGuildEnum.disbanded:
      case JoinGuildEnum.fail:
      case JoinGuildEnum.addInfo:
        break;
    }

    isLoading.value = false;
  }

  bool _enterGuild(BuildContext context) {
    try {
      ChannelCmdsModel.instance.updateGuildChannelCmds(guildId);
    } catch (e, s) {
      /// 此处捕获ChannelCmdsModel.instance是否为null的异常，记录异常即可
      logger.info('onAccept error', e, s);
    }
    final context = Global.navigatorKey.currentContext;
    // 如果加入的是私密频道，则需要判断权限
    return enterChannel(
      guildId: guildId,
      channelId: channelId,
      context: context,
    );
  }

  /// 跳转至首页服务器
  Future goToGuild() {
    if (fromThirdPart) {
      notifier.onError(DeepLinkTaskErrCode.SUCCESS);
      return Future.value();
    }

    return gotoJoinedGuild(
      guildId: guildId,
      channelId: channelId,
    );
  }

  /// 跳转至首页服务器
  void webGoToGuild() {
    Routes.backHome();
    ChatTargetsModel.instance
        .selectChatTargetById(guildId, channelId: channelId);

    HomeScaffoldController.to.gotoWindow(1);
  }

  @override
  void onClose() {
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
  }

  /// 加入服务器并且进入这个服务器
  Future<JoinGuildEnum> joinGuild(String guildId,
      {String inviteCode = "", String channelId, String postId}) async {
    if (channelId == "0" || channelId == null) channelId = "";
    JoinGuildEnum result = JoinGuildEnum.fail;

    try {
      /// NOTE: 2021/12/17 正式加入服务器
      await GuildApi.join(
        guildId: guildId,
        userId: Global.user.id,
        c: inviteCode,
        postId: postId,
      );

      result = JoinGuildEnum.succeed;

      /// 上报状态
      DLogManager.getInstance().customEvent(
        actionEventId: 'join_server',
        actionEventSubId: '1',
        pageId: 'page_join_server',
        extJson: {
          "invite_code": inviteCode,
          'guild_id': guildId,
        },
      );
    } on RequestArgumentError catch (e) {
      switch (e.code) {
        case 1050:
          showToast("请先完善个人资料".tr);
          result = JoinGuildEnum.addInfo;
          break;
        case 1010:

          /// NOTE: 2022/1/17 当出现网络超时时，服务端有可能会加入成功，但是未正确返回
          // showToast('已加入服务器'.tr);
          result = JoinGuildEnum.joined;
          break;
        case 1011:
          showToast('服务器已解散'.tr);
          result = JoinGuildEnum.disbanded;
          break;
        default:
          result = JoinGuildEnum.inviteExpired;
          break;
      }
    } catch (e) {
      if (e is DioError && e.type == DioErrorType.connectTimeout) {
        showToast(networkErrorText);
      }
      // 无论是否是因为加入失败的原因，都上报异常
      DLogManager.getInstance().customEvent(
        actionEventId: 'join_server',
        actionEventSubId: '0',
        actionEventSubParam: e?.toString(),
        pageId: 'page_join_server',
        extJson: {
          "invite_code": inviteCode,
          'guild_id': guildId,
        },
      );
    }

    if (result == JoinGuildEnum.succeed || result == JoinGuildEnum.joined) {
      try {
        /// 获取数据并刷新，先不做backHome，并且必须保证数据
        await _joinGuild(guildId);
      } catch (e) {
        logger.info('join Guild error', e);
        print(e);
      }
    }

    return result;
  }

  /// 如果想加入并且进入服务器，使用 [joinGuild]
  Future<void> _joinGuild(String guildId) async {
    try {
      /// NOTE: 2021/12/24 此处会拉取一次数据，并设置权限相关信息
      final guild = await GuildApi.getFullGuildInfo(
          guildId: guildId, userId: Global.user.id);
      guild.sortChannels();
      unawaited(_cleanGuild(guild));
      ChatTargetsModel.instance.addChatTarget(guild);
    } catch (e) {
      logger.info('进入服务器异常', e);
    }
  }

  Future<void> _cleanGuild(GuildTarget guild) async {
    guild.channels.forEach((element) {
      InMemoryDb.remove(element.id);

      ///fix 退出服务台再进去服务台，_remoteSynchronized=false,导致无法设置未读计数
      Db.lastMessageIdBox.delete(element.id);
    });
    await ChatTable.batchClearChatHistory(
        guild?.id, guild?.channels?.map((e) => e.id) ?? []);
  }

  bool enterChannel({
    @required String guildId,
    @required String channelId,
    @required BuildContext context,
  }) {
    bool succeed = false;

    /// NOTE: 2021/12/20 没有权限进入的时候，不需要显示欢迎页面
    final gpNew = PermissionModel.getPermission(guildId);
    final isVisibleNew = PermissionUtils.isChannelVisible(gpNew, channelId);
    if (!isVisibleNew && (channelId?.isNotEmpty ?? false)) {
      // 没有权限的渠道，要求进频道，跳转到服务器，进入默认渠道
      UIChannelNoPermissionAlert.showNoPermissionAlert(context: context);

      /// TODO: 2021/12/24 异步调用，并且没有在内部处理异常
      ChatTargetsModel.instance.selectChatTargetById(guildId, channelId: "");
    } else {
      _selectChatTarget(guildId, channelId);
      succeed = true;
    }

    return succeed;
  }

  // 圈子类型的频道不需要选中
  void _selectChatTarget(String guildId, String channelId) {
    bool shouldSelectChannel = false;
    if (channelId.hasValue) {
      final channel = ChatTargetsModel.instance.getChannel(channelId);
      shouldSelectChannel =
          channel != null && channel.type != ChatChannelType.guildCircleTopic;
    }

    /// TODO: 2021/12/24 异步调用，并且没有在内部处理异常
    unawaited(ChatTargetsModel.instance.selectChatTargetById(guildId,
        channelId: shouldSelectChannel ? channelId : null,
        gotoChatView: shouldSelectChannel));
  }
}
