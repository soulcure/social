import 'package:get/get.dart';
import 'package:im/api/channel_api.dart';
import 'package:im/api/user_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/config.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/text_field/link_input.dart';

import '../../../global.dart';

class CreateChannelResponse {
  static const CodeSuccess = 0;
  static const CodeError = 1;

  int code;
  ChatChannel channel;
  List<PermissionOverwrite> overwrite;
  String desc;

  CreateChannelResponse(this.code, {this.channel, this.overwrite, this.desc});
}

class CreateChannelController extends GetxController {
  static const int channelTypeChanged = 0;
  static const int enablePrivateChanged = 1;
  static const int isPrivateChannelChanged = 2;
  static const int liveEnabledChanged = 3;
  static const int selectedUserIdsChanged = 4;
  static const int selectedRoleIdsChanged = 5;
  static const int createLoadingChanged = 6;
  static const int videoCameraEnabledChanged = 7;

  static const int createButtonTag = 8;
  static const int createInfoChanged = 9;
  static const int linkInfoChanged = 10;
  static const int inputChanged = 11;

  static const String checkItemName = "name";
  static const String checkItemLink = "link";

  final String guildId;
  final String cateId;
  String cateName;

  bool _createLoading = false;

  bool get createLoading => _createLoading;

  set createLoading(bool value) {
    _createLoading = value;
    update([createLoadingChanged, createButtonTag]);
  }

  bool _isPrivateChannel = false;

  bool get isPrivateChannel => _isPrivateChannel;

  set isPrivateChannel(bool value) {
    _isPrivateChannel = value;
    update([isPrivateChannelChanged, createInfoChanged, createButtonTag]);
  }

  String _channelName = "";

  String get channelName => _channelName;

  set channelName(String v) {
    final String pre = _channelName;
    _channelName = v;
    if ((pre.isEmpty && v.isNotEmpty) || (pre.isNotEmpty && v.isEmpty)) {
      update([createButtonTag, createInfoChanged]);
    }
  }

  Set<String> selectedRoleIds = {};
  Set<String> selectedUserIds = {};

  void clearSelected() {
    selectedRoleIds.clear();
    selectedUserIds.clear();
  }

  void onTapRole(String roleId) {
    if (selectedRoleIds.contains(roleId)) {
      selectedRoleIds.remove(roleId);
    } else {
      selectedRoleIds.add(roleId);
    }
    update([selectedRoleIdsChanged, createButtonTag]);
  }

  void onTapUser(String userId) {
    if (selectedUserIds.contains(userId)) {
      selectedUserIds.remove(userId);
    } else {
      selectedUserIds.add(userId);
    }
    update([selectedUserIdsChanged, createButtonTag]);
  }

  ChatChannelType _channelType = ChatChannelType.guildText;

  ChatChannelType get channelType => _channelType;

  set channelType(ChatChannelType value) {
    switch (value) {
      case ChatChannelType.guildText:
      case ChatChannelType.guildVoice:
      case ChatChannelType.guildVideo:
        // _enablePrivate = true;
        _channelLink = '';
        break;
      case ChatChannelType.guildLink:
      case ChatChannelType.guildLive:
        // _isPrivateChannel = false;
        // _enablePrivate = false;
        clearSelected();
        break;
      default:
        break;
    }
    _channelType = value;
    update([
      channelTypeChanged,
      enablePrivateChanged,
      isPrivateChannelChanged,
      createInfoChanged,
      linkInfoChanged,
      createButtonTag
    ]);
  }

  bool _liveEnabled = false; // ???????????????????????????????????????
  bool get liveEnabled => _liveEnabled;

  set liveEnabled(bool value) {
    _liveEnabled = value;
    update([liveEnabledChanged]);
  }

  // bool _enablePrivate = true; //????????????????????????????????????????????????
  // bool get enablePrivate => _enablePrivate;
  // set enablePrivate(bool value) {
  //   _enablePrivate = value;
  //   update([enablePrivateChanged, createInfoChanged]);
  // }

  String _channelLink = ''; //?????????????????????
  // String get channelLink => _channelLink;

  LinkBean _channelLinkBean; //???????????????
  LinkBean get channelLinkBean => _channelLinkBean;

  set channelLinkBean(LinkBean linkBean) {
    _channelLinkBean = linkBean;
    _channelLink = linkBean.toLinkString();
    update([linkInfoChanged]);
  }

  bool get disableLive => !_liveEnabled || hasLiveChannel;

  bool get hasLiveChannel {
    final target = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    bool result = false;
    if (target.channels != null) {
      result = target.channels.any((e) => e.type == ChatChannelType.guildLive);
    } else {
      result = false;
    }
    return result;
  }

  bool _videoCameraEnabled = false; // ?????????????????????????????????
  bool get videoCameraEnabled => _videoCameraEnabled;

  set videoCameraEnabled(bool value) {
    _videoCameraEnabled = value;
    _liveEnabled = Config.permission['live'] ?? false;
    update([liveEnabledChanged, videoCameraEnabledChanged, createInfoChanged]);
  }

  CreateChannelController({this.guildId, this.cateId});

  @override
  void onInit() {
    // ??????????????????
    UserApi.getAllowRoster('channel').then((value) {
      videoCameraEnabled = value;
    });

    if (cateId.hasValue) {
      final target =
          ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
      cateName = target.channels
              .firstWhere((e) => e.id == cateId, orElse: () => null)
              ?.name ??
          '';
    }

    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
  }

  // ????????????
  String checkParam(List<String> checkItems) {
    for (final String c in checkItems) {
      if (c == checkItemName) {
        if (channelName.trim().isEmpty) {
          return "?????????????????????".tr;
        }
      }
      if (c == checkItemLink) {
        final linkBean = _channelLinkBean;
        final isCreateLink = _channelType == ChatChannelType.guildLink;
        if (isCreateLink) {
          if (linkBean == null) {
            return "URL??????????????????".tr;
          } else {
            if (linkBean is WxProgramBean && linkBean.appId.isEmpty) {
              return "???????????????ID????????????".tr;
            } else if (linkBean is UrlBean && linkBean.path.isEmpty) {
              return "URL??????????????????".tr;
            }
          }
        }
      }
    }
    return "";
  }

  Future<CreateChannelResponse> create() async {
    final _channelName = channelName.trim();

    // // ??????????????????
    // if (_channelName.isEmpty) {
    //   return CreateChannelResponse(CreateChannelResponse.CodeError,
    //       desc: "?????????????????????");
    // }

    // if (isPrivateChannel && selectedRoleIds.isEmpty) {
    //   return CreateChannelResponse(CreateChannelResponse.CodeError,desc: "????????????????????????????????????");
    // }

    // ///???????????????????????????????????????????????????????????????
    // final linkBean = _channelLinkBean;
    // final isCreateLink = _channelType == ChatChannelType.guildLink;
    // if (isCreateLink) {
    //   if (linkBean == null) {
    //     return CreateChannelResponse(CreateChannelResponse.CodeError,
    //         desc: "URL??????????????????");
    //   } else {
    //     if (linkBean is WxProgramBean && linkBean.appId.isEmpty) {
    //       return CreateChannelResponse(CreateChannelResponse.CodeError,
    //           desc: "???????????????ID????????????");
    //     } else if (linkBean is UrlBean && linkBean.path.isEmpty) {
    //       return CreateChannelResponse(CreateChannelResponse.CodeError,
    //           desc: "URL??????????????????");
    //     }
    //   }
    // }

    final errMsg = checkParam([checkItemName, checkItemLink]);
    if (errMsg.isNotEmpty) {
      return CreateChannelResponse(CreateChannelResponse.CodeError,
          desc: errMsg);
    }

    createLoading = true;

    try {
      List<Map<String, dynamic>> permissionOverwrites = [];
      if (isPrivateChannel) {
        permissionOverwrites = [
          {
            "id": guildId,
            "action_type": "role",
            "allows": 0,
            "deny": Permission.VIEW_CHANNEL.value,
          }
        ];

        if (selectedRoleIds.isNotEmpty) {
          final List<Map<String, dynamic>> rolePermissions = selectedRoleIds
              .map((e) => {
                    "id": e,
                    "action_type": "role",
                    "allows": Permission.VIEW_CHANNEL.value,
                    "deny": 0
                  })
              .toList();

          permissionOverwrites = [...permissionOverwrites, ...rolePermissions];
        }

        // ??????????????????????????????????????????????????????????????????
        if (!PermissionUtils.isGuildOwner(guildId: guildId)) {
          selectedUserIds.add(Global.user.id);
        }

        if (selectedUserIds.isNotEmpty) {
          final List<Map<String, dynamic>> userPermissions = selectedUserIds
              .map((e) => {
                    "id": e,
                    "action_type": "user",
                    "allows": Permission.VIEW_CHANNEL.value,
                    "deny": 0
                  })
              .toList();
          permissionOverwrites = [...permissionOverwrites, ...userPermissions];
        }
        // ?????????
        if (!PermissionUtils.isGuildOwner(guildId: guildId)) {
          selectedUserIds.remove(Global.user.id);
        }
      }

      ///fix:???????????????????????????2???
      // final isValid = await CheckUtil.startCheck(
      //     TextCheckItem(_channelName, TextChannelType.CHANNEL_NAME),
      //     toastError: false);
      // if (!isValid) {
      //   createLoading = false;
      //   return CreateChannelResponse(CreateChannelResponse.CodeError,
      //       desc: defaultErrorMessage);
      // }
      final res = await ChannelApi.createChannel(
          guildId, Global.user.id, _channelName, channelType, cateId,
          permissionOverwrites: permissionOverwrites,
          link: _channelLink,
          showDefaultErrorToast: false);

      final _channelId = res['channel_id'];
      if (res != null && isNotNullAndEmpty(_channelId.toString())) {
        final _chatChannel = ChatChannel(
            id: _channelId,
            guildId: guildId,
            name: _channelName,
            type: channelType,
            parentId: cateId,
            link: _channelLink);

        // ?????????overwrite????????????????????????add??????
        final overwrites = (res["permission_overwrites"] as List).map((e) {
          return PermissionOverwrite.fromJson(e);
        }).toList();

        /// ?????? 500ms ?????????????????? push {type: string} ???????????????????????????????????????
        await Future.delayed(const Duration(milliseconds: 500));

        createLoading = false;

        clearSelected();
        return CreateChannelResponse(CreateChannelResponse.CodeSuccess,
            channel: _chatChannel, overwrite: overwrites, desc: '????????????'.tr);
      } else {
        return CreateChannelResponse(CreateChannelResponse.CodeError,
            desc: "????????????".tr);
      }
    } catch (e) {
      final isNetworkError = Http.isNetworkError(e);
      createLoading = false;
      return CreateChannelResponse(CreateChannelResponse.CodeError,
          desc: isNetworkError ? networkErrorText : e?.message ?? "");
    }
  }

  String endOfLiveString() {
    if (!_liveEnabled) return '??????????????????'.tr;
    if (hasLiveChannel) return '???????????????'.tr;
    return '';
  }
}
