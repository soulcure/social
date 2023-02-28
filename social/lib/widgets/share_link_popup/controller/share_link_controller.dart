import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/invite_code.dart';
import 'package:im/api/invite_api.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/global.dart';
import 'package:im/global_methods/goto_direct_message.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/share_link_popup/share_dm_list_popup.dart';
import 'package:im/widgets/share_link_popup/share_link_report_manager.dart';
import 'package:oktoast/oktoast.dart';

import '../share_link_popup.dart';

class ShareLinkController extends GetxController {
  final String guildId;
  String copyPrefix;
  final String linkValue;
  final String title;
  final String desc;
  final String shareTitle;
  final String shareDesc;
  final String shareCover;
  final ChatChannel channel;
  final ShareLinkType linkType;

  ShareLinkController({
    this.guildId,
    this.copyPrefix,
    this.linkValue,
    this.title,
    this.desc,
    this.shareTitle,
    this.shareDesc,
    this.shareCover,
    this.channel,
    this.linkType = ShareLinkType.other,
  });

  int timesLeft = -1; // 剩余次数
  int minuteLeft = -1; // 剩余分钟数
  EntityInviteUrl link;
  bool linkLoadFailed = false;

  GuildTarget _guild;

  @override
  void onInit() {
    fetchInviteUrl();
    super.onInit();
  }

  Future<EntityInviteUrl> fetchInviteUrl({
    int number,
    int time,
    String remark,
  }) async {
    // 已指定分享链接，不必再去请求获取分享链接
    if (linkValue != null) return null;
    final Map params = {
      'channel_id': channel?.id,
      'guild_id': ChatTargetsModel.instance.selectedChatTarget.id,
      'user_id': Global.user.id,
      'v': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    if (number != null && time != null) {
      params['number'] = number;
      params['time'] = time;
      params['remark'] = remark;
      params['type'] = 1;
    } else {
      params['type'] = 2;
    }
    try {
      final value = await InviteApi.getInviteInfo(params);
      if (value?.url != null) {
        link = value;
        linkLoadFailed = false;
        timesLeft = int.parse(value.numberLess ?? '0');
        minuteLeft = int.parse(value.expire ?? '0');
      } else {
        link = null;
        linkLoadFailed = false;
      }
      update();
      return value;
    } catch (e) {
      if (e is DioError) {
        if (e.type != DioErrorType.cancel && e.type != DioErrorType.response) {
          link = null;
          linkLoadFailed = true;
          update();
        }
      }
      if (e is RequestArgumentError) {
        if (e.code == 1012) {
          showToast('该频道没有分享权限'.tr);
        }
      } else {
        showToast('网络异常，请检查后重试'.tr);
      }
      return null;
    }
  }

  Future<void> shareToUser(bool isMore, String userId) async {
    if (isLinkEmpty) return;
    if (isMore) {
      final List<UserInfo> users = await showShareDmListPopUp(Get.context);
      Get.back();
      if (users != null) {
        users.forEach((v) => _sendMessage(v.userId));
      }
    } else {
      final res =
          await showConfirmDialog(title: '提示'.tr, content: '确认分享链接 ？'.tr);
      if (res == true) {
        Get.back();
        _sendMessage(userId);
        showToast('😄 邀请链接已发送'.tr);
        ShareLinkReportManager.liveBehavior(
          getLink,
          'fanbook_friend',
          linkType,
        );
      }
    }
  }

  void _sendMessage(String userId) {
    sendDirectMessage(userId, TextEntity.fromString(getLink ?? ''));
  }

  void onCopy() {
    final content = getLink != null ? "$getCopyPrefix$getLink" : '';
    final ClipboardData data = ClipboardData(text: content);
    Clipboard.setData(data);
    showToast('链接已复制'.tr);
  }

  GuildTarget get guild {
    if (_guild != null) return _guild;
    if (guildId != null) {
      _guild = ChatTargetsModel.instance.getGuild(guildId);
    } else {
      _guild = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    }
    return _guild;
  }

  String get getCopyPrefix {
    return copyPrefix ??= "我正在「%s」服务器中聊天，来和我一起畅聊吧 ~ 点击加入：".trArgs([guild.name]);
  }

  /// 分享到三方平台的标题
  String get getShareTitle {
    /// 如果没有传入分享标题，则默认分享标题为服务器名
    return shareTitle ?? getCopyPrefix;
  }

  /// 分享到三方平台的描述
  String get getShareDesc {
    /// 如果没有传入分享描述，则默认为分享服务器的描述
    return shareDesc ?? link?.url ?? '';
  }

  /// 分享到三方平台的图片封面
  String get getShareCover {
    if (shareCover != null) return shareCover;
    if (isNotNullAndEmpty(guild.icon)) return guild.icon;
    return Global.logoUrl;
  }

  String get inviteLinkTitle {
    if (title.hasValue) {
      return title;
    }

    final name = channel?.name ??
        ChatTargetsModel.instance.selectedChatTarget?.name ??
        '';
    if (channel?.name != null)
      return '邀请好友加入 #%s'.trArgs([name ?? '']);
    else
      return '邀请好友加入 %s'.trArgs([name ?? '']);
  }

  String get description {
    if (desc.hasValue) {
      return desc;
    } else {
      return '分享此链接，朋友点击即可加入'.tr;
    }
  }

  bool get hasFriend => DirectMessageController.to.channelsDm.isNotEmpty;

  String get getLink => linkValue ?? link?.url;

  bool get isLinkEmpty => getLink.noValue;
}
