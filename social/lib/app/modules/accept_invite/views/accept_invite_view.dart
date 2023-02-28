import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/design_logical_pixels.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/utils/deeplink_processor.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/primary_button.dart';
import 'package:im/widgets/certification_icon.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/user_info/realtime_nick_name.dart';

import '../controllers/accept_invite_controller.dart';

class AcceptInviteView extends GetView<AcceptInviteController> {
  ///这些颜色没有对应的属性
  final color1 = const Color(0xffF5F5F8);
  final color2 = const Color(0xff8A8F99);
  final color3 = const Color(0xff717D8D);
  final color4 = const Color(0xff646A73);
  final color5 = const Color(0xff8F959E);
  final color6 = const Color(0xff5C7099);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (controller.fromThirdPart) {
          controller.notifier.onError(DeepLinkTaskErrCode.INVITE_CANCEL);
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: color1,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Container(
            margin: EdgeInsets.all(16.px),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.px),
              boxShadow: [
                BoxShadow(
                    color: color3.withOpacity(0.1),
                    offset: Offset(0, 2.px),
                    blurRadius: 16.px),
              ],
            ),
            child: Obx(_buildContent),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return CustomAppbar(
      leadingCallback: () {
        if (controller.fromThirdPart) {
          controller.notifier.onError(DeepLinkTaskErrCode.INVITE_CANCEL);
        } else {
          Get.back();
        }
      },
    );
  }

  Widget _buildContent() {
    if (controller.isExpire) return _buildExpiredLinkInfo();

    if (controller.requestStatus.value == RequestStatus.waiting) {
      return _buildLoading();
    }
    if (controller.requestStatus.value == RequestStatus.error) {
      return _buildRetry();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _inviterHead(),
        const Spacer(),
        _buildNewGuildInfo(),
        const Spacer(),
        _buildButtonContent(),
        const Spacer(),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildRetry() {
    return Center(
        child: TextButton(
      onPressed: controller.fetchGuildInfo,
      child: Text("加载失败，点击重试".tr),
    ));
  }

  /// 构建链接过期的界面
  Widget _buildExpiredLinkInfo() {
    final context = Global.navigatorKey.currentContext;
    final style = Theme.of(context)
        .textTheme
        .bodyText1
        .copyWith(fontSize: 13, height: 1.px);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 160.px,
        ),
        Container(
          height: 100.px,
          width: 100.px,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(50.px),
          ),
          child: Icon(
            IconFont.buffChatLinkOff,
            color: Theme.of(context).disabledColor,
            size: 48.px,
          ),
        ),
        SizedBox(
          height: 24.px,
        ),
        Text(
          '邀请链接已失效'.tr,
          style: Theme.of(context)
              .textTheme
              .bodyText2
              .copyWith(fontSize: 18, height: 1),
        ),
        SizedBox(
          height: 20.px,
        ),
        if (Global.user.id == controller.inviterId)
          Text(
            '可尝试生成一个新的邀请链接'.tr,
            style: Theme.of(context)
                .textTheme
                .bodyText1
                .copyWith(fontSize: 13, height: 1),
          )
        else
          RichText(
            text: TextSpan(
              style: style,
              children: [
                TextSpan(text: "向".tr),
                WidgetSpan(
                  child: RealtimeNickname(
                    userId: controller.inviterId,
                    maxLength: 8,
                    style: style,
                  ),
                ),
                TextSpan(text: "请求新的邀请链接".tr),
              ],
            ),
          ),
        SizedBox(
          width: MediaQuery.of(context).size.width,
        )
      ],
    );
  }

  Widget _gapVertical(double height) {
    return SizedBox(height: height.px);
  }

  Widget _gapHorizontal(double width) {
    return SizedBox(width: width.px);
  }

  Widget _buildNewGuildInfo() {
    // final isOfficial = controller.authenticate == '2';
    final profile = certificationProfileWith(controller.authenticate.value);
    final description =
        profile == null ? '' : '${profile?.description ?? ''} ｜';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 56.px),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          //_gapVertical(110),
          ContainerImage(
            isNotNullAndEmpty(controller.guildIcon.value)
                ? controller.guildIcon.value
                : Global.logoUrl,
            radius: 16.px,
            width: 80.px,
            height: 80.px,
          ),
          _gapVertical(20),
          Text(
            controller.guildName.value,
            softWrap: true,
            style: Theme.of(Global.navigatorKey.currentContext)
                .textTheme
                .bodyText2
                .copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
          ),
          _gapVertical(12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (profile != null)
                CertificationIcon(
                  profile: profile,
                  size: 16.px,
                ),
              if (profile != null) _gapHorizontal(4.5),
              Text(
                '%s%s位成员'.trArgs(
                    [description, controller.memberNum.value.toString()]),
                style: TextStyle(
                  color: color4,
                  fontSize: 13,
                ),
              )
            ],
          ),
          Container(
            color: color5.withOpacity(0.3),
            width: 32.px,
            height: 1,
            margin: EdgeInsets.symmetric(vertical: 16.px),
          ),
          Text(
            '欢迎加入「%s」服务器，来和我一起畅聊吧~'.trArgs([controller.guildName.value]),
            textAlign: TextAlign.center,
            style: TextStyle(color: color4, fontSize: 14, height: 1.2),
          ),
          // Text(
          //   style: TextStyle(
          //     color: color4,
          //     fontSize: 14,
          //   ),
          // ),
        ],
      ),
    );
  }

  /// 已加入或接受邀请展示的组件
  Widget _buildButtonContent() {
    if (controller.joined.value)
      return _buildButton('已加入该服务器，点击进入'.tr, controller.goToGuild);
    else
      return _buildButton('接受邀请'.tr, controller.onAccept);
  }

  Widget _buildButton(String text, Function onPressed) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.px),
      child: Obx(
        () => PrimaryButton(
          loading: controller.isLoading.value,
          borderRadius: 24.px,
          onPressed: onPressed,
          label: text,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          height: 48.px,
        ),
      ),
    );
  }

  Widget _inviterHead() {
    if (controller.notifier != null) {
      // 从分享邀请页进来的，不显示邀请者
      return const SizedBox();
    }

    return Container(
      decoration: BoxDecoration(
        color: color1.withOpacity(0.8),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8.px),
          topRight: Radius.circular(8.px),
        ),
      ),
      height: 56.px,
      child: Row(
        children: [
          _gapHorizontal(16),
          RealtimeAvatar(
            userId: controller.inviterId,
            size: 32.px,
            showBorder: false,
          ),
          _gapHorizontal(8),
          RealtimeNickname(
            userId: controller.inviterId,
            style: const TextStyle(
              color: Color(0xFF363940),
              fontSize: 14,
            ),
          ),
          Text(
            ' 邀请你加入'.tr,
            style: TextStyle(
              color: color2,
              fontSize: 14,
              height: 1.25,
            ),
          ),
          _gapHorizontal(24),
        ],
      ),
    );
  }
}
