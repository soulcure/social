import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/api.dart';
import 'package:im/api/user_api.dart';
import 'package:im/api/wallet_api.dart';
import 'package:im/app/controllers/audio_room_controller.dart';
import 'package:im/app/modules/task/task_util.dart';
import 'package:im/app/modules/wallet/controllers/wallet_home_controller.dart';
// ignore: library_prefixes
import 'package:im/app/routes/app_pages.dart' as AppPages;
import 'package:im/app/routes/spectial_routes.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/uri_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/db/db.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/global.dart';
import 'package:im/hybrid/jpush_util.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/live_status_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/login/model/country_model.dart';
import 'package:im/pay/pay_manager.dart';
import 'package:im/routes.dart';
import 'package:im/services/server_side_configuration.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/check_media_conflict_util.dart';
import 'package:im/utils/random_string.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/user.dart';
import 'package:im/utils/web_view_utils.dart';
import 'package:im/widgets/audio_player_manager.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/dialog/update_dialog.dart';
import 'package:im/widgets/fb_ui_kit/form/form_builder.dart';
import 'package:im/widgets/fb_ui_kit/form/form_fix_child_model.dart';
import 'package:im/widgets/id_with_copy.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/segment_list/segment_member_list_service.dart';
import 'package:im/ws/ws.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';
import 'package:quest_system/quest_system.dart';

import '../../loggers.dart';

class PersonalPage extends StatefulWidget {
  @override
  _PersonalPageState createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  bool _logoutLoading = false;
  ValueNotifier<bool> debugIsEnable = ValueNotifier(false);

  /// ??????????????????????????????
  bool get isChineseMobile =>
      ServerSideConfiguration.to.isChineseMobile(Global.user.mobile);

  @override
  void initState() {
    init();
    super.initState();
  }

  /// - ?????????
  Future<void> init() async {
    //  ????????????????????????????????????????????????????????????????????????????????????????????????
    if (isChineseMobile) {
      //  ??????????????????
      await WalletApi.queryWalletHomeData(userId: Global.user.id)
          .then((newWallet) {
        if (newWallet == null) return;
        ServerSideConfiguration.to.nftId = newWallet.nftUserId;
        ServerSideConfiguration.to.nftCollectTotal = newWallet.collectTotal;
        if (mounted) setState(() {});
      });
    }
    debugIsEnable.value = await UserApi.getAllowRoster('video');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusHeight = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Container(
        color: Colors.transparent,
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: <Widget>[
              _buildTopTitle(statusHeight),
              _buildProfile(context),
              sizeHeight16,

              ///?????????????????????????????????????????????????????????
              if (ServerSideConfiguration.to.walletIsOpen)
                FbForm.common(
                  '????????????'.tr,
                  isShowArrow: true,
                  suffixChildModel: FbFormLabelSuffixChild(
                    //  ?????????????????????????????????
                    //  - 1???????????????????????????????????????????????????????????????????????????????????????????????????????????????
                    //  - 2??????????????????????????????nft???????????????id ???????????????????????????????????????????????????????????????????????????????????????????????????
                    (!isChineseMobile ||
                            ServerSideConfiguration.to.nftId == null)
                        ? ""
                        : ServerSideConfiguration.to.nftId.isEmpty
                            ? '?????????'.tr
                            : ServerSideConfiguration.to.nftCollectTotal ?? "0",
                    color: Get.theme.disabledColor,
                  ),
                  position: ServerSideConfiguration.to.payIsOpen
                      ? FbFormPosition.top
                      : FbFormPosition.singleLine,
                  onTap: () {
                    //  ???????????????????????????
                    Get.toNamed(
                      AppPages.Routes.WALLET_HOME_PAGE,
                      arguments: WalletHomeController.inputParams(
                        userId: Global.user.id,
                        userName: Global.user.nickname,
                        isChineseMobile: isChineseMobile,
                      ),
                    );
                  },
                ),

              ///???????????????????????????????????????????????????
              if (ServerSideConfiguration.to.payIsOpen)
                FbForm.common(
                  '??????'.tr,
                  isShowArrow: true,
                  position: ServerSideConfiguration.to.walletIsOpen
                      ? FbFormPosition.bottom
                      : FbFormPosition.singleLine,
                  onTap: Routes.pushLedouPage,
                ),
              if (ServerSideConfiguration.to.walletIsOpen ||
                  ServerSideConfiguration.to.payIsOpen)
                sizeHeight16,

              FbForm.common(
                '????????????'.tr,
                isShowArrow: true,
                position: FbFormPosition.top,
                onTap: () => Routes.pushNotificationSettingsPage(context),
              ),
              FbForm.common(
                '????????????'.tr,
                isShowArrow: true,
                position: FbFormPosition.middle,
                onTap: () => Routes.pushPrivacySetPage(context),
              ),
              FbForm.common(
                '????????????'.tr,
                isShowArrow: true,
                position: FbFormPosition.bottom,
                onTap: () => Get.toNamed(AppPages.Routes.BIND_PAYMENT),
              ),
              sizeHeight16,

              FbForm.common(
                '????????????'.tr,
                isShowArrow: true,
                position: FbFormPosition.top,
                onTap: () => Routes.pushCleanCachePage(context),
              ),
              FbForm.common(
                '????????????'.tr,
                isShowArrow: true,
                position: FbFormPosition.middle,
                onTap: feedback,
              ),
              if (!kIsWeb) const CheckUpdateButton(isFromPersonalPage: true),
              FbForm.common(
                '????????????'.tr,
                isShowArrow: true,
                position: FbFormPosition.bottom,
                onTap: () => Routes.pushAboutUsPage(context),
              ),
              sizeHeight16,

              ValueListenableBuilder(
                valueListenable: debugIsEnable,
                builder: (context, value, child) {
                  return value
                      ? FbForm.common(
                          '??????????????????'.tr,
                          isShowArrow: true,
                          position: FbFormPosition.bottom,
                          onTap: () => Get.toNamed(
                              AppPages.Routes.EXPERIMENTAL_FEATURES_PAGE),
                        )
                      : const SizedBox();
                },
              ),
              ValueListenableBuilder(
                valueListenable: debugIsEnable,
                builder: (context, value, child) {
                  return value ? sizeHeight16 : const SizedBox();
                },
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.only(bottom: 20),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  child: FadeButton(
                    height: 52,
                    backgroundColor: theme.backgroundColor,
                    onTap: _logout,
                    child: Text(
                      '????????????'.tr,
                      style: theme.textTheme.bodyText1
                          .copyWith(color: DefaultTheme.dangerColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopTitle(double statusHeight) {
    return Container(
      color: Get.theme.backgroundColor,
      padding: EdgeInsets.only(left: 16, top: statusHeight, right: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: SpectialRoutes.openQrScanner,
            iconSize: 22,
            icon: Icon(IconFont.buffScanQr,
                color: appThemeData.textTheme.bodyText1.color),
          )
        ],
      ),
    );
  }

  Container _buildProfile(BuildContext context) {
    return Container(
      color: Get.theme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 20),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Routes.pushModifyUserInfoPage(context);
        },
        child: Consumer<LocalUser>(
          builder: (context, user, _) {
            if (user?.id == null) return const SizedBox();
            return Row(
              children: <Widget>[
                RealtimeAvatar(
                  userId: user.id,
                  size: 64,
                ),
                sizeWidth12,
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                              child: RealtimeNickname(
                            userId: user.id,
                            showNameRule: ShowNameRule.remark,
                            breakWord: true,
                            style: Get.theme.textTheme.bodyText2.copyWith(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          )),
                          sizeWidth4,
                          getGenderIcon(user.gender, size: 16),
                          sizeWidth5,
                        ],
                      ),
                      sizeHeight8,
                      IdWithCopy(user.username),
                    ],
                  ),
                ),
                const MoreIcon()
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _logout() async {
    // ????????????????????????????????????????????????????????????????????????????????????
    final exitLive = await checkAndExitLiveRoom();
    if (!exitLive) {
      return;
    }
    await logout(context, onSuccess: (mobile, country) {
      _logoutLoading = false;
      QuestSystem.clear();
      Routes.pop(context);
      Routes.pushLoginPage(context,
          mobile: mobile, country: country, replace: true);
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
    unawaited(showConfirmDialog(
        title: '?????????????????????'.tr,
        onConfirm: () {
          if (_logoutLoading) return;

          /// ??????????????????
          ServerSideConfiguration.to.nftId = null;
          ServerSideConfiguration.to.nftCollectTotal = "0";

          /// ?????????????????????,????????????????????????
          PayManager.removeObservingPaymentQueue();

          /// ?????????????????????,????????????
          if (GlobalState.mediaChannel.value != null &&
              GlobalState.mediaChannel.value.item2 != null) {
            final ChatChannel channel = GlobalState.mediaChannel.value.item2;
            try {
              final AudioRoomController c =
                  Get.find<AudioRoomController>(tag: channel.id);
              c.closeAndDispose(flag: 2);
            } catch (_) {}
          }

          /// ??????????????????
          DLogManager.getInstance().guildLogout();
          DLogManager.getInstance().userLogout();
          beforeClear?.call();
          clearData(onError: onError, onSuccess: onSuccess);
          TaskUtil.instance.clear();

          ///???????????????: ????????????????????????????????????http
          Http.init(closeOld: true);
          WebViewUtils.instance().deleteAll();

          /// ?????????????????????????????????
          if (AudioPlayerManager.instance.isPlaying)
            unawaited(AudioPlayerManager.instance.stop());
        }));
  }
}

// todo ???????????? _logout ??????
void clearData(
    {VoidCallback onError,
    Function(String mobile, CountryModel country) onSuccess}) {
  try {
    clear();
    final String mobile = Global.user.mobile;
    CountryModel country;
    final countryString = SpService.to.getString(SP.country);
    if (countryString != null &&
        countryString.isNotEmpty &&
        countryString != "null") {
      final map = json.decode(countryString);
      country = CountryModel.fromMap(map);
    }
    Future.delayed(const Duration(milliseconds: 300), () {
      if (kIsWeb) {
//            ChatTargetsModel.instance.directMessageListTarget = DirectMessageListTarget();
        // ???????????????4???????????????????????????????????????????????????
        Db.dmListBox.clear();
        Db.channelBox.clear();
        Db.guildBox.clear();
        Db.friendListBox.clear();
        Db.guildRecentAtBox.clear();
      }

      SegmentMemberListService.to.cleanDataModelCache();

      Global.user = LocalUser()..cache();
      Config.token = null;
      SpService.to.remove(SP.defaultChatTarget);
      ServerSideConfiguration.to.aliPayUid = null;
      if (!kIsWeb) {
        JPush().setBadge(0);
        JPushUtil.clearAllNotification();
      }
      onSuccess?.call(mobile, country);
    });
  } catch (e) {
    logger.severe('??????????????????', e);
    onError?.call();
  }
}

void clear() {
  Config.permission = null;
  if (UniversalPlatform.isMobileDevice) {
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
  }
  GlobalState.selectedChannel.value = null;
  ChatTargetsModel.instance.clear();
  LiveStatusManager.instance.clear();
}

Future<void> feedback() async {
  String appVersion;
  if (kIsWeb) {
    appVersion = '';
  } else {
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
  }

  final Map<String, String> params = {
    'udx': '93${DateTime.now().millisecondsSinceEpoch}3c',
    'app_version': appVersion,
    'user_name': Global.user.username,
    'user_id': Global.user.id,
    'nickname': Global.user.nickname,
  };

  final uri =
      Uri.parse('${Config.useHttps ? "https" : "http"}://${ApiUrl.feedbackUrl}')
          .addParams(params);
  await Routes.pushHtmlPageWithUri(Get.context, uri,
      title: '????????????'.tr, appendTokenToUrl: true);
}
