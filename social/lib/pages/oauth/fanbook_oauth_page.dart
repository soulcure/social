import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/pages/oauth/fanbook_oauth_controller.dart';
import 'package:im/pages/oauth/fanbook_oauth_view.dart';
import 'package:im/utils/deeplink_processor.dart';

class FanbookOAuthPage extends StatelessWidget {
  /// 三方应用在fanbook后台申请的client id
  final String clientId;

  /// 三方应用发送请求的唯一标识，授权结束时fanbook会将其原样返回，大小不能超过1k
  final String state;

  /// 通过三方应用打开时传入，用于通知外部授权结果
  final DeepLinkTaskNotifier notifier;

  const FanbookOAuthPage({
    Key key,
    @required this.clientId,
    @required this.state,
    this.notifier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FanbookAuthController>(
        tag: clientId,
        init: FanbookAuthController(
          context: context,
          clientId: clientId,
          state: state,
          notifier: notifier,
        ),
        builder: (controller) {
          return WillPopScope(
            onWillPop: () async {
              controller.authCancel();
              return false;
            },
            child: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: Column(
                  children: [
                    /// 标题
                    _buildTitle(context),
                    _gap(80),
                    FanbookOauthView(clientId),
                  ],
                ),
              ),
            ),
          );
        });
  }

  /// 创建title
  Widget _buildTitle(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44 * FanbookOauthView.ratio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.close, size: 24),
              onPressed:
                  Get.find<FanbookAuthController>(tag: clientId).authCancel,
            ),
          ),
          Text(
            "授权访问您的账号".tr,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gap(double size) {
    return SizedBox(height: size * FanbookOauthView.ratio);
  }
}
