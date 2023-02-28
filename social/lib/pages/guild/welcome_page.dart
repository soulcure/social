import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/controllers/verified_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/icon_font.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/utils/invite_code/invite_code_util.dart';
import 'package:websafe_svg/websafe_svg.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    ///TODO:这里需要处理用户在欢迎页面退出app的情况
    ///fix: 用户有私信 无服务器台，导致数据库重复open hive报错 has closed
    ///Db.open(Global.user.id);
    super.initState();

    DLogManager.getInstance().customEvent(
        actionEventId: 'enter_invite_page',
        pageId: 'page_invite',
        extJson: {"invite_code": InviteCodeUtil.inviteCode});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              child: WebsafeSvg.asset(
                'assets/svg/login_page_bg.svg',
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                width: Get.width,
              ),
            ),
            SafeArea(
              /// FIXME: 2021/12/16 此处存在像素溢出
              child: Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () {
                          Get.back();
                        },
                        icon: const Icon(
                          IconFont.buffNavBarCloseItem,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  // const SizedBox(height: 44),
                  SizedBox(
                    height: 176,
                    child: Center(
                      child: ImageWidget.fromAsset(AssetImageBuilder(
                          'assets/app-icon/icon.png',
                          width: 80,
                          height: 80)),
                    ),
                  ),
                  Text('Hello，新朋友'.tr,
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.w400)),
                  sizeHeight12,
                  Text('是时候告别传统社区了!'.tr,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w400)),
                  const SizedBox(height: 48),
                  Text(
                    '你需要通过邀请码才能进入服务器\n当然，你也可以创建自己的服务器'.tr,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xff5c6273),
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: pushInvitePage,
                    child: Container(
                      height: 44,
                      width: 210,
                      decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(6)),
                      alignment: Alignment.center,
                      child: Text(
                        '加入服务器'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  sizeHeight20,
                  GetBuilder<VerifiedController>(
                    init: VerifiedController(),
                    builder: (controller) => GestureDetector(
                      onTap: () {
                        controller.onTap(preventDuplicateMiniProgram: true);
                        DLogManager.getInstance().customEvent(
                          actionEventId: "guild_apply_create",
                          actionEventSubId: "click_create",
                          actionEventSubParam: "reg_user",
                        );
                      },
                      child: Container(
                        height: 44,
                        width: 210,
                        decoration: BoxDecoration(
                            color: const Color(0xFFF5F6FA),
                            borderRadius: BorderRadius.circular(6)),
                        alignment: Alignment.center,
                        child: Text(
                          '创建服务器'.tr,
                          style: TextStyle(
                              fontSize: 16, color: appThemeData.primaryColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 64),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void pushInvitePage() {
    Routes.pushJoinGuildPage(context);
  }
}
