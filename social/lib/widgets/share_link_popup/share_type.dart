import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluwx/fluwx.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/friend_list_page/controllers/friend_list_page_controller.dart';
import 'package:im/app/modules/share_circle/controllers/share_circle_controller.dart';
import 'package:im/app/modules/share_circle/views/share_circle_poster_page.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/global.dart';
import 'package:im/global_methods/goto_direct_message.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/svg_icons.dart';
import 'package:im/widgets/share_link_popup/share_friends_popup.dart';
import 'package:im/widgets/share_link_popup/share_link_popup.dart';
import 'package:im/widgets/share_link_popup/share_link_report_manager.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../routes.dart';

/// 分享模型
class ShareConfig {
  /// 分享品台logo
  final Widget icon;

  /// 分享品台名称
  final String name;

  ShareConfig(
    this.name,
    this.icon,
  );
}

/// 分享行为，可与任意分享配置组合，例如微信分享配置可组合分享图片或分享网页的行为
abstract class ShareAction {
  /// 执行分享操作时是否展示loading弹窗
  final bool showLoading;

  /// 分享完成后是否关闭弹窗
  bool isPopAfterShare;

  ShareAction({
    this.showLoading = true,
    this.isPopAfterShare = true,
  });

  Future<bool> shareAction();

  Future<bool> share(BuildContext context) async {
    if (showLoading) {
      Loading.show(context);
    }
    bool res;
    try {
      res = await shareAction();
    } catch (e, s) {
      logger.severe("share function", e, s);
      res = false;
    }
    if (showLoading) {
      Loading.hide();
    }
    if (isPopAfterShare) {
      Get.back();
    }
    return res;
  }
}

/// 微信好友分享配置
class WechatShareToFriendConfig extends ShareConfig {
  WechatShareToFriendConfig()
      : super("微信".tr, WebsafeSvg.asset(SvgIcons.svgWechat));
}

/// 微信朋友圈分享配置
class WechatShareToMomentConfig extends ShareConfig {
  WechatShareToMomentConfig()
      : super("朋友圈".tr, WebsafeSvg.asset(SvgIcons.svgWechatTimeline));
}

/// Fanbook好友分享配置
class FanbookShareToFriendConfig extends ShareConfig {
  FanbookShareToFriendConfig()
      : super(
          "你的好友".tr,
          Icon(
            IconFont.buffTabLogo,
            color: Theme.of(Global.navigatorKey.currentContext).primaryColor,
          ),
        );
}

/// 保存图片
class SaveImageConfig extends ShareConfig {
  SaveImageConfig()
      : super(
          "保存到本地".tr,
          const Icon(IconFont.buffSave),
        );
}

/// 保存图片
class CopyLinkConfig extends ShareConfig {
  CopyLinkConfig()
      : super(
          "复制邀请码".tr,
          const Icon(IconFont.buffChatCopy),
        );
}

/// 复制链接
class CopyLinkShareConfig extends ShareConfig {
  CopyLinkShareConfig()
      : super(
          "复制链接".tr,
          const Icon(IconFont.buffLink),
        );
}

/// 生成分享图
class SaveShareConfig extends ShareConfig {
  SaveShareConfig()
      : super(
          "生成分享图".tr,
          const Icon(IconFont.buffCircleImageThumb),
        );
}

class SaveShareAction extends ShareAction {
  final String link;
  final ShareBean shareBean;

  SaveShareAction(this.link, this.shareBean)
      : super(showLoading: false, isPopAfterShare: false);
  @override
  Future<bool> shareAction() async {
    await Get.dialog(
        ShareCirclePosterPage(shareLink: link, shareBean: shareBean),
        name: shareCirclePosterRoute,
        useSafeArea: false);
    return true;
  }
}

class CopyLinkShareAction extends ShareAction {
  final String link;
  CopyLinkShareAction(this.link) : super(showLoading: false);
  @override
  Future<bool> shareAction() async {
    final ClipboardData data = ClipboardData(text: link ?? '');
    await Clipboard.setData(data);
    showToast('链接已复制'.tr);
    return true;
  }
}

/// 微信分享网页
class WechatShareLinkAction extends ShareAction {
  final String title;
  final String subtitle;
  final String link;
  final String icon;
  final WeChatScene scene;

  final ShareLinkType shareLinkType;

  WechatShareLinkAction({
    this.title,
    this.subtitle,
    this.link,
    this.icon,
    this.scene = WeChatScene.SESSION,
    this.shareLinkType = ShareLinkType.other,
  });

  @override
  Future<bool> shareAction() async {
    if (!link.hasValue) return false;
    if (!(await isWeChatInstalled)) {
      showToast('未安装微信'.tr);
      return false;
    }
    final model = WeChatShareWebPageModel(
      link,
      title: title,
      description: subtitle,
      thumbnail: WeChatImage.network(icon),
      scene: scene,
    );
    await shareToWeChat(model);
    final optContent =
        scene == WeChatScene.SESSION ? 'wechat' : 'wechat_moments';
    ShareLinkReportManager.liveBehavior(link, optContent, shareLinkType);
    return true;
  }
}

/// 微信分享图片
class WechatShareImageAction extends ShareAction {
  final File file;
  final WeChatScene scene;

  WechatShareImageAction({
    @required this.file,
    this.scene = WeChatScene.SESSION,
  });

  @override
  Future<bool> shareAction() async {
    final image = WeChatImage.file(file);
    WeChatShareImageModel(image, scene: scene);
    return true;
  }
}

/// Fanbook分享链接
class FanbookShareLinkAction extends ShareAction {
  final String link;
  final ShareLinkType shareLinkType;

  FanbookShareLinkAction(this.link, {this.shareLinkType = ShareLinkType.other})
      : super(showLoading: false);

  @override
  Future<bool> shareAction() async {
    final context = Global.navigatorKey.currentContext;
    if (!link.hasValue) return false;
    if (FriendListPageController.to.list.isEmpty) {
      showToast('😑暂无好友，请选择其他方式分享'.tr);
    } else {
      await showShareFriendsPopUp(context, onConfirm: (users) async {
        for (final user in users) {
          unawaited(_sendMessage(user.user.userId));
        }
        showToast('😄 邀请链接已发送'.tr);
        Get.back();
      });
      ShareLinkReportManager.liveBehavior(
        link,
        'fanbook_friend',
        shareLinkType,
      );
    }
    return true;
  }

  Future<void> _sendMessage(String userId) async {
    unawaited(sendDirectMessage(userId, TextEntity.fromString(link ?? '')));
  }
}

/// 分享按钮，展示分享品台logo和品台名称
class ShareItem extends StatelessWidget {
  /// 分享按钮的基本配置，包含平台logo和名称等信息
  final ShareConfig config;

  /// 分享执行的操作
  final ShareAction action;

  /// 分享平台logo展示的尺寸，如果为null则以radius为半径绘制圆形logo
  final double size;

  /// 分享平台logo的圆角半径，如果size为null则以此为半径绘制圆形logo
  final double radius;

  /// logo和平台名之间的间距
  final double gap;

  /// logo背景颜色
  final Color iconBgColor;

  /// 平台名称文本样式
  final TextStyle textStyle;
  final EdgeInsets padding;
  final Function() onShareClick;

  const ShareItem({
    Key key,
    @required this.config,
    @required this.action,
    this.size,
    this.radius = 24,
    this.textStyle,
    this.gap = 6,
    this.padding,
    this.iconBgColor,
    this.onShareClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(size != null || radius != null);

    final _theme = Theme.of(context);

    /// logo尺寸
    final _size = size ?? radius * 2;
    return GestureDetector(
      onTap: () async {
        final result = await action.share(context);
        if (result) {
          onShareClick?.call();
        }
      },
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: iconBgColor ?? _theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.all(Radius.circular(radius)),
              ),
              child: config.icon,
            ),
            SizedBox(height: gap),
            Text(config.name, style: textStyle),
          ],
        ),
      ),
    );
  }
}
