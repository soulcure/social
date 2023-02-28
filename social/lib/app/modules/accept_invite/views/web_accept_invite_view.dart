import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/button/primary_button.dart';
import 'package:im/widgets/certification_icon.dart';
import '../controllers/accept_invite_controller.dart';

class WebAcceptInviteView extends StatefulWidget {

  @override
  _WebAcceptInviteViewState createState() => _WebAcceptInviteViewState();
}

class _WebAcceptInviteViewState extends State<WebAcceptInviteView> {
  AcceptInviteController controller;

  @override
  void initState() {
    super.initState();

    controller = Get.put(AcceptInviteController());
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (controller.isExpire) {
      child = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: Theme
                  .of(context)
                  .scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              IconFont.buffChatLinkOff,
              color: Theme
                  .of(context)
                  .disabledColor,
              size: 48,
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Text(
            '邀请链接已失效'.tr,
            style: Theme
                .of(context)
                .textTheme
                .bodyText2
                .copyWith(fontSize: 18, height: 1),
          ),
          const SizedBox(
            height: 20,
          ),
          if (Global.user.id == controller.inviterId)
            Text(
              '可尝试生成一个新的邀请链接'.tr,
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyText1
                  .copyWith(fontSize: 13, height: 1),
            )
          else
            Obx(() {
              return Text(
                '向%s请求新的邀请链接'.trArgs([
                  controller.inviterNickname.value.takeCharacter(8).toString()
                ]),
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(fontSize: 13, height: 1),
              );
            }),
          SizedBox(
            width: MediaQuery
                .of(context)
                .size
                .width,
          )
        ],
      );
    } else {
      child = Obx(() {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: controller.joined.value
              ? _buildJoinedContent()
              : _buildAcceptContent(),
        );
      });
    }
    return GestureDetector(
      onTap: Navigator
          .of(context)
          .pop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            width: 480,
            height: 600,
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(8))),
            padding: const EdgeInsets.all(40),
            child: child,
          ),
        ),
      ),
    );
  }

  /// 未加入展示的组件
  List<Widget> _buildAcceptContent() {
    return [
      Center(
          child: Visibility(
              visible: isNotNullAndEmpty(controller.inviterAvatar.value),
              child: Avatar(url: controller.inviterAvatar.value, radius: 50))),
      sizeHeight16,
      Center(
          child:
          Text('%s邀请你加入以下服务器'.trArgs([controller.inviterNickname.value]))),
      const Spacer(flex: 4),
      _buildGuildInfo(),
      const Spacer(flex: 3),
      PrimaryButton(
        label: '接受邀请'.tr,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        loading: controller.isLoading.value,
        onPressed: controller.onAccept,
      ),
      Container(
        margin: const EdgeInsets.only(top: 16, bottom: 30),
        height: 48,
        width: double.infinity,
        child: TextButton(
          onPressed: () {
            // Navigator.of(context).pop();
            Get.back();
          },
          child: Text('不了，谢谢'.tr, style: Get.textTheme.bodyText1),
        ),
      )
    ];
  }

  /// 已加入展示的组件
  List<Widget> _buildJoinedContent() {
    return [
      Center(
          child: Visibility(
              visible: isNotNullAndEmpty(controller.inviterAvatar.value),
              child: Avatar(url: controller.inviterAvatar.value, radius: 50))),
      sizeHeight16,
      Center(
          child:
          Text('%s邀请你加入以下服务器'.trArgs([controller.inviterNickname.value]))),
      const Spacer(),
      _buildGuildInfo(),
      const Spacer(flex: 3),
      PrimaryButton(
        label: '已加入该服务器，点击进入'.tr,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        loading: controller.isLoading.value,
        onPressed: controller.webGoToGuild,
      ),
      const Spacer(flex: 12),
    ];
  }

  /// 服务器详情
  Widget _buildGuildInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Get.theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Avatar(
                url: isNotNullAndEmpty(controller.guildIcon.value)
                    ? controller.guildIcon.value
                    : Global.logoUrl,
                radius: 32,
              ),
              sizeWidth12,
              Flexible(
                  child: Text(controller.guildName.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Get.textTheme.bodyText2.copyWith(fontSize: 24))),
            ],
          ),
          CertificationIconWithText(
            // show: _authenticate == '2',
            profile: certificationProfileWith(controller.authenticate.value),
            fontWeight: FontWeight.bold,
            // fillColor: const Color(0xff6179F2).withOpacity(0.15),
            // textColor: const Color(0xff6179F2),
          ),
          sizeHeight15,
          Container(
            constraints: const BoxConstraints(minWidth: 200),
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Get.theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
//                getOnlineStatusIcon(
//                  context,
//                  PresenceStatus.offline,
//                ),
//                sizeWidth5,
                Text(
                  '%s 位成员'.trArgs([controller.memberNum.toString()]),
                  style: Get.textTheme.bodyText2.copyWith(fontSize: 15),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
