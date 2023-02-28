import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/oauth_api.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/modules/friend_list_page/controllers/friend_list_page_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/global_methods/goto_direct_message.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/deeplink_processor.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:pedantic/pedantic.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../global.dart';

class ExternalShareModel extends ChangeNotifier with WidgetsBindingObserver {
  static const platform = MethodChannel('buff.com/fbUtils');

  final String clientId;
  final String toGuildId;
  final String shareContentType;
  final String inviteCode;
  final String desc;
  final String image;
  final String link;
  final String state;
  final String packageName;
  final DeepLinkTaskNotifier taskNotifier;

  String get inviterId => _inviterId;
  String _inviterId;

  String get imageUrl => _imageUrl;
  String _imageUrl;

  String _imageLocalPath;

  Uint8List get imageBytes => _imageBytes;
  Uint8List _imageBytes;

  bool isSelectUser = false;
  UserInfo _selectedUser;

  UserInfo get selectedUser => _selectedUser;

  List<UserInfo> _recentUsers;

  ChatChannel get selectedChannel => _selectedChannel;
  ChatChannel _selectedChannel;

  String get appName => _appName;
  String _appName;

  String get appAvatar => _appAvatar;
  String _appAvatar;

  // 1 邀请进服务器，点击返回，用户未进入服务器
  // 2 邀请进服务器，点击不了，用户未进入服务器
  // 3 用户点击关闭
  // 4 图片内容为空或获取失败
  // 5 获取邀请信息失败
  // 6 获取邀请信息失败
  // 7 邀请码不是当前要分享服务器的邀请码
  // 8 退到后台
  Map<int, String> codeDesc = {
    0: "成功".tr,
    1: "未加入服务器，已取消分享",
    2: "未加入服务器，已取消分享",
    3: "已取消分享",
    4: "图片获取失败",
    5: "请先加入服务器再进行分享",
    6: "邀请信息获取失败",
    7: "邀请信息和服务器不匹配，请检查配置",
    8: "取消分享",
    9: "分享内容不支持，请更新至最新版本"
  };

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      taskNotifier?.onError(DeepLinkTaskErrCode.SHARE_BACK);
    }
    super.didChangeAppLifecycleState(state);
  }

  ExternalShareModel(
    this.clientId,
    this.toGuildId,
    this.shareContentType,
    this.inviteCode,
    this.desc,
    this.image,
    this.link,
    this.state,
    this.packageName, {
    this.taskNotifier,
  }) {
    WidgetsBinding.instance.addObserver(this);

    if (image.hasValue && image.startsWith("http")) {
      _imageUrl = image;
    }
    _dealImage();
  }

  Future selectUser(String userId) async {
    isSelectUser = true;
    _selectedUser = await UserInfo.get(userId);
  }

  void selectChannel(ChatChannel channel) {
    isSelectUser = false;
    _selectedChannel = channel;
  }

  List<String> friendListIds() {
    final list =
        FriendListPageController.to.list.map((e) => e.user.userId).toList();
    return list;
  }

  List<UserInfo> friendList() {
    return FriendListPageController.to.list.map((e) => e.user).toList();
  }

  List<String> recentUserListIds() {
    return DirectMessageController.to.channelsDm
        .map((e) => e.recipientId)
        .toList();
  }

  Future init() async {
    try {
      final _appInfo = await OAuthAPI.getAppInfo(clientId);
      _appName = _appInfo?.appName;
      _appAvatar = _appInfo?.avatarUrl;
    } catch (e) {
      _appName = "";
      _appAvatar = "";
    }

    unawaited(loadRemoteData());

    // await _prepareRecent();
  }

  Future loadRemoteData() async {
    final DirectMessageController c = Get.find<DirectMessageController>();
    if (c.channels.isEmpty) {
      await c.loadLocalData();
      final localChannelIds = Db.channelBox.values.map((e) => e.id).toSet();
      await c.useRemoteDirectMessageData(localChannelIds);
    }

    final FriendListPageController friendsController =
        Get.find<FriendListPageController>();
    if (friendsController.list.isEmpty) {
      await friendsController.initFriendList();
    }
    notifyListeners();
  }

  // Future _prepareRecent() async {
  //   _recentUserIds.clear();
  //   final c = DirectMessageController.to.channels;
  //   for (int i = 0; i < c.length; i++) {
  //     final e = c.elementAt(i);
  //     _recentUserIds.add(e.guildId);
  //   }
  //   return _recentUserIds;
  // }

  // Future _prepareRecent() async {
  //   _recentUsers.clear();
  //   // final c = DirectMessageController.to.channels;
  //   // 从数据库中读取最近的联系人信息
  //   //启动时不再读取全部的本地未读消息
  //   final List<ChatChannel> dmList = [];
  //   final cacheDmIds =
  //       Db.dmListBox.values.toList().reversed.map((e) => e['channelId']);
  //   for (final channelId in cacheDmIds) {
  //     final channel = Db.channelBox.get(channelId);
  //     if (channel == null) continue;
  //     dmList.add(channel);
  //   }
  //
  //   for (int i = 0; i < dmList.length; i++) {
  //     final e = dmList.elementAt(i);
  //     final UserInfo u = await UserInfo.get(e.guildId);
  //     if (u != null) {
  //       _recentUsers.add(u);
  //     }
  //   }
  //   return _recentUsers;
  // }

  // Future<List<UserInfo>> recentList() async {
  //      final recentIds = recentUserListIds();
  //      for (int i = 0; i < recentIds.length; i++) {
  //        final e = recentIds.elementAt(i);
  //        final UserInfo u = await UserInfo.get(e);
  //        if (u != null) {
  //          _recentUsers.add(u);
  //        }
  //      }
  //    return _recentUsers;
  //  }

  Future loadCompleteInfo() async {
    // 首次获取，则拉取
    if (_recentUsers != null) return;
    _recentUsers = [];
    final channelsDm = DirectMessageController.to.channelsDm;
    for (final ChatChannel c in channelsDm) {
      final u = await UserInfo.get(c.guildId);
      _recentUsers.add(u);
    }
  }

  Future<List<String>> searchMembers(String key,
      {String source = "all"}) async {
    final Set<UserInfo> userList = {};

    final friends =
        FriendListPageController.to.list.map((e) => e.user).toList();
    if (source == "recents" || source == "all") {
      unawaited(loadCompleteInfo());
      final recentUsers = UnmodifiableListView(_recentUsers);
      userList.addAll(recentUsers.where((element) =>
          (element.nickname != null && element.nickname.contains(key)) ||
          (element.gnick != null && element.gnick.contains(key)) ||
          (element.username != null && element.username.contains(key))));
    }

    if (source == "friends" || source == "all") {
      userList.addAll(friends.where((element) =>
          (element.nickname != null && element.nickname.contains(key)) ||
          (element.gnick != null && element.gnick.contains(key)) ||
          (element.username != null && element.username.contains(key))));
    }
    return userList.map((e) => e.userId).toList();
  }

  List<GuildTarget> guildList() {
    final list = <GuildTarget>[];
    ChatTargetsModel.instance.chatTargets.forEach((element) {
      if (element.runtimeType == GuildTarget) {
        list.add(element);
      }
    });
    return list;
  }

  ExternalShareEntity shareEntity() {
    return ExternalShareEntity(
      shareContentType: shareContentType,
      desc: desc,
      imageUrl: _imageUrl,
      imageLocalPath: _imageLocalPath,
      imageBytes: _imageBytes,
      link: link,
      state: state,
      clientId: clientId,
      guildId: toGuildId,
      packageName: packageName,
      inviteCode: inviteCode,
      appName: _appName,
      appAvatar: _appAvatar,
    );
  }

  // 如果来的是图片数据，则需要处理成url
  Future _dealImage() async {
    // 如果是url形式的image，imageUrl已经获得
    if (imageUrl != null || image.isEmpty) return;
    try {
      if (UniversalPlatform.isIOS) {
        // iOS上传过来的是base64之后的数据
        _imageBytes = base64Url.decode(image);
      } else if (UniversalPlatform.isAndroid) {
        // Android上传过来的是本地图片路径
        if (image.startsWith("content")) {
          await checkSystemPermissions(
            context: Global.navigatorKey.currentContext,
            permissions: [
              if (UniversalPlatform.isAndroid) Permission.storage,
            ],
          );
          final Map<String, dynamic> args = <String, dynamic>{};
          args.putIfAbsent('uri', () => image);
          _imageBytes = await platform.invokeMethod('getUriData', args);
        } else {
          final File file = File(image);
          _imageBytes = file.readAsBytesSync();
        }
      }

      // 保存本地
      final String tempFileKey = "tempFile-${_imageBytes.hashCode}";
      final file =
          await CustomCacheManager.instance.putFile(tempFileKey, _imageBytes);
      _imageLocalPath = file.path;
    } catch (e) {
      //忽略上传和获取图片的失败
    }
    notifyListeners();
  }

  Future share() async {
    if (isSelectUser) {
      unawaited(sendDirectMessage(_selectedUser.userId, shareEntity()));
      // 跳转到私聊页面
      taskNotifier?.onSuccess(
          result: ExternalShareResult(
              appName: _appName,
              shareToType: "user",
              toUserId: _selectedUser.userId));
    } else {
      unawaited(TextChannelController.to(channelId: _selectedChannel.id)
          .sendContent(shareEntity()));

      taskNotifier?.onSuccess(
          result: ExternalShareResult(
              appName: _appName,
              shareToType: "channel",
              toGuildId: _selectedChannel.guildId,
              toChannelId: _selectedChannel.id));
      // await ChatTargetsModel.instance.selectChatTargetById(_selectedChannel.guildId,channelId: _selectedChannel.id,gotoChatView: true);
    }
    // await showConfirmDialog("分享成功".tr);
  }

  /// 点击返回结束页面时调用
  void back() {
    taskNotifier?.onError(DeepLinkTaskErrCode.SHARE_CANCEL);
  }

  /// 分享成功后弹出弹窗，让用户选择是否返回三方应用
// Future showConfirmDialog(String text) {
//   return showDialog(
//     context: Global.navigatorKey.currentContext,
//     builder: (ctx) {
//       return ActionCompleteDialog(
//         icon: const Icon(IconFont.buffToastSuccess,
//             color: Color(0xFF6179F2), size: 60),
//         text: text,
//         buttons: [
//           TextButton(
//             onPressed: () async {
//               /// 返回到三方app
//               taskNotifier?.onSuccess(result: ExternalShareResult());
//               Navigator.pop(ctx);
//             },
//             child: Text(
//               "返回$_appName",
//               style: const TextStyle(
//                   fontSize: 17,
//                   height: 21.0 / 17.0,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF6179F2)),
//             ),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               // 回到任务开始执行的页面
//               taskNotifier?.onSuccess(
//                 result: ExternalShareResult(isBackToThirdPart: false),
//               );
//             },
//             child: const Text(
//               "留在Fanbook".tr,
//               style: TextStyle(
//                 fontSize: 17,
//                 height: 21.0 / 17.0,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF6179F2),
//               ),
//             ),
//           ),
//         ],
//       );
//     },
//     barrierDismissible: false,
//   );
// }
}

/// 分享结果
class ExternalShareResult {
  /// 是否返回到三方应用
  final String appName;
  final String shareToType;
  final String toUserId;
  final String toGuildId;
  final String toChannelId;

  ExternalShareResult(
      {this.appName,
      this.shareToType,
      this.toUserId,
      this.toGuildId,
      this.toChannelId});
}
