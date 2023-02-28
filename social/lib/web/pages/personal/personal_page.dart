import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/login/model/country_model.dart';
import 'package:im/pages/personal/personal_page.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/web/pages/personal/personal_info_page.dart';
import 'package:im/web/utils/confirm_dialog/message_box.dart';
import 'package:im/web/widgets/button/web_hover_button.dart';
import 'package:im/web/widgets/web_form_detector/web_form_page_view.dart';
import 'package:im/web/widgets/web_form_detector/web_form_tab_item.dart';
import 'package:im/web/widgets/web_form_detector/web_form_tab_view.dart';

import 'about_us_page/page.dart';
import 'html_page/page.dart';
import 'privacy_set_page.dart';

class PersonalPage extends StatefulWidget {
  @override
  _PersonalPageState createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  bool _logoutLoading = false;

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF0F1F2);
    return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: SizedBox(
            width: 1040,
            child: WebFormPage(
              tabItems: [
                WebFormTabItem.title(title: '用户设置'.tr),
                WebFormTabItem(
                    title: '个人中心'.tr, icon: IconFont.webMine, index: 0),
                WebFormTabItem(
                    title: '隐私设置'.tr, icon: IconFont.webPrivateSet, index: 1),
                const WebFormTabItem.builder(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: divider,
                  ),
                ),
                WebFormTabItem.builder(
                  onTap: () async {
                    AboutUsPage.disable();
                    await showFeedbackPage(context);
                    AboutUsPage.enable();
                  },
                  child: Container(
                      alignment: Alignment.center,
                      height: 40,
                      padding: const EdgeInsets.only(left: 18),
                      decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor),
                      child: Row(
                        children: [
                          Icon(
                            IconFont.buffChannelMessage,
                            size: 18,
                            color: CustomColor(context).disableColor,
                          ),
                          sizeWidth8,
                          Text('意见反馈'.tr,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: CustomColor(context).disableColor))
                        ],
                      )),
                ),
                WebFormTabItem(
                    title: '关于我们'.tr,
                    icon: IconFont.buffTabFriendList,
                    index: 3),
              ],
              tabViews: [
                WebFormTabView(
                  title: '个人中心'.tr,
                  index: 0,
                  child: PersonalInfoPage(),
                ),
                WebFormTabView(
                  title: '隐私设置'.tr,
                  index: 1,
                  desc: '这里可以更改你对个人隐私的设置'.tr,
                  child: PrivacySetPage(),
                ),
                WebFormTabView(
                  title: '意见反馈'.tr,
                  index: 2,
                  child: PersonalInfoPage(),
                ),
                WebFormTabView(
                  title: '关于我们'.tr,
                  index: 3,
                  child: AboutUsPage(),
                ),
              ],
              trailing: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 8, 12),
                    child: WebHoverButton(
                      color: Colors.transparent,
                      hoverColor: Theme.of(context).errorColor.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      onTap: _logout,
                      child: Row(
                        children: [
                          Icon(IconFont.webSignOut,
                              size: 20, color: Theme.of(context).errorColor),
                          sizeWidth10,
                          Text(
                            '退出登录'.tr,
                            style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).errorColor),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Future<void> _logout() async {
    await logout(context, onSuccess: (mobile, country) {
      _logoutLoading = false;
      Routes.popAndPushLoginPage(mobile, country);
    }, onError: () {
      _logoutLoading = false;
    }, beforeClear: () {
      if (_logoutLoading) return;
      _logoutLoading = true;
    });
  }

  Future<void> logout(BuildContext context,
      {VoidCallback onError,
      Function(String mobile, CountryModel country) onSuccess,
      VoidCallback beforeClear}) async {
    AboutUsPage.disable();
    await showWebMessageBox(
        title: '确认退出登录？'.tr,
        onConfirm: () {
          if (_logoutLoading) return;
          beforeClear?.call();
          clearData(onError: onError, onSuccess: onSuccess);

          /// 用户登出事件
          DLogManager.getInstance().guildLogout();
          DLogManager.getInstance().userLogout();
        });
    AboutUsPage.enable();
  }
}
