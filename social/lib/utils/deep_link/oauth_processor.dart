import 'package:get/get.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/api/invite_api.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/oauth/fanbook_oauth_page.dart';
import 'package:im/routes.dart';
import 'package:im/utils/deeplink_processor.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/app/modules/accept_invite/controllers/accept_invite_param.dart';

/// 用来匹配OAuth验证的deep link
class OAuthDeepLinkMatcher extends DeepLinkMatcher {
  OAuthDeepLinkMatcher() : super("fanbook://oauth");

  @override
  DeepLinkTask createTask(Uri deepLink) {
    return OAuthDeepLinkTask(deepLink);
  }
}

class OAuthDeepLinkTask extends DeepLinkTask {
  OAuthDeepLinkTask(Uri deepLink) : super(deepLink);

  @override
  Future run() async {
    /// 邀请码
    final String inviteCode = deepLink.queryParameters["inviteCode"];
    if (inviteCode.noValue) {
      /// 没有传入邀请码，直接执行跳转到OAuth验证页面
      await _gotoOAuth();
      return;
    }

    final String guildId = deepLink.queryParameters["guildId"];
    if (ChatTargetsModel.instance.isJoinGuild(guildId)) {
      /// 已加入服务器或邀请成功，进入OAuth验证页
      await _gotoOAuth();
      return;
    }

    /// 跳转到邀请页面，获取邀请结果
    final cmd = InviteDeepLinkCommand(
      inviteCode,
      paramValidator: invalidGuildIdValidator(guildId),
    );
    final inviteResult = await cmd.execute();

    /// 是否已加入服务器
    final hasJoined =
        inviteResult.errCode == DeepLinkTaskErrCode.INVITE_HAS_JOINED;
    if (hasJoined || inviteResult.isSuccess) {
      /// 已加入服务器或邀请成功，进入OAuth验证页
      await _gotoOAuth();
      return;
    }

    /// 邀请失败
    _backToThirdPart(inviteResult.errCode);
  }

  /// 执行授权操作
  Future _gotoOAuth() async {
    final clientId = deepLink.queryParameters["clientId"];
    final state = deepLink.queryParameters["state"];
    final cmd = OAuthDeepLinkCommand(clientId, state);
    final r = await cmd.execute();

    /// 回退到三方app
    _backToThirdPart(r.errCode, code: r.result);
  }

  @override
  bool isNeedToWaite() {
    /// 如果未登录则进入等待状态
    return !isLogin;
  }

  /// 返回到唤起Fanbook的三方应用
  void _backToThirdPart(int errCode, {String code}) {
    final packageName = deepLink.queryParameters["packageName"];
    final clientId = deepLink.queryParameters["clientId"];
    final state = deepLink.queryParameters["state"];

    /// 生成返回授权结构的deep link
    final Map<String, String> parameters = {};
    if (errCode != null) {
      parameters["errCode"] = errCode.toString();
    }
    if (code != null) {
      parameters["code"] = code;
    }
    if (state != null) {
      parameters["state"] = state;
    }

    final scheme = "fanbook${packageName?.replaceAll(".", "") ?? ""}$clientId";
    final url = Uri(
      scheme: scheme,
      host: "oauth",
      queryParameters: parameters,
    );

    /// 回到三方app
    backToThirdPart(url.toString());
    print("OAuthDeepLinkTask back to third part, error code: $errCode");
  }
}

/// 处理OAuth验证的deep link
class OAuthDeepLinkCommand extends DeepLinkCommand<String> {
  final String clientId;
  final String state;

  OAuthDeepLinkCommand(this.clientId, this.state) : super();

  // @override
  // Widget build() {
  //   /// OAuth验证页面
  //   return FanbookOAuthPage(
  //     clientId: clientId,
  //     state: state,
  //     notifier: notifier,
  //   );
  // }

  @override
  Future<DeepLinkCommandResult<String>> gotoPageForResult() {
    Routes.push(
        Global.navigatorKey.currentContext,
        FanbookOAuthPage(
          clientId: clientId,
          state: state,
          notifier: notifier,
        ),
        commandName,
        replace: replace);
    return notifier.result;
  }
}

/// 跳转到邀请页面时，验证邀请参数是否有效，返回错误码，参数有效时返回[DeepLinkTaskResult.SUCCESS]
typedef InviteParamValidator = int Function(
  String inviteCode,
  String guildId,
  String inviterId,
  String channelId,
);

InviteParamValidator invalidGuildIdValidator(String guildId) {
  return (
    inviteCode,
    _guildId,
    inviterId,
    channelId,
  ) {
    /// 判断要分享的服务器与被邀请的服务器是否一致
    if (guildId != _guildId) {
      return DeepLinkTaskErrCode.SHARE_WRONG_GUILD_ID;
    }
    return DeepLinkTaskErrCode.SUCCESS;
  };
}

/// 处理跳转到邀请页面的操作
class InviteDeepLinkCommand extends DeepLinkCommand {
  /// 邀请码
  final String inviteCode;
  final InviteParamValidator paramValidator;

  /// 邀请的服务器id
  String _guildId;

  /// 邀请者id
  String _inviterId;

  /// 邀请的频道id
  String _channelId;

  /// 验证邀请参数是否有效
  InviteDeepLinkCommand(this.inviteCode, {this.paramValidator}) : super();

  @override
  Future<DeepLinkCommandResult> gotoPageForResult() {
    final param = AcceptInviteParam(
      inviterId: _inviterId,
      guildId: _guildId,
      inviteCode: inviteCode,
      channelId: _channelId,
      notifier: notifier,
    );

    if (replace) {
      Get.offNamed(app_pages.Routes.ACCEPT_INVITE, arguments: param);
    } else {
      Get.toNamed(app_pages.Routes.ACCEPT_INVITE, arguments: param);
    }

    return notifier.result;
  }

  @override
  Future<DeepLinkCommandResult> execute() async {
    if (!inviteCode.hasValue) {
      return DeepLinkCommandResult(DeepLinkTaskErrCode.INVALID_INVITE_CODE);
    }

    try {
      /// 解析邀请码
      final Map inviteInfo = await InviteApi.getCodeInfo(
        inviteCode,
        showDefaultErrorToast: true,
      );

      if (inviteInfo == null || inviteInfo.isEmpty) {
        /// 无效的邀请码
        return DeepLinkCommandResult(DeepLinkTaskErrCode.INVALID_INVITE_CODE);
      }

      _guildId = inviteInfo['guild_id'];
      _inviterId = inviteInfo['inviter_id'];
      _channelId = inviteInfo['channel_id'];

      if (paramValidator != null) {
        /// 验证邀请参数是否有效
        final errCode =
            paramValidator(inviteCode, _guildId, _inviterId, _channelId);
        if (errCode != DeepLinkTaskErrCode.SUCCESS) {
          /// 邀请参数有问题
          return DeepLinkCommandResult(errCode);
        }
      }

      /// 判断邀请码是否过期
      bool isExpire;
      if (inviteInfo['number'] == '-1') {
        isExpire = inviteInfo['expire_time'] == '0';
      } else {
        isExpire = inviteInfo['expire_time'] == '0' ||
            inviteInfo['number'] == '0' ||
            inviteInfo['is_used'] == '1';
      }
      if (isExpire) {
        /// 邀请码过期
        return DeepLinkCommandResult(DeepLinkTaskErrCode.INVITE_CODE_EXPIRED);
      }

      /// 判断是否已加入服务器
      final guildInfo = await GuildApi.getGuildInfo(
        guildId: inviteInfo['guild_id'],
        userId: Global.user.id,
        showDefaultErrorToast: true,
      );
      final bool joined = guildInfo['join'];
      if (joined) {
        /// 已加入过服务器
        return DeepLinkCommandResult(DeepLinkTaskErrCode.INVITE_HAS_JOINED);
      }

      /// 跳转到邀请并返回邀请结果
      return super.execute();
    } catch (e, s) {
      /// 未知错误
      print("InviteDeepLinkCommand error: $e\n$s");
      return DeepLinkCommandResult(DeepLinkTaskErrCode.NORMAL);
    }
  }
}
