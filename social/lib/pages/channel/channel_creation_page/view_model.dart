import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/api/channel_api.dart';
import 'package:im/api/user_api.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/core/config.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/text_field/link_input.dart';
import 'package:oktoast/oktoast.dart';
import 'package:tuple/tuple.dart';

final Map<ChatChannelType, Tuple3> channelTypeInfo = {
  ChatChannelType.guildText: Tuple3(
      "文字频道".tr, IconFont.buffWenzipindaotubiao, IconFont.buffSimiwenzipindao),
  ChatChannelType.guildVoice: Tuple3(
      "语音频道".tr, IconFont.buffChannelMicLittle, IconFont.buffChannelVoicePriv),
  ChatChannelType.guildVideo: Tuple3("视频频道".tr,
      IconFont.buffChannelVideocamLittle, IconFont.buffChannelVideoPriv),
  ChatChannelType.guildLink:
      Tuple3("链接频道".tr, IconFont.buffChannelLink, IconFont.buffChannelLinkPriv),
  ChatChannelType.guildLive:
      Tuple3("直播频道".tr, IconFont.buffChannelLive, IconFont.buffChannelLivePriv),
};

class ViewModel extends ChangeNotifier {
  final String guildId;
  final String cateId;
  final ValueNotifier<bool> loading;

  bool _createLoading = false;
  String channelName = "";
  bool _videoCameraEnabled = false; // 是否允许创建音视频频道
  bool _liveEnabled = false; // 是否允许创建直播频道的权限

  // bool _enablePrivate = true; //直播频道和链接频道无法设置为私密

  String _channelLink = ''; //链接频道的链接
  LinkBean _channelLinkBean; //链接频道的

  bool _isPrivateChannel = false;
  ChatChannelType _channelType = ChatChannelType.guildText;
  List<Role> roleSelected = [];

  ViewModel({this.guildId, this.cateId, this.loading}) {
    UserApi.getAllowRoster('channel').then(setVideoCameraEnabled);
  }

  // 角色列表
  List<Role> guildRoles() {
    final List<Role> rs =
        List.from(PermissionModel.getPermission(guildId).roles);
    rs.removeWhere((r) {
      return r.id == guildId;
    }); // 去掉全体成员
    return rs;
  }

  bool get createLoading => _createLoading;

  void setCreateLoading(bool value) {
    if (loading != null)
      loading.value = value;
    else {
      _createLoading = value;
      notifyListeners();
    }
  }

  bool get videoCameraEnabled => _videoCameraEnabled;

  void setVideoCameraEnabled(bool value) {
    _videoCameraEnabled = value;
    _liveEnabled = Config.permission['live'] ?? false;
    notifyListeners();
  }

  // bool get enablePrivate => _enablePrivate;
  //
  // void setEnablePrivate(bool value) {
  //   _enablePrivate = value;
  //   notifyListeners();
  // }

  String get channelLink => _channelLink;

  void setChannelLink(LinkBean linkBean) {
    _channelLink = linkBean.toLinkString();
    _channelLinkBean = linkBean;
    notifyListeners();
  }

  bool get liveEnabled => _liveEnabled;

  void setLiveEnabled(bool value) {
    _liveEnabled = value;
    notifyListeners();
  }

  bool get isPrivateChannel => _isPrivateChannel;

  void setIsPrivateChannel(bool value) {
    _isPrivateChannel = value;
    notifyListeners();
  }

  void setRoleSelected(List<Role> value) {
    roleSelected = value;
    notifyListeners();
  }

  String endOfLiveString() {
    if (!_liveEnabled) return '（敬请期待）'.tr;
    if (hasLiveChannel) return '（已创建）'.tr;
    return '';
  }

  bool get disableLive => !_liveEnabled || hasLiveChannel;

  bool get hasLiveChannel {
    final target = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    bool result = false;
    for (int i = 0; i < target.channels?.length ?? []; ++i) {
      final element = target.channels[i];
      if (element.type == ChatChannelType.guildLive) {
        result = true;
        break;
      }
    }
    return result;
  }

  ChatChannelType get channelType => _channelType;

  void setChannelType(ChatChannelType value) {
    switch (value) {
      case ChatChannelType.guildText:
      case ChatChannelType.guildVoice:
      case ChatChannelType.guildVideo:
        // _enablePrivate = true;
        _channelLink = '';
        break;
      case ChatChannelType.guildLink:
      case ChatChannelType.guildLive:
        _isPrivateChannel = false;
        // _enablePrivate = false;
        roleSelected.clear();
        break;
      default:
        break;
    }
    _channelType = value;
    notifyListeners();
  }

  Future<void> create(BuildContext context) async {
    final _channelName = channelName.trim();
    FocusScope.of(context).unfocus();

    // 拦截非法数据
    if (_channelName.isEmpty) {
      showToast("请输入频道名称".tr);
      return;
    }

    if (isPrivateChannel && roleSelected.isEmpty) {
      showToast("请至少选择一个角色".tr);
      return;
    }

    ///如果是小程序链接频道，其中一个参数不能为空
    final linkBean = _channelLinkBean;
    final isCreateLink = _channelType == ChatChannelType.guildLink;
    if (isCreateLink && linkBean == null) {
      showToast("URL地址不能为空".tr);
      return;
    }
    if (linkBean != null && isCreateLink) {
      if (linkBean is WxProgramBean && linkBean.appId.isEmpty) {
        showToast("小程序原始ID不能为空".tr);
        return;
      } else if (linkBean is UrlBean && linkBean.path.isEmpty) {
        showToast("URL地址不能为空".tr);
        return;
      }
    }

    setCreateLoading(true);

    try {
      List<Map<String, dynamic>> permissionOverwrites = [];
      if (isPrivateChannel) {
        permissionOverwrites = [
          {
            "role_id": guildId,
            "action_type": "role",
            "allows": 0,
            "deny": Permission.VIEW_CHANNEL.value,
          }
        ];

        if (roleSelected.isNotEmpty) {
          final List<Map<String, dynamic>> rolePermissions =
              roleSelected.map((e) {
            return {
              "role_id": e.id,
              "action_type": "role",
              "allows": Permission.VIEW_CHANNEL.value,
              "deny": 0
            };
          }).toList();
          permissionOverwrites = [...permissionOverwrites, ...rolePermissions];
        }
      }

      final res = await ChannelApi.createChannel(
          guildId, Global.user.id, _channelName, channelType, cateId,
          permissionOverwrites: permissionOverwrites, link: _channelLink);
      showToast('创建成功'.tr);
      final _channelId = res['channel_id'];
      if (res != null && isNotNullAndEmpty(_channelId.toString())) {
        final _chatChannel = ChatChannel(
            id: _channelId,
            guildId: guildId,
            name: _channelName,
            type: channelType,
            parentId: cateId,
            link: _channelLink);

        // 如果有overwrite，扔到外面，通过add添加
        final overwrites = (res["permission_overwrites"] as List).map((e) {
          return PermissionOverwrite.fromJson(e);
        }).toList();

        /// 延迟 500ms 是为了服务器 push {type: string} 的消息被插入到本地数据库中
        await Future.delayed(const Duration(milliseconds: 500));
        setCreateLoading(false);
        Navigator.of(context).pop(Tuple2(_chatChannel, overwrites));
      }
    } catch (e) {
      setCreateLoading(false);
    }
  }
}
