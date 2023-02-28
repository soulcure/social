import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/api.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/common/extension/uri_extension.dart';
import 'package:im/const.dart';
import 'package:im/core/config.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/db/db.dart';
import 'package:im/hybrid/jpush_util.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/login/model/country_model.dart';
import 'package:im/pages/tool/debug_page.dart';
import 'package:im/routes.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/random_string.dart';
import 'package:im/utils/show_confirm_popup.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/link_tile.dart';
import 'package:im/ws/ws.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../global.dart';
import '../../loggers.dart';

class AboutUsPage extends StatefulWidget {
  @override
  _AboutUsPageState createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  String _versionInfo = '';

  // oppo 的渠道显示注销账号
  // bool get isShowDelAccount => Global.deviceInfo.channel == "OP0S0N00666";

  // bool get isShowDelAccount => true;
  bool _logoutLoading = false;

  Future<void> init() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() =>
        _versionInfo = '${packageInfo.version}+${packageInfo.buildNumber}');
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    Loading.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    return WillPopScope(
        onWillPop: UniversalPlatform.isIOS
            ? null
            : () async {
                if (_logoutLoading) return false;
                return true;
              },
        child: Scaffold(
            appBar: CustomAppbar(
              title: '关于我们'.tr,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            body: Column(
              children: <Widget>[
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: DebugPage.show,
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      image: DecorationImage(
                        image: AssetImage('assets/images/icon.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                sizeHeight24,
                Text(appName,
                    style: _theme.textTheme.bodyText2.copyWith(fontSize: 24)),
                sizeHeight12,
                Text('v${_versionInfo ?? ''}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(fontSize: 14)),
                const SizedBox(height: 40),
                LinkTile(
                  context,
                  Text('用户协议'.tr),
                  height: 56,
                  onTap: () {
                    final Map<String, String> params = {
                      'udx': '93${DateTime.now().millisecondsSinceEpoch}3c',
                    };
                    final uri = Uri.parse(
                            '${Config.useHttps ? "https" : "http"}://${ApiUrl.termsUrl}')
                        .addParams(params);
                    Routes.pushHtmlPageWithUri(context, uri, title: '用户协议'.tr);
                  },
                ),
                LinkTile(
                  context,
                  Text('隐私政策'.tr),
                  height: 56,
                  onTap: () {
                    final Map<String, String> params = {
                      'udx': '93${DateTime.now().millisecondsSinceEpoch}3d',
                    };

                    final uri = Uri.parse(
                            '${Config.useHttps ? "https" : "http"}://${ApiUrl.privacyUrl}')
                        .addParams(params);
                    Routes.pushHtmlPageWithUri(context, uri, title: '隐私政策'.tr);
                  },
                ),
                LinkTile(
                  context,
                  Text('隐私权限设置'.tr),
                  height: 56,
                  onTap: () {
                    Get.toNamed(
                      app_pages.Routes.SYSTEM_PERMISSION_SETTING_PAGE,
                    );
                  },
                ),
                LinkTile(
                  context,
                  Text('个人信息收集清单'.tr),
                  height: 56,
                  onTap: () {
                    final Map<String, String> params = {
                      'udx': '93${DateTime.now().millisecondsSinceEpoch}3d',
                    };

                    final uri = Uri.parse(
                            '${Config.useHttps ? "https" : "http"}://${ApiUrl.personalInfoListUrl}')
                        .addParams(params);
                    Routes.pushHtmlPageWithUri(context, uri,
                        title: '个人信息收集清单'.tr);
                  },
                ),
                LinkTile(
                  context,
                  Text('第三方信息共享清单'.tr),
                  height: 56,
                  onTap: () {
                    final Map<String, String> params = {
                      'udx': '93${DateTime.now().millisecondsSinceEpoch}3d',
                    };

                    final uri = Uri.parse(
                            '${Config.useHttps ? "https" : "http"}://${ApiUrl.commonBillUrl}')
                        .addParams(params);
                    Routes.pushHtmlPageWithUri(context, uri,
                        title: '第三方信息共享清单'.tr);
                  },
                ),
                LinkTile(
                  context,
                  Text('服务器公约'.tr),
                  height: 56,
                  onTap: () {
                    final Map<String, String> params = {
                      'udx': '93${DateTime.now().millisecondsSinceEpoch}3d',
                    };

                    final uri = Uri.parse(
                            '${Config.useHttps ? "https" : "http"}://${ApiUrl.conventionUrl}')
                        .addParams(params);
                    Routes.pushHtmlPageWithUri(context, uri, title: '服务器公约'.tr);
                  },
                ),
                // if (isShowDelAccount) // oppo渠道要求有注销账号的功能
                Expanded(
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    child: TextButton(
                      onPressed: () async {
                        final select = await showConfirmPopup(
                          title: '确认注销当前账号？'.tr,
                          confirmStyle: Theme.of(context)
                              .textTheme
                              .bodyText2
                              .copyWith(
                                  fontSize: 17,
                                  color: DefaultTheme.dangerColor),
                        );
                        if (select == true) {
                          final selectAgain = await showConfirmPopup(
                            title:
                                '注销账号后，您将有15天的反悔期，在此期间重新登录可以找回账号，15天后您的所有Fanbook用户信息将会被删除，请再次确认'
                                    .tr,
                            confirmText: '确定注销'.tr,
                            confirmStyle: Theme.of(context)
                                .textTheme
                                .bodyText2
                                .copyWith(
                                    fontSize: 17,
                                    color: DefaultTheme.dangerColor),
                          );
                          if (selectAgain == true) {
                            _deleteAccount();
                            // Loading.show(context);
                            // Future.delayed(const Duration(milliseconds: 2000), () {
                            //   Loading.hide();
                            // });
                          }
                        }
                      },
                      child: Text("注销账号".tr,
                          style: _theme.textTheme.bodyText2
                              .copyWith(fontSize: 14)),
                    ),
                  ),
                ),
                sizeHeight20,
              ],
            )));
  }

  void _deleteAccount() {
    if (_logoutLoading) return;
    _logoutLoading = true;
    try {
      Loading.show(context);
      Future.delayed(const Duration(milliseconds: 1700), () {
        // 故意等一会儿
        clear();
        final String mobile = Global.user.mobile;
        CountryModel country;
        final countryString = SpService.to.getString(SP.country);
        if (countryString != null && countryString.isNotEmpty) {
          final map = json.decode(countryString);
          country = CountryModel.fromMap(map);
        }
        Future.delayed(const Duration(milliseconds: 300), () {
          if (kIsWeb) {
//            ChatTargetsModel.instance.directMessageListTarget = DirectMessageListTarget();
            // 暂时清理这4个，全部清除会出问题，暂时没时间找
            Db.dmListBox.clear();
            Db.channelBox.clear();
            Db.guildBox.clear();
            Db.friendListBox.clear();
          }

          Global.user = LocalUser()..cache();
          SpService.to.remove(SP.defaultChatTarget);
          if (!kIsWeb) {
            JPush().setBadge(0);
            JPushUtil.clearAllNotification();
          }
          Loading.hide();
          Routes.pop(context);
          Routes.pushLoginPage(context,
              mobile: mobile, country: country, replace: true);
          _logoutLoading = false;
        });
      });
    } catch (e) {
      logger.severe('退出登录错误', e);
      Loading.hide();
      _logoutLoading = false;
    }
  }

  void clear() {
    Config.permission = null;
    if (!kIsWeb) {
      JPushUtil.setAlias(RandomString.length(12));
    }
    Ws.instance.close();
    InMemoryDb.clear();
    ChatTargetsModel.instance.selectedChatTarget =
        ChatTargetsModel.instance.firstTarget;
    if (GlobalState.selectedChannel.value != null) {
      TextChannelController.to(channelId: GlobalState.selectedChannel.value.id)
          ?.internalList
          ?.clear();
      GlobalState.selectedChannel.value = null;
    }
    ChatTargetsModel.instance.clear();
  }
}
