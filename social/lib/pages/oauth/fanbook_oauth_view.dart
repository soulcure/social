import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/oauth_ben.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/pages/oauth/fanbook_oauth_controller.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/button/round_check_box.dart';
import 'package:im/widgets/circle_image.dart';
import 'package:im/widgets/realtime_user_info.dart';

import '../../global.dart';
import '../../icon_font.dart';

class FanbookOauthView extends StatelessWidget {
  final String clientId;
  static final double ratio =
      MediaQueryData.fromWindow(window).size.height / 812;
  final FanbookAuthController controller;

  FanbookOauthView(this.clientId)
      : controller = Get.find<FanbookAuthController>(tag: clientId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppInfo>(
      future: controller.getAppInfo,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          /// 加载失败
          return _buildRetry();
        }
        if (!snapshot.hasData) {
          /// 加载中
          return _buildLoading();
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 三方app头像，名称信息
                _buildAppInfoArea(snapshot.data),
                sizeHeight16,
                divider,
                _gap(28),

                /// 授予权限的描述
                _buildAuthInfo(snapshot.data),
                _gap(62),
                _button(
                  backgroundColor: primaryColor,
                  onPressed: controller.authConfirmed,
                  child: Text(
                    '同意'.tr,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                _gap(16),
                _button(
                    backgroundColor: const Color(0xFFEDEDED),
                    onPressed: controller.authCancel,
                    child: Text(
                      '取消'.tr,
                      style: TextStyle(color: primaryColor),
                    )),
                _gap(48),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _button({
    @required Color backgroundColor,
    @required child,
    Function onPressed,
    bool enable = true,
  }) {
    assert(child != null && backgroundColor != null);

    if (!enable) {
      backgroundColor = backgroundColor.withOpacity(0.5);
    }

    return IgnorePointer(
      ignoring: !enable,
      child: SizedBox(
        width: 184,
        height: 40,
        child: FadeButton(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          onTap: onPressed,
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.normal,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// 创建app信息区域
  Widget _buildAppInfoArea(AppInfo appInfo) {
    final avatarRadius = 46 * ratio;
    final avatarSize = avatarRadius * 2;
    final oauthNameStr = '${Global.user.nickname} #${Global.user.username}';
    String oauthAvatar;
    String fanbookAvatar;
    TextDirection direction;
    String oauthText;
    if (!controller.fromThirdParty) {
      direction = TextDirection.ltr;
      oauthAvatar = Global.user.avatar;
      fanbookAvatar = appInfo.avatarUrl;
      oauthText = "想访问您的Fanbook账户".tr;
    } else {
      direction = TextDirection.rtl;
      oauthAvatar = appInfo.avatarUrl;
      fanbookAvatar = 'assets/images/icon.png';
      oauthText = "想访问您的Fanbook".tr;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          textDirection: direction,
          mainAxisSize: MainAxisSize.min,
          children: [
            /// fanbook头像
            if (!controller.fromThirdParty)
              CircleImage(
                radius: avatarRadius,
                url: fanbookAvatar,
                hasBorder: true,
              )
            else
              CircleImage(
                radius: avatarRadius,
                asset: fanbookAvatar,
                hasBorder: true,
              ),
            const SizedBox(width: 18),
            const Icon(
              IconFont.buffMoreHorizontal,
              size: 20,
              color: Color(0xFFD8D8D8),
            ),

            const SizedBox(width: 18),

            /// 三方应用头像
            CircleImage(
              radius: avatarRadius,
              url: oauthAvatar,
              placeholder: (_, __) => Container(
                width: avatarSize,
                height: avatarSize,
                color: const Color(0xFFE0E2E6),
              ),
            ),
          ],
        ),
        _gap(24),
        Text(
          appInfo.appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(Get.context)
              .textTheme
              .bodyText2
              .copyWith(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        sizeHeight4,
        Text(
          oauthText,
          style:
              Theme.of(Get.context).textTheme.bodyText1.copyWith(fontSize: 16),
        ),
        if (!controller.fromThirdParty) ...[
          sizeHeight16,
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text.rich(
              TextSpan(
                  children: [
                    TextSpan(
                      text: '正在以 '.tr,
                    ),
                    TextSpan(
                      text: oauthNameStr,
                      style: Theme.of(Get.context)
                          .textTheme
                          .bodyText2
                          .copyWith(fontSize: 14),
                    ),
                    TextSpan(
                      text: ' 身份登录'.tr,
                    )
                  ],
                  style: Theme.of(Get.context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 14)),
              textAlign: TextAlign.center,
            ),
          ),
        ]
      ],
    );
  }

  /// 创建授权信息的区域
  Widget _buildAuthInfo(AppInfo appInfo) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 用户头像和用户名
        if (controller.fromThirdParty)
          Row(
            children: [
              RealtimeAvatar(
                userId: Global.user.id,
                size: 32 * ratio,
              ),
              const SizedBox(width: 12),
              RealtimeNickname(
                userId: Global.user.id,
                style: Theme.of(Get.context)
                    .textTheme
                    .bodyText2
                    .copyWith(fontSize: 16),
              ),
            ],
          ),
        _gap(24),
        if (appInfo.desc != null && appInfo.desc.isNotEmpty) ...[
          Text(
            "授权后将获取以下权限".tr,
            style: Theme.of(Get.context)
                .textTheme
                .bodyText1
                .copyWith(fontSize: 14),
          ),
          _gap(18),
          if (appInfo.userInfoDesc.hasValue)
            _buildAuthItem(
              appInfo.userInfoDesc,
              defaultValue: true,
            ),
          _gap(20),
          if (appInfo.userLinkDesc.hasValue)
            _buildAuthItem(
              appInfo.userLinkDesc,
              defaultValue: true,
            )
        ] else
          _buildAuthItem(
            "申请使用你的用户名和头像".tr,
            defaultValue: true,
          ),
      ],
    );
  }

  /// 构建加载中组件
  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// 构建失败重试组件
  Widget _buildRetry() {
    return Center(
      child: Column(
        children: [
          TextButton(
            onPressed: controller.retry,
            child: Text("请求失败，点击重试".tr),
          ),
          sizeHeight24,
          _button(
              backgroundColor: const Color(0xFFEDEDED),
              onPressed: controller.authCancel,
              child: Text(
                '取消'.tr,
                style: TextStyle(color: primaryColor),
              )),
        ],
      ),
    );
  }

  Widget _buildAuthItem(String text,
      {String subTitle, ValueChanged<bool> onChanged, bool defaultValue}) {
    return Column(
      children: [
        Row(
          children: [
            IgnorePointer(
              child: RoundCheckBox(
                size: 20,
                left: 0,
                right: 0,
                defaultValue: defaultValue,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(fontSize: 16, color: Color(0xFF1F2125)),
            ),
          ],
        ),
        if (subTitle.hasValue) ...[
          sizeHeight8,
          Container(
            padding: const EdgeInsets.only(left: 34),
            alignment: Alignment.centerLeft,
            child: Text(
              subTitle,
              style: const TextStyle(fontSize: 16, color: Color(0xFF8F959E)),
            ),
          )
        ]
      ],
    );
  }

  Widget _gap(double size) {
    return SizedBox(height: size * FanbookOauthView.ratio);
  }
}
