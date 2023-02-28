import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/global_methods/goto_direct_message.dart';
import 'package:im/pages/external_share/external_share_model.dart';
import 'package:im/pages/external_share/external_share_page.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/routes.dart';
import 'package:im/utils/deep_link/oauth_processor.dart';
import 'package:im/widgets/fb_ui_kit/dialog/acton_complete_dialog.dart';
import 'package:pedantic/pedantic.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../global.dart';
import '../../svg_icons.dart';
import '../deeplink_processor.dart';

class ExternalShareDeepLinkTask extends DeepLinkTask {
  String _clientId;
  String _guildId;
  String _inviteCode;
  String _state;
  String _packageName;

  ExternalShareDeepLinkTask(Uri deepLink) : super(deepLink) {
    _inviteCode = deepLink.queryParameters["inviteCode"];
    _clientId = deepLink.queryParameters["clientId"];
    _guildId = deepLink.queryParameters["guildId"];
    _state = deepLink.queryParameters["state"];
    _packageName = deepLink.queryParameters["packageName"];
  }

  @override
  bool isNeedToWaite() {
    return !isLogin;
  }

  @override
  Future run() async {
    final shareContentType = deepLink.queryParameters["shareContentType"];
    if (shareContentType != "link" && shareContentType != "image") {
      /// 不支持的分享类型
      _backToThirdPart(DeepLinkTaskErrCode.SHARE_UNSUPPORTED_TYPE);
      return;
    }

    if (_guildId.hasValue && !_isJoinedGuild()) {
      /// 如果未加入服务器，先跳转到邀请加入服务器页面
      final inviteResult = await _gotoInvitePage();

      /// 是否已加入服务器
      final hasJoined =
          inviteResult.errCode == DeepLinkTaskErrCode.INVITE_HAS_JOINED;
      if (!inviteResult.isSuccess && !hasJoined) {
        /// 邀请失败
        _backToThirdPart(inviteResult.errCode);
        return;
      }
    }

    final shareResult = await _gotoExternalSharePage();
    if (shareResult.errCode == DeepLinkTaskErrCode.SHARE_BACK) {
      /// fanbook退到后台，返回到任务开始时的页面
      back();
      return;
    }

    if (shareResult.isSuccess) {
      /// 回到任务开始的页面
      back(
          isSuccess: true,
          finishCallback: (code) async {
            // 分享成功，跳转UI
            if (shareResult.result.shareToType == "user") {
              unawaited(gotoDirectMessageChat(shareResult.result.toUserId));
              // 需要等待跳转到消息页面后继续往下走
              await Future.delayed(const Duration(milliseconds: 500));
            } else if (shareResult.result.shareToType == "channel") {
              await ChatTargetsModel.instance.selectChatTargetById(
                  shareResult.result.toGuildId,
                  channelId: shareResult.result.toChannelId,
                  gotoChatView: true);
            }

            await showConfirmDialog(shareResult.result.appName,
                onBackThirdParty: () {
              /// 回到三方应用
              /// 因为之前已经完成了返回到相应的位置，因此不需要再动UI了
              _backToThirdPart(shareResult.errCode, shouldBack: false);
            });
          });

      return;
    }

    /// 分享失败，回到三方app
    _backToThirdPart(shareResult.errCode);
  }

  Future showConfirmDialog(String appName,
      {VoidCallback onBackThirdParty, VoidCallback onStay}) {
    return showDialog(
      context: Global.navigatorKey.currentContext,
      builder: (ctx) {
        return ActionCompleteDialog(
          type: 1,
          icon: WebsafeSvg.asset(
            SvgIcons.externalShareSuccess,
            width: 84,
            height: 84,
          ),
          text: "分享成功".tr,
          buttons: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (onBackThirdParty != null) onBackThirdParty();
              },
              child: Text(
                "返回$appName",
                style: const TextStyle(
                    fontSize: 17,
                    height: 21.0 / 17.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6179F2)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (onStay != null) onStay();
              },
              child: Text(
                "留在Fanbook".tr,
                style: const TextStyle(
                  fontSize: 17,
                  height: 21.0 / 17.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF363940),
                ),
              ),
            ),
          ],
        );
      },
      barrierDismissible: false,
    );
  }

  /// 跳转到邀请页面并返回邀请结果
  Future<DeepLinkCommandResult> _gotoInvitePage() {
    final command = InviteDeepLinkCommand(
      _inviteCode,
      paramValidator: invalidGuildIdValidator(_guildId),
    );
    return command.execute();
  }

  /// 跳转到分享页面并返回分享结果
  Future<DeepLinkCommandResult<ExternalShareResult>> _gotoExternalSharePage() {
    final command = ExternalShareCommand(
      _clientId,
      _guildId,
      deepLink.queryParameters["shareContentType"],
      _inviteCode,
      deepLink.queryParameters["desc"],
      deepLink.queryParameters["image"],
      deepLink.queryParameters["link"],
      _state,
      _packageName,
    );
    return command.execute();
  }

  /// 返回到唤起Fanbook的三方应用
  void _backToThirdPart(int code, {bool shouldBack = true}) {
    /// 生成到三方应用的deep link
    final Map<String, String> parameters = {};
    parameters["errCode"] = code.toString();
    if (_state != null) {
      parameters["state"] = _state;
    }

    final scheme =
        "fanbook${_packageName?.replaceAll(".", "") ?? ""}$_clientId";

    final url = Uri(
      scheme: scheme,
      host: "share",
      queryParameters: parameters,
    );

    /// 回到三方应用
    backToThirdPart(url.toString(), shouldBack: shouldBack);
    print("ExternalShareTask back to third part, error code: $code");
  }

  /// 当前用户是否在分享所在的服务器中
  bool _isJoinedGuild() {
    return ChatTargetsModel.instance.isJoinGuild(_guildId);
  }
}

class ExternalShareCommand extends DeepLinkCommand<ExternalShareResult> {
  final String clientId;
  final String _guildId;
  final String shareContentType;
  final String inviteCode;
  final String desc;
  final String image;
  final String link;
  final String state;
  final String packageName;

  ExternalShareModel _shareModel;

  ExternalShareCommand(
    this.clientId,
    this._guildId,
    this.shareContentType,
    this.inviteCode,
    this.desc,
    this.image,
    this.link,
    this.state,
    this.packageName,
  ) {
    _shareModel = ExternalShareModel(
      clientId,
      _guildId,
      shareContentType,
      inviteCode,
      desc,
      image,
      link,
      state,
      packageName,
      taskNotifier: notifier,
    );
  }

  @override
  Future<DeepLinkCommandResult<ExternalShareResult>> gotoPageForResult() {
    Routes.push(Global.navigatorKey.currentContext,
        ExternalSharePage(_shareModel), commandName,
        replace: replace);
    return notifier.result;
  }
}

class ExternalShareDeepLinkMatcher extends DeepLinkMatcher {
  ExternalShareDeepLinkMatcher() : super("fanbook://share");

  @override
  DeepLinkTask createTask(Uri deepLink, {bool isColdStart = true}) {
    return ExternalShareDeepLinkTask(deepLink);
  }
}
