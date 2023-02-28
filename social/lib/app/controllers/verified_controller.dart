import 'package:get/get.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/modules/create_guide_select_template/views/land_create_guild_select_template_page_view.dart';
import 'package:im/app/modules/mini_program_page/controllers/mini_program_page_controller.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/core/config.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/global.dart';
import 'package:im/locale/message_keys.dart';
import 'package:im/routes.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

class VerifiedController extends GetxController {
  bool _white = false;

  int _checkCode = 0;

  @override
  void onInit() {
    _checkCreateGuildAllow();
    _checkWhite();
    super.onInit();
  }

  ///获取状态码
  Future<void> _checkCreateGuildAllow() async {
    await GuildApi.checkCreateGuild(
      userId: Global.user.id,
      isOriginDataReturn: true,
    ).then((v) => _checkCode = v['code']);
  }

  ///检查是否白名单
  void _checkWhite() {
    UserApi.getAllowRoster('guild').then((v) => _white = v ?? false);
  }

  void onTap({bool preventDuplicateMiniProgram = false}) {
    if (preventDuplicateMiniProgram &&
        Get.isRegistered<MiniProgramPageController>()) {
      return;
    } else if (_checkCode == 1101) {
      showToast("你可创建的服务器已达上限！".tr);
      return;
    } else if (_white || _checkCode == 1000) {
      _jumpCreatePage();
      return;
    } else if (_checkCode == 0) {
      showToast(networkErrorText);
      return;
    } else {
      _onAuthTap();
      return;
    }
  }

  ///实名认证流程问卷流程
  Future<void> _onAuthTap() async {
    if (OrientationUtil.landscape) {
      showToast('请通过Fanbook APP申请创建服务器'.tr);
      return;
    }

    /// 申请创建服务器小程序链接
    String url =
        "${Config.miniProgramHost}/mp/191787698774609920/231712076446302208/serverApply-v4/?fb_redirect&open_type=mp";
    if (Get.locale.languageCode != MessageKeys.zh) {
      /// 如果是非中国地区继续旧的逻辑
      url =
          "${Config.miniProgramHost}/mp/191787698774609920/231712076446302208/serverApply?fb_redirect&open_type=mp";
    }
    await Routes.pushMiniProgram(url);
    await _checkCreateGuildAllow();
    if (_checkCode == 1000) {
      unawaited(
          Get.toNamed(app_pages.Routes.CONFIG_GUILD_SELECT_TEMPLATE_PAGE));
    }
  }

  void _jumpCreatePage() {
    if (OrientationUtil.landscape) {
      unawaited(Get.dialog(LandCreateGuildSelectTemplatePageView()));
    } else {
      unawaited(
          Get.toNamed(app_pages.Routes.CONFIG_GUILD_SELECT_TEMPLATE_PAGE));
    }
  }
}
