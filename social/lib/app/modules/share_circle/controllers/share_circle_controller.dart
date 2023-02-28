import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/invite_code.dart';
import 'package:im/api/invite_api.dart';
import 'package:im/app/modules/circle/models/circle_post_data_model.dart';
import 'package:im/app/modules/circle/models/circle_post_data_type.dart';
import 'package:im/app/modules/circle/models/circle_share_poster_model.dart';
import 'package:im/app/modules/mute/controllers/mute_listener_controller.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/config.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

import '../../../../global.dart';
import '../../../../routes.dart';

class ShareBean {
  final CirclePostDataModel data;
  final Function onSend;
  final String guildId;
  final bool isLandFromCircleDetail;

  /// 是否从圈子列表点击进来
  final bool isFromList;

  ///用于海报分享
  final CircleSharePosterModel sharePosterModel;

  ShareBean({
    this.data,
    this.sharePosterModel,
    this.onSend,
    this.guildId,
    this.isLandFromCircleDetail = false,
    this.isFromList = false,
  });
}

class ShareCircleController extends GetxController {
  final ShareBean shareBean;

  final List<ChatChannel> channels = [];
  final List<bool> channelValue = [];

  final _selectedIndex = (-1).obs;

  int get select => _selectedIndex.value;

  set select(int index) => _selectedIndex.value = index;

  ///key为channelId
  final Map<String, ChatChannel> selectedChannels = {};

  bool get hasSelected => selectedChannels.isNotEmpty;

  bool isNetWorkNormal = true;
  GuildTarget _guildTargetModel;

  ShareCircleController(this.shareBean);

  String _shareUrl;
  String _shareUrlNoIc;

  /// * 分享链接
  String get shareUrl => shareUrlJoinFlag ? _shareUrl : _shareUrlNoIc;

  /// * 允许通过分享链接加入的开关: 默认为关
  bool shareUrlJoinFlag = false;

  /// * 是否有邀请权限
  bool hasInvitePermission;

  /// * 圈子topicID
  String get topicId => shareBean?.data?.postInfoDataModel?.topicId;

  /// * 圈子所属服务器名称
  String get guildName => _guildTargetModel?.name ?? "";

  /// * 圈子所属服务器头像
  String get guildIcon => _guildTargetModel?.icon ?? "";

  @override
  Future<void> onInit() async {
    super.onInit();
    circleShareClickButtonEvent(shareBean.isFromList);
    _guildTargetModel = ChatTargetsModel.instance
        .getGuild(shareBean.data.postInfoDataModel.guildId);

    if (_guildTargetModel != null) {
      _initialData();
    }
    final gp = PermissionModel.getPermission(shareBean.guildId);
    hasInvitePermission = PermissionUtils.oneOf(
        gp, [Permission.CREATE_INSTANT_INVITE],
        channelId: topicId);
    // print('getChat hasInvitePermission: $hasInvitePermission - guildId: ${shareBean.guildId}');

    update();
    await getShareUrl();
    update();
  }

  void _initialData() {
    _guildTargetModel.channels?.forEach((channel) {
      final isTextChannel = channel.type == ChatChannelType.guildText;
      final GuildPermission gp = PermissionModel.getPermission(channel.guildId);
      final canSendMes = PermissionUtils.oneOf(gp, [Permission.SEND_MESSAGES],
          channelId: channel.id);
      final isVisible = PermissionUtils.isChannelVisible(
          gp, channel.id); //[dj private channel]
      if (isTextChannel && canSendMes && isVisible) {
        channels.add(channel);
        channelValue.add(false);
      }
    });
  }

  void onOnItemClick(int index) {
    if (MuteListenerController.to.isMuted) {
      // 是否被禁言
      showToast('你已被禁言，无法操作'.tr);
      return;
    }

    circleShareDestinationEvent('fanbook_channel_id');
    select = index;
    selectedChannels.clear();
    if (index >= 0) {
      final channel = channels[index];
      selectedChannels[channel.id] = channel;

      onShareChannel(index);
    }
  }

  void onShareChannel(int index) {
    if (selectedChannels.isEmpty) return;
    _toShare();
    Get.back();
  }

  void _toShare() {
    final Set<ChatChannel> wrongSet = {};
    selectedChannels.forEach((key, value) {
      final GuildPermission gp = PermissionModel.getPermission(value.guildId);
      final canSendMes =
          PermissionUtils.oneOf(gp, [Permission.SEND_MESSAGES], channelId: key);
      final isChannelDeleted = _guildTargetModel.getChannel(value.id) == null;
      if (!canSendMes || isChannelDeleted) {
        wrongSet.add(value);
      } else {
        final liked = shareBean.data.postSubInfoDataModel.iLiked;

        ///由于目前"本人是否点赞过圈子"这个状态在分享到聊天界面中，无法被其他用户判断，所以这里默认处理为未点赞过
        shareBean.data.modifyILiked('0');
        final tcController = TextChannelController.to(channelId: key);
        tcController
            .sendContent(CircleShareEntity(data: shareBean.data),
                awaitDatabaseFinish: true)
            .then(
          (_) async {
            await Future.delayed(300.milliseconds);
            Routes.backHome();
            shareBean.data.modifyILiked(liked);
            unawaited(ChatTargetsModel.instance.selectChatTargetById(
                value.guildId,
                channelId: key,
                gotoChatView: true));
          },
        );
      }
    });
    if (wrongSet.isEmpty)
      showToast('😄 分享成功'.tr);
    else {
      String errorChannels = '';
      wrongSet.forEach((element) {
        final isLast = element == wrongSet.last;
        errorChannels += '#${element.name}${isLast ? '' : '、'.tr}';
      });
      showToast('😯%s 出现变动发送失败，请刷新频道列表重试'.trArgs([errorChannels]));
    }
  }

  Future<void> getShareUrl() async {
    final Map<String, dynamic> queryParameters = {};
    if (hasInvitePermission) {
      final inviteEntity = await _getInviteEntity();
      if (inviteEntity?.code != null) {
        queryParameters['ic'] = Uri.encodeComponent(inviteEntity.code);
      }
    }
    if (Config.env != Env.pro) {
      queryParameters['env'] = Config.env.toString().split('.')[1];
    }
    final shareUri = Uri(
      host: Config.h5CircleLinkHosts[Config.env],
      scheme: Config.httpScheme,
      path: 'circle/${shareBean.data.postId}',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    //shareUri.queryParameters.remove无法删除参数
    queryParameters.remove('ic');
    final shareUriNoIc = Uri(
      host: Config.h5CircleLinkHosts[Config.env],
      scheme: Config.httpScheme,
      path: 'circle/${shareBean.data.postId}',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    _shareUrl = shareUri.toString();
    _shareUrlNoIc = shareUriNoIc.toString();
  }

  Future<EntityInviteUrl> _getInviteEntity({
    int number,
    int time,
    String remark,
  }) async {
    // 已指定分享链接，不必再去请求获取分享链接
    final Map params = {
      'channel_id': topicId,
      'guild_id': shareBean.guildId,
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
      final res = await InviteApi.getInviteInfo(params);
      return res;
    } catch (e) {
      print(e);
      if (e is DioError) {
        print('net error');
      }
      if (e is RequestArgumentError) {
        if (e.code == 1012) {
          // showToast('该频道没有分享权限'.tr);
        }
      } else {
        showToast('网络异常，请检查后重试'.tr);
      }
      return null;
    }
  }

  String get title {
    if ((shareBean.data.dataInfo['post']['title'] as String)?.isEmpty == true) {
      if ((shareBean.data.dataInfo['post']['content_v2'] as String)?.isEmpty ==
          true) {
        return '$guildName 的圈子动态';
      } else if (shareBean.data.dataInfo['post']['content_v2'] != null) {
        List listContent;
        try {
          listContent =
              jsonDecode(shareBean.data.dataInfo['post']['content_v2']);
        } catch (e) {
          print(e);
        }
        String title = '';
        if (listContent != null && listContent.isNotEmpty) {
          for (int i = 0; i < listContent.length; i++) {
            if (listContent[i]['insert'] is String &&
                (listContent[i]['insert'] != '\n' &&
                    listContent[i]['insert'] != '\n\n')) {
              title = title + listContent[i]['insert'];
              if (title.length >= 100) break;
            }
          }
        }
        if (title.isEmpty) {
          return '$guildName 的圈子动态';
        } else {
          return title;
        }
      } else {
        return '$guildName 的圈子动态';
      }
    } else {
      return shareBean.data.dataInfo['post']['title'];
    }
  }

  String get image {
    if (shareBean.data?.postInfoDataModel?.firstMedia is Map) {
      if (shareBean.data?.postInfoDataModel?.firstMedia['_type'] ==
          CirclePostDataType.image) {
        return shareBean.data?.postInfoDataModel?.firstMedia['source'];
      } else if (shareBean.data?.postInfoDataModel?.firstMedia['_type'] ==
          CirclePostDataType.video) {
        return shareBean.data?.postInfoDataModel?.firstMedia['thumbUrl'];
      } else {
        return guildIcon;
      }
    } else {
      return guildIcon;
    }
  }

  /// 点击动态分享按钮
  void circleShareClickButtonEvent(bool isFromList) {
    DLogManager.getInstance().customEvent(
        actionEventId: 'circle_share_click_button',
        actionEventSubId: isFromList ? 'post_list' : 'post_detail',
        extJson: {"guild_id": shareBean.data.postInfoDataModel.guildId});
  }

  /// 点击选择分享动态目的地
  void circleShareDestinationEvent(String actionEventSubId) {
    DLogManager.getInstance().customEvent(
        actionEventId: 'circle_share_click_button',
        actionEventSubId: actionEventSubId,
        extJson: {"guild_id": shareBean.data.postInfoDataModel.guildId});
  }

  /// * 更新 shareUrlJoinFlag
  void updateShareUrlJoinFlag() {
    shareUrlJoinFlag = !shareUrlJoinFlag;
    update();
  }
}
