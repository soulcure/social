import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluwx/fluwx.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/invite_code.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/quest/fb_quest_config.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/pages/setting/share_link_setting_page.dart';
import 'package:im/widgets/circle_icon.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/share_link_popup/controller/share_link_controller.dart';
import 'package:im/widgets/share_link_popup/setting/share_link_setting_popup.dart';
import 'package:im/widgets/share_link_popup/share_type.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:quest_system/quest_system.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

import 'const.dart';
import 'share_link_navigator.dart';

typedef OnShareTypeTap = void Function(
  GuildTarget guild,
  String title,
  String subtitle,
  String lnk,
  String icon,
);

/// 分享链接类型
/// 直播需要日志埋点， 所以添加此枚举值做判断，后续其它需要处理的再继续添加类型
enum ShareLinkType {
  // 直播(正在直播)
  live,

  // 直播(回放)
  livePlayback,

  /// 默认类型
  other,
}

/// @param link: 分享出去的链接，如果为空则会分享服务器或频道链接
/// @param title: 分享组件展示的标题
/// @param description: 分享组件标题下的描述
/// @param shareTitle: 分享到三方品台的标题
/// @param shareDesc: 分享到三方品台的描述
/// @param shareCover: 分享到三方品台的图片封面链接
/// @param isGenQrCode: 是否生成分享海报
void showShareLinkPopUp(
  BuildContext context, {
  ChatChannel channel,
  TooltipDirection direction = TooltipDirection.bottom,
  EdgeInsets margin = const EdgeInsets.all(0),
  String link,
  String title,
  String description,
  String shareTitle,
  String shareDesc,
  String shareCover,
  bool isGenQrCode = true,
  String copyPrefix,
  String guildId,
  ShareLinkType linkType = ShareLinkType.other,
}) {
  // 在主播播放横屏直播时，观众可以横屏观看且分享时会强转成竖屏.为防止点击分享时被断成横屏逻
  // 辑走showShareLinkSettingPage，这里加上liveShare判断。
  final liveShare =
      linkType == ShareLinkType.live || linkType == ShareLinkType.livePlayback;
  if (OrientationUtil.portrait || liveShare) {
    showBottomModal(
      context,
      resizeToAvoidBottomInset: false,
      backgroundColor: CustomColor(context).backgroundColor6,
      builder: (c, s) => ShareLinkPopup(
        channel: channel,
        link: link,
        title: title,
        desc: description,
        shareTitle: shareTitle,
        shareDesc: shareDesc,
        shareCover: shareCover,
        isGenQrCode: isGenQrCode,
        copyPrefix: copyPrefix,
        guildId: guildId,
        linkType: linkType,
      ),
    );
  } else {
    showShareLinkSettingPage(context, channel: channel, url: link);
  }
}

class ShareLinkPopup extends StatefulWidget {
  final ChatChannel channel;
  final String link;
  final String title;
  final String desc;
  final String shareTitle;
  final String shareDesc;
  final String shareCover;
  final bool isGenQrCode;
  final String copyPrefix;
  final String guildId;
  final ShareLinkType linkType;

  const ShareLinkPopup({
    this.channel,
    this.link,
    this.title,
    this.desc,
    this.shareTitle,
    this.shareDesc,
    this.shareCover,
    this.isGenQrCode = true,
    this.copyPrefix,
    this.guildId,
    this.linkType = ShareLinkType.other,
  });

  @override
  _ShareLinkPopupState createState() => _ShareLinkPopupState();
}

class _ShareLinkPopupState extends State<ShareLinkPopup> {
  ShareLinkController controller;
  double _height;
  double _safeHeight;
  final double hasFriendHeight = 500;
  final double noFriendHeight = 360;

  @override
  void initState() {
    controller = ShareLinkController(
      guildId: widget.guildId,
      copyPrefix: widget.copyPrefix,
      linkValue: widget.link,
      title: widget.title,
      desc: widget.desc,
      shareTitle: widget.shareTitle,
      shareDesc: widget.shareDesc,
      shareCover: widget.shareCover,
      channel: widget.channel,
      linkType: widget.linkType,
    );
    super.initState();
    _safeHeight = getBottomViewInset();
    _height =
        (controller.hasFriend ? hasFriendHeight : noFriendHeight) + _safeHeight;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      /// 触发任务检查
      CustomTrigger.instance.dispatch(
        QuestTriggerData(
          condition: QuestCondition([
            QIDSegQuest.inviteFriend,
            GlobalState.selectedChannel.value?.guildId
          ]),
        ),
      );
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: ShareLinkNavigator(
        // 内部导航组件
        builder: (_) {
          return Column(
            children: <Widget>[
              GetBuilder<ShareLinkController>(
                  init: controller,
                  builder: (_) {
                    return Column(
                      children: <Widget>[
                        _buildTitle(),
                        _buildLink(),
                        Divider(
                          height: 8,
                          thickness: 8,
                          color: appThemeData.scaffoldBackgroundColor,
                        ),
                        _buildDmList(),
                        _buildShareType(),
                      ],
                    );
                  }),
              Container(
                height: 56,
                alignment: Alignment.center,
                child: FadeBackgroundButton(
                  onTap: Get.back,
                  borderRadius: btnBorderRadius,
                  backgroundColor: Get.theme.backgroundColor,
                  tapDownBackgroundColor:
                      Get.theme.backgroundColor.withOpacity(0.5),
                  child: Text(
                    '取消'.tr,
                    style: Get.textTheme.bodyText2.copyWith(fontSize: 17),
                  ),
                ),
              ),
              if (_safeHeight > 0)
                Container(
                    color: appThemeData.backgroundColor, height: _safeHeight)
            ],
          );
        },
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
        alignment: Alignment.centerLeft,
        height: 48,
        width: Get.width,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  controller.inviteLinkTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appThemeData.textTheme.bodyText2.copyWith(
                      fontSize: 17, fontWeight: FontWeight.bold, height: 1),
                ),
              ),
            ),
            _buildShareQRCodeButton(),
          ],
        ));
  }

  /// 构建分享二维码海报按钮
  Widget _buildShareQRCodeButton() {
    /// 不分享二维码海报
    if (!widget.isGenQrCode || controller.isLinkEmpty) return sizedBox;

    /// 分享二维码按钮
    return IconButton(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      icon: const Icon(IconFont.buffQrCode, size: 20),
      // todo 改成 get controller
      onPressed: () => Routes.pushShareGuildPosterPage(
          controller.guild, controller.getLink,
          onCopy: controller.onCopy),
    );
  }

  // 链接
  Widget _buildLink() {
    Widget _deadLineWidget() {
      String value = '';
      final isExpire = controller.minuteLeft == 0 || controller.timesLeft == 0;
      if (controller.minuteLeft == -1) {
        value += '永久有效，'.tr;
      } else {
        value += '有效期还剩 %s，'.trArgs([formatSecond(controller.minuteLeft)]);
      }
      if (controller.timesLeft == -1) {
        value += '无限次数'.tr;
      } else {
        value += '使用次数还剩 %s次'.trArgs([controller.timesLeft.toString()]);
      }
      if (isExpire) {
        value += '，请重置'.tr;
      }

      return Text(
        value,
        style: TextStyle(
            fontSize: 14,
            height: 1,
            color: isExpire
                ? appThemeData.errorColor
                : appThemeData.textTheme.bodyText1.color),
      );
    }

    Widget _buildBaseLink(String url, {EntityInviteUrl entity}) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.description,
              style: appThemeData.textTheme.bodyText1.copyWith(
                  fontSize: 14, height: 1, fontWeight: FontWeight.bold),
            ),
            sizeHeight10,
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: appThemeData.scaffoldBackgroundColor,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            url ?? '',
                            style: appThemeData.textTheme.bodyText2.copyWith(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: controller.onCopy,
                          child: const Icon(
                            IconFont.buffChatCopy,
                            size: 24,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                if (entity != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: GestureDetector(
                      onTap: () async {
                        expendPopup();
                        await shareLinkKey.currentState.pushNamed(
                            ShareLinkNavigatorState.linkHomeSetting,
                            arguments: ShareLinkSettingParam(
                              settingTimes: ShareLinkTimes.values.firstWhere(
                                  (e) =>
                                      e.value ==
                                      int.parse(entity.number ?? '0'),
                                  orElse: () => ShareLinkTimes.infinite),
                              settingDeadLine: ShareLinkDeadLine.values
                                  .firstWhere(
                                      (e) =>
                                          e.value ==
                                          int.parse(entity.time ?? '0'),
                                      orElse: () => ShareLinkDeadLine.infinite),
                              settingRemark: entity.remark,
                              channelName: widget.channel?.name,
                            ));
                        collapsePopup();
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: appThemeData.scaffoldBackgroundColor,
                        ),
                        child: Icon(
                          IconFont.buffSetting,
                          color: appThemeData.textTheme.bodyText2.color,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            sizeHeight10,
            _deadLineWidget(),
          ],
        ),
      );
    }

    if (widget.link != null) {
      return _buildBaseLink(widget.link);
    }
    return Stack(
      children: [
        _buildBaseLink(controller.link?.url, entity: controller.link),
        if (controller.linkLoadFailed ?? false)
          Positioned.fill(
            child: Container(
                color: CustomColor(context).backgroundColor6,
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: appThemeData.scaffoldBackgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(IconFont.buffChatWifiOff)),
                    sizeHeight6,
                    Text(
                      '网络异常，请检查网络后重试'.tr,
                      style: appThemeData.textTheme.bodyText1
                          .copyWith(fontSize: 14),
                    )
                  ],
                )),
          )
        else if (controller.getLink.noValue)
          Positioned.fill(
            child: Container(
                color: CustomColor(context).backgroundColor6,
                child: DefaultTheme.defaultLoadingIndicator()),
          ),
      ],
    );
  }

  // 私聊列表
  Widget _buildDmList() {
    final ts12 = copyWithFs12(Get.textTheme.bodyText2);
    return GetBuilder<DirectMessageController>(
      builder: (c) {
        const int maxLength = 15;
        List<ChatChannel> dmList = c.channelsDm ?? [];
        bool isMore = false;
        if (dmList.length > maxLength) {
          isMore = true;
          dmList = dmList.sublist(0, maxLength) ?? [];
        }
        if (dmList.isEmpty) {
          return const SizedBox();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text(
                    '私信给'.tr,
                    style:
                        ts12.copyWith(height: 1, fontWeight: FontWeight.bold),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dmList.map((channel) {
                      final userId = channel?.recipientId ?? channel?.guildId;
                      return Container(
                        child: UserInfo.consume(userId,
                            builder: (context, user, widget) {
                          final bool isMoreIcon =
                              isMore && channel == dmList.last;

                          return GestureDetector(
                            onTap: () =>
                                controller.shareToUser(isMoreIcon, userId),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                children: <Widget>[
                                  if (isMoreIcon)
                                    CircleIcon(
                                      icon: IconFont.buffPayArrowNext,
                                      size: 24,
                                      color: Get.theme.disabledColor,
                                      backgroundColor:
                                          Get.theme.scaffoldBackgroundColor,
                                      radius: 24,
                                    ),
                                  if (!isMoreIcon)
                                    RealtimeAvatar(
                                      userId: user.userId,
                                      size: 48,
                                    ),
                                  sizeHeight6,
                                  SizedBox(
                                    width: 48,
                                    child: Center(
                                      child: isMoreIcon
                                          ? Text(
                                              '更多'.tr,
                                              maxLines: 2,
                                              style: ts12.copyWith(height: 1),
                                            )
                                          : RealtimeNickname(
                                              userId: user.userId,
                                              maxLines: 2,
                                              style: ts12.copyWith(height: 1),
                                              showNameRule:
                                                  ShowNameRule.remarkAndGuild,
                                            ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        }),
                      );
                    })?.toList(),
                  ),
                ),
              ],
            ),
            sizeHeight20,
            Divider(
              color: appThemeData.scaffoldBackgroundColor,
            ),
          ],
        );
      },
    );
  }

  // 分享类型
  Widget _buildShareType() {
    final textStyle = copyWithFs12(Get.textTheme.bodyText2);
    const padding = EdgeInsets.symmetric(horizontal: 8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            '分享给'.tr,
            style: textStyle.copyWith(height: 1, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 85,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            children: [
              /// 分享给Fanbook好友
              ShareItem(
                config: FanbookShareToFriendConfig(),
                action: FanbookShareLinkAction(controller.getLink,
                    shareLinkType: controller.linkType),
                textStyle: textStyle,
                padding: padding,
              ),

              /// 分享给微信好友
              ShareItem(
                config: WechatShareToFriendConfig(),
                action: WechatShareLinkAction(
                  shareLinkType: controller.linkType,
                  title: controller.getShareTitle,
                  subtitle: controller.getShareDesc,
                  link: controller.getLink ?? '',
                  icon: controller.getShareCover,
                ),
                textStyle: textStyle,
                padding: padding,
              ),

              /// 分享到微信朋友圈
              ShareItem(
                config: WechatShareToMomentConfig(),
                action: WechatShareLinkAction(
                  title: controller.getShareTitle,
                  subtitle: controller.getShareDesc,
                  link: controller.getLink ?? '',
                  icon: controller.getShareCover,
                  scene: WeChatScene.TIMELINE,
                  shareLinkType: controller.linkType,
                ),
                textStyle: textStyle.copyWith(height: 1),
                padding: padding,
              ),
            ],
          ),
        ),
        sizeHeight10,
        Divider(
          height: 8,
          thickness: 8,
          color: appThemeData.scaffoldBackgroundColor,
        ),
      ],
    );
  }

  // 拓展popup，当没有好友的时候，popup会比较小，需要拓展高度，方便输入框输入内容
  void expendPopup() {
    if (controller.hasFriend) return;
    setState(() {
      _height = 500 + _safeHeight;
    });
    SheetController.of(context)?.expand();
  }

  // 收缩popup
  void collapsePopup() {
    if (controller.hasFriend) return;
    setState(() {
      _height = 360 + _safeHeight;
    });
    SheetController.of(context)?.collapse();
  }
}
