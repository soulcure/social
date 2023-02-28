import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluwx/fluwx.dart';
import 'package:get/get.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/app/modules/scan_qr_code/controllers/scan_qr_code_controller.dart';
import 'package:im/common/extension/design_logical_pixels.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/certification_icon.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/share_link_popup/share_type.dart';
import 'package:im/widgets/toast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:oktoast/oktoast.dart';
import 'package:permission_handler/permission_handler.dart';

class ShareGuildPosterPage extends StatelessWidget {
  final GuildTarget guild;
  final posterKey = GlobalKey();

  /// 分享链接
  final String shareLink;

  static final Map<String, int> _guildMemeberCountMap = {};
  final RxInt _guildMemberCount = 0.obs;

  final VoidCallback onCopy;

  ShareGuildPosterPage({
    Key key,
    @required this.guild,
    @required this.shareLink,
    @required this.onCopy,
  })  : assert(guild != null),
        assert(shareLink.hasValue),
        super(key: key) {
    if (_guildMemeberCountMap[guild.id] == null) {
      _guildMemeberCountMap[guild.id] = 0;
    }
    _guildMemberCount.value = _guildMemeberCountMap[guild.id];
  }

  String get guildName => guild.name ?? '';

  String get inviteCode => Uri.parse(shareLink).pathSegments[0];

  @override
  Widget build(BuildContext context) {
    GuildApi.getGuildMemberCount(guild.id).then((value) {
      _guildMemberCount.value = value;
      _guildMemeberCountMap[guild.id] = value;
    });
    return Scaffold(
      backgroundColor: const Color(0x42000000),
      body: Stack(
        children: [
          /// 邀请海报
          _invitePosterCard(context),

          /// 分享弹窗
          _sharePopUp(context),
        ],
      ),
    );
  }

  /// 分享海报
  Widget _invitePosterCard(BuildContext context) {
    return Positioned(
      top: 45.px,
      left: 32.px,
      right: 32.px,
      child: RepaintBoundary(
        key: posterKey,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _userInfo(),
              _gap(28),
              _guildIcon(),
              _gap(20),
              _guildName(),
              _gap(6),
              _guildExtraInfo(),
              _gap(16),
              Container(
                width: 32.px,
                height: 1.px,
                color: const Color(0x4D8F959E),
              ),
              _gap(16),
              _joinText(),
              _gap(20),
              _qrCode(),
              _gap(10),
              Text(
                "打开Fanbook扫码加入".tr,
                style: const TextStyle(color: Color(0xFF8F959E), fontSize: 11),
              ),
              _gap(20),
              _inviteCode(),
              _gap(20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gap(double height) {
    return SizedBox(height: height.px);
  }

  /// 发起邀请的用户头像和昵称
  Widget _userInfo() {
    return Container(
      height: 52.px,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F8),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          sizeWidth24,
          RealtimeAvatar(
            userId: Global.user.id,
            size: 32.px,
            showBorder: false,
          ),
          sizeWidth12,
          RealtimeNickname(
            userId: Global.user.id,
            maxLength: 90,
            style: const TextStyle(
              color: Color(0xFF363940),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          sizeWidth5,
          Text(
            "邀请你加入".tr,
            style: const TextStyle(color: Color(0xFF8A8F99), fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// 服务器头像
  Widget _guildIcon() {
    return FlutterAvatar(
      url: guild.icon,
      size: 72.px,
      radius: 12,
      showBorder: false,
    );
  }

  /// 服务器名
  Widget _guildName() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        guildName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
    );
  }

  /// 显示：官方入驻服|务器成员数量
  Widget _guildExtraInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CertificationIconWithText(
          // show: showIcon,
          profile: certificationProfile,
          textColor: const Color(0xFF646A73),
          fillColor: Colors.white,
        ),
        if (certificationProfile != null)
          Container(
            height: 14.px,
            width: 1.px,
            margin: const EdgeInsets.only(right: 8, left: 2),
            color: const Color(0xFF646A73),
          ),
        ObxValue((v) {
          return Text(
            '%s位成员'.trArgs([v.value.toString()]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF646A73),
              fontSize: 12,
            ),
          );
        }, _guildMemberCount),
      ],
    );
  }

  /// 分享二维码
  Widget _qrCode() {
    return ScanQrCodeController.genQRCode(
      data: shareLink,
      size: 140.px,
      embeddedImg: const AssetImage("assets/images/icon.png"),
      embeddedImageSize: 20.px,
    );
  }

  /// 欢迎加入服务器文案
  Widget _joinText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        "欢迎加入「%s」服务器\n来和我一起畅聊吧~".trArgs([guildName]),
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Color(0xFF646A73), fontSize: 13, height: 1.5),
      ),
    );
  }

  /// 邀请码
  Widget _inviteCode() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 46.px,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F5),
        borderRadius: BorderRadius.circular(23.px),
        border: Border.all(color: const Color(0x1a8f959e)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "👋 服务器邀请码：".tr,
            style: const TextStyle(color: Color(0xFF646A73), fontSize: 13),
          ),
          Text(
            inviteCode,
            style: const TextStyle(
              color: Color(0xFF1F2125),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 分享弹窗
  Widget _sharePopUp(BuildContext context) {
    final bottom = MediaQueryData.fromWindow(window).padding.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 122.px,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              scrollDirection: Axis.horizontal,
              children: [
                /// 保存到本地
                _buildShareItem(
                  SaveImageConfig(),
                  SaveInvitePosterAction(_generateInvitePoster),
                ),

                /// 分享给微信好友
                _buildShareItem(
                  WechatShareToFriendConfig(),
                  WechatShareInvitePosterAction(_generateInvitePoster),
                ),

                /// 分享到微信朋友圈
                _buildShareItem(
                  WechatShareToMomentConfig(),
                  WechatShareInvitePosterAction(
                    _generateInvitePoster,
                    scene: WeChatScene.TIMELINE,
                  ),
                ),

                /// 复制链接
                _buildShareItem(
                  CopyLinkConfig(),
                  CopyLinkPosterAction(onCopy),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              alignment: Alignment.center,
              width: window.physicalSize.width,
              padding: EdgeInsets.symmetric(vertical: 17.5.px),
              color: Colors.white,
              child: Text(
                "取消".tr,
                style: const TextStyle(color: Color(0xFF1F2125), fontSize: 17),
              ),
            ),
          ),
          if (bottom > 0) Container(height: bottom, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildShareItem(ShareConfig config, ShareAction action) {
    return ShareItem(
      config: config,
      action: action,
      size: 56.px,
      radius: 10,
      iconBgColor: Colors.white,
      textStyle: const TextStyle(color: Color(0xFF646A73), fontSize: 10),
      padding: EdgeInsets.symmetric(horizontal: 6.px),
    );
  }

  Future<Uint8List> _generateInvitePoster() async {
    final RenderRepaintBoundary boundary =
        posterKey.currentContext.findRenderObject();
    final ratio = window.devicePixelRatio; // 获取当前设备的像素比
    final image = await boundary.toImage(pixelRatio: ratio);
    final _byteData = await image.toByteData(format: ImageByteFormat.png);
    return _byteData.buffer.asUint8List();
  }
}

typedef GeneratePoster = Future<Uint8List> Function();

/// 分享邀请海报到微信
class WechatShareInvitePosterAction extends ShareAction {
  /// 生成邀请海报的接口
  final GeneratePoster generatePoster;
  final WeChatScene scene;

  WechatShareInvitePosterAction(
    this.generatePoster, {
    this.scene = WeChatScene.SESSION,
  });

  @override
  Future<bool> shareAction() async {
    final rawData = await generatePoster();
    final image = WeChatImage.binary(rawData);
    final shareModel = WeChatShareImageModel(image, scene: scene);
    await shareToWeChat(shareModel);
    return true;
  }
}

/// 保存分享海报
class SaveInvitePosterAction extends ShareAction {
  /// 生成邀请海报的接口
  final GeneratePoster generatePoster;

  SaveInvitePosterAction(this.generatePoster)
      : super(
          isPopAfterShare: false,
          showLoading: false,
        );

  @override
  Future<bool> shareAction() async {
    /// 获得图片Uint8 list数据
    final rawImg = await generatePoster();

    /// ios android获取保存图片权限不一致，需要分别处理
    final permission = await checkSystemPermissions(
      context: Get.context,
      permissions: [
        if (UniversalPlatform.isIOS) Permission.photos,
        if (UniversalPlatform.isAndroid) Permission.storage
      ],
    );
    if (permission != true) {
      showToast('无权限获取相册，保存失败'.tr);
      return false;
    }

    /// 保存图片到相册
    final res = await ImageGallerySaver.saveImage(rawImg);
    if (res == null || res == '') {
      showToast("保存失败".tr);
      return false;
    }
    Toast.iconToast(icon: ToastIcon.success, label: "已保存到系统相册".tr);
    return true;
  }
}

/// 复制链接
class CopyLinkPosterAction extends ShareAction {
  final VoidCallback onCopy;

  CopyLinkPosterAction(this.onCopy)
      : super(isPopAfterShare: false, showLoading: false);

  @override
  Future<bool> shareAction() async {
    onCopy();
    return true;
  }
}
