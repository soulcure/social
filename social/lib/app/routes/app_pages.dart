import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/bindings/online_document_binding.dart';
import 'package:im/app/modules/document_online/info/bindings/view_document_info_binding.dart';
import 'package:im/app/modules/document_online/info/views/view_document_info_page.dart';
import 'package:im/app/modules/document_online/search/bindings/document_search_binding.dart';
import 'package:im/app/modules/document_online/search/views/document_search_page.dart';
import 'package:im/app/modules/document_online/select/bindings/document_select_binding.dart';
import 'package:im/app/modules/document_online/select/views/document_select_page.dart';
import 'package:im/app/modules/document_online/views/online_document_page.dart';
import 'package:im/app/modules/wallet/bindings/wallet_collect_detail_binding.dart';
import 'package:im/app/modules/wallet/bindings/wallet_home_binding.dart';
import 'package:im/app/modules/wallet/bindings/wallet_verified_binding.dart';
import 'package:im/app/modules/wallet/views/wallet_collect_detail_page.dart';
import 'package:im/app/modules/wallet/views/wallet_home_page.dart';
import 'package:im/app/modules/wallet/views/wallet_verified_page.dart';

import '../../common/extension/string_extension.dart';
import '../../community/unity_view_page.dart';
import '../../core/engine.dart';
import '../../global.dart';
import '../../pages/bot_market/bindings/bot_market_page_binding.dart';
import '../../pages/bot_market/bot_market_page_view.dart';
import '../../pages/guild_setting/channel/channel_manage_page.dart';
import '../../pages/guild_setting/role/role_manage_page.dart';
import '../../pages/home/home_page.dart';
import '../../pages/login/login_page.dart';
import '../../pages/splash/protocal_page.dart';
import '../../pages/splash/splash_page.dart';
import '../../pages/topic/bindings/topic_binding.dart';
import '../../pages/topic/topic_page.dart';
import '../modules/accept_invite/bindings/accept_invite_binding.dart';
import '../modules/accept_invite/views/accept_invite_view.dart';
import '../modules/bind_payment/bindings/bind_payment_binding.dart';
import '../modules/bind_payment/views/bind_payment_view.dart';
import '../modules/black_list/bindings/black_list_binding.dart';
import '../modules/black_list/views/black_list_page.dart';
import '../modules/bot_detail_page/bindings/bot_detail_page_binding.dart';
import '../modules/bot_detail_page/views/bot_detail_page_view.dart';
import '../modules/channel_command_setting_page/bindings/channel_command_setting_page_binding.dart';
import '../modules/channel_command_setting_page/views/channel_command_setting_page_view.dart';
import '../modules/circle/views/circle_view.dart';
import '../modules/circle_detail/bindings/circle_detail_binding.dart';
import '../modules/circle_detail/views/circle_detail_view.dart';
import '../modules/circle_search/views/circle_search_view.dart';
import '../modules/circle_video_page/bindings/circle_video_page_binding.dart';
import '../modules/circle_video_page/route/circle_video_transtion.dart';
import '../modules/circle_video_page/views/circle_video_view.dart';
import '../modules/common_share_page/views/common_share_page_view.dart';
import '../modules/config_guild_assistant_page/bindings/config_guild_assistant_page_binding.dart';
import '../modules/config_guild_assistant_page/views/config_guild_assistant_page_view.dart';
import '../modules/create_guide_select_template/bindings/create_guild_select_template_page_binding.dart';
import '../modules/create_guide_select_template/views/create_guild_select_template_page_view.dart';
import '../modules/direct_message/bindings/direct_message_binding.dart';
import '../modules/direct_message/views/direct_message_view.dart';
import '../modules/dynamicViewPreview/bindings/dynamic_view_preview_binding.dart';
import '../modules/dynamicViewPreview/views/dynamic_view_preview_view.dart';
import '../modules/experimental_features_page/bindings/experimental_features_page_binding.dart';
import '../modules/experimental_features_page/views/experimental_features_page_view.dart';
import '../modules/file/bindings/file_select_binding.dart';
import '../modules/file/views/file_select_page_view.dart';
import '../modules/friend_apply_page/views/friend_apply_page_view.dart';
import '../modules/friend_list_page/bindings/friend_list_page_binding.dart';
import '../modules/friend_list_page/views/friend_list_page_view.dart';
import '../modules/guest/bindings/guest_binding.dart';
import '../modules/guest/views/guest_view.dart';
import '../modules/mini_program_page/bindings/mini_program_page_binding.dart';
import '../modules/mini_program_page/views/mini_program_page_view.dart';
import '../modules/multi_channel_command_shortcuts_settings_page/bindings/multi_channel_command_shortcuts_settings_page_binding.dart';
import '../modules/multi_channel_command_shortcuts_settings_page/views/multi_channel_command_shortcuts_settings_page_view.dart';
import '../modules/mute/bindings/mute_list_binding.dart';
import '../modules/mute/views/mute_list_page.dart';
import '../modules/private_channel_access_page/bindings/private_channel_access_page_binding.dart';
import '../modules/private_channel_access_page/views/private_channel_access_page_view.dart';
import '../modules/redpack/open_pack/binding/open_redpack_binding.dart';
import '../modules/redpack/open_pack/components/open_redpack_detail_transition.dart';
import '../modules/redpack/open_pack/views/open_redpack_detail_page.dart';
import '../modules/redpack/send_pack/bindings/send_redpack_page_binding.dart';
import '../modules/redpack/send_pack/views/send_redpack_page.dart';
import '../modules/scan_qr_code/bindings/scan_qr_code_binding.dart';
import '../modules/scan_qr_code/views/scan_qr_code_view.dart';
import '../modules/send_code/bindings/send_code_binding.dart';
import '../modules/send_code/views/send_code_view.dart';
import '../modules/system_permission_setting_page/bindings/system_permission_setting_binding.dart';
import '../modules/system_permission_setting_page/views/system_permission_setting_page.dart';
import '../modules/task/introduction_ceremony/bindings/task_introduction_ceremony_binding.dart';
import '../modules/task/introduction_ceremony/open_task_introduction_ceremony.dart';
import '../modules/task/introduction_ceremony/views/task_introduction_ceremony_view.dart';
import '../modules/tc_doc_add_group_page/bindings/tc_doc_add_group_page_binding.dart';
import '../modules/tc_doc_add_group_page/views/tc_doc_add_group_page_view.dart';
import '../modules/tc_doc_groups_page/bindings/tc_doc_groups_page_binding.dart';
import '../modules/tc_doc_groups_page/views/tc_doc_groups_page_view.dart';
import '../modules/tc_doc_page/bindings/tc_doc_page_binding.dart';
import '../modules/tc_doc_page/views/tc_doc_page_view.dart';
import '../modules/ui_gallery/views/ui_gallery_view.dart';
import '../modules/welcome_setting/bindings/welcome_setting_binding.dart';
import '../modules/welcome_setting/views/welcome_setting_view.dart';
import '../modules/welcome_setting_select_channel/bindings/welcome_setting_select_channel_binding.dart';
import '../modules/welcome_setting_select_channel/views/welcome_setting_select_channel_view.dart';

part 'app_routes.dart';

class _GetMiddleware extends GetMiddleware {
  @override
  RouteSettings redirect(String route) {
    if (route == '/login' && !Engine.initialized) {
      return const RouteSettings(name: '/');
    } else if (Global.user.id.noValue && !'splash,/'.contains(route)) {
      return const RouteSettings(name: '/');
    }
    return null;
  }
}

class _TaskGetMiddleware extends GetMiddleware {
  @override
  RouteSettings redirect(String route) {
    if (OpenTaskIntroductionCeremony.isOpenTaskInterface() &&
        route == Routes.MINI_PROGRAM_PAGE) {
      return const RouteSettings(name: Routes.TASK_INTRODUCTION_CEREMONY);
    }
    return null;
  }
}

// web上的路由获取到的路径是带 / 的，具体原因还没深究 ，所有定义路由的时候暂时需要把带/的也加上，不然会匹配不到
class AppPages {
  static const INITIAL = "/splash";

  static final routes = [
    // GetPage(
    //   name: _Paths.HOME,
    //   page: () => HomeView(),
    //   binding: HomeBinding(),
    // ),
    GetPage(
      name: "/",
      transition: Transition.fadeIn,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: "/splash",
      transition: Transition.fadeIn,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: "/protocal",
      transition: Transition.fadeIn,
      page: () => ProtocalPage(),
    ),
    GetPage(
        name: "/login",
        transition: Transition.fadeIn,
        page: () => const LoginPage(),
        middlewares: [_GetMiddleware()]),
    GetPage(
      name: "/home",
      page: () => HomePage(),
      middlewares: [_GetMiddleware()],
    ),
    GetPage(
      name: _Paths.EXPERIMENTAL_FEATURES_PAGE,
      page: () => ExperimentalFeaturesPageView(),
      binding: ExperimentalFeaturesPageBinding(),
    ),
    GetPage(
      name: _Paths.TASK_INTRODUCTION_CEREMONY,
      transition: Transition.downToUp,
      popGesture: false,
      page: () => TaskIntroductionCeremonyView(),
      binding: TaskIntroductionCeremonyBinding(),
    ),
    GetPage(
      name: _Paths.MINI_PROGRAM_PAGE,
      page: () => MiniProgramPageView(),
      middlewares: [_TaskGetMiddleware()],
      binding: MiniProgramPageBinding(),
      transition: Transition.downToUp,
      popGesture: false,
      fullscreenDialog: true,
    ),
    GetPage(
      name: _Paths.TOPIC_PAGE,
      page: () => const TopicPage(),
      binding: TopicPageBinding(),
    ),
    GetPage(
      name: _Paths.DIRECT_MESSAGE,
      page: () => DirectMessageView(),
      binding: DirectMessageBinding(),
    ),
    GetPage(
        name: _Paths.FRIEND_LIST_PAGE,
        page: () => const FriendListPageView(),
        binding: FriendListPageBinding()),
    GetPage(
        name: _Paths.FRIEND_APPLY_PAGE,
        page: () => const FriendApplyPageView()),
    GetPage(
      name: _Paths.GUEST,
      page: () => GuestView(),
      binding: GuestBinding(),
    ),
    GetPage(
      name: _Paths.CIRCLE_SEARCH,
      page: () => CircleSearchView(),
    ),
    GetPage(
      name: _Paths.CONFIG_GUILD_ASSISTANT_PAGE,
      page: () => ConfigGuildAssistantPageView(),
      binding: ConfigGuildAssistantPageBinding(),
    ),
    GetPage(
      name: _Paths.CONFIG_GUILD_SELECT_TEMPLATE_PAGE,
      page: () => CreateGuildSelectTemplatePageView(),
      binding: CreateGuildSelectTemplatePageBinding(),
    ),
    GetPage(
      name: _Paths.WELCOME_SETTING,
      page: () => WelcomeSettingView(),
      binding: WelcomeSettingBinding(),
    ),
    GetPage(
      name: _Paths.WELCOME_SETTING_SELECT_CHANNEL,
      page: () => WelcomeSettingSelectChannelView(),
      binding: WelcomeSettingSelectChannelBinding(),
    ),
    GetPage(
      name: _Paths.FILE_SELECT,
      page: () => const FileSelectPageView(),
      binding: FileSelectBinding(),
    ),
    GetPage(
      name: _Paths.CIRCLE_DETAIL,
      page: () => CircleDetailView(),
      binding: CircleDetailBinding(),
    ),
    GetPage(
      customTransition: CircleVideoPageTransition(),
      name: _Paths.CIRCLE_VIDEO_PAGE,
      page: () => const CircleVideoView(),
      binding: CircleVideoPageBinding(),
    ),
    GetPage(
      name: _Paths.CIRCLE,
      page: () => CircleView(),
    ),
    GetPage(
      name: _Paths.UI_GALLERY,
      page: () => UiGalleryView(),
    ),
    GetPage(
      name: _Paths.COMMON_SHARE_PAGE,
      page: () => const CommonSharePageView(),
    ),
    GetPage(
      name: _Paths.ACCEPT_INVITE,
      page: () => AcceptInviteView(),
      binding: AcceptInviteBinding(),
    ),
    GetPage(
      name: _Paths.BOT_MARKET_PAGE,
      page: () => BotMarketPageView(),
      binding: BotMarketPageBinding(),
    ),
    GetPage(
      name: _Paths.BOT_DETAIL_PAGE,
      page: () => BotDetailPageView(),
      binding: BotDetailPageBinding(),
    ),
    GetPage(
      name: _Paths.MUTE_LIST_PAGE,
      page: () => const MuteListPage(),
      binding: MuteListBinding(),
    ),
    GetPage(
      name: Routes.GUILD_CHANNEL_SETTINGS,
      page: () => ChannelManagePage(),
    ),
    GetPage(
      name: Routes.MULTI_CHANNEL_COMMAND_SHORTCUT_SETTINGS_PAGE,
      binding: MultiChannelCommandShortcutsSettingsPageBinding(),
      page: () => MultiChannelCommandShortcutsSettingsPageView(),
    ),
    GetPage(
      name: Routes.GUILD_ROLE_MANAGER,
      page: () => const RoleManagePage(),
    ),
    GetPage(
      name: Routes.BLACK_LIST_PAGE,
      binding: BlackListBinding(),
      page: () => BlackListPage(),
    ),
    GetPage(
      name: Routes.SEND_RED_PACK,
      binding: SendRedPackPageBinding(),
      page: () => SendRedPackPage(),
    ),
    GetPage(
      name: _Paths.BIND_PAYMENT,
      page: () => BindPaymentView(),
      binding: BindPaymentBinding(),
    ),
    GetPage(
      name: _Paths.SEND_CODE,
      page: () => SendCodeView(),
      binding: SendCodeBinding(),
    ),
    GetPage(
      name: Routes.PRIVATE_CHANNEL_ACCESS_PAGE,
      binding: PrivateChannelAccessPageBinding(),
      page: () => PrivateChannelAccessPageView(),
    ),
    GetPage(
      name: Routes.OPEN_RED_PACK,
      page: () => const OpenRedPackDetailPage(),
      binding: OpenRedPackDetailBinding(),
    ),
    GetPage(
      name: Routes.OPEN_RED_PACK_ANIMA,
      page: () => const OpenRedPackDetailPage(),
      binding: OpenRedPackDetailBinding(),
      customTransition: OpenRedPackTransition(),
    ),
    GetPage(
      name: _Paths.CHANNEL_COMMAND_SETTING_PAGE,
      page: () => ChannelCommandSettingPageView(),
      binding: ChannelCommandSettingPageBinding(),
    ),
    GetPage(
      name: Routes.SYSTEM_PERMISSION_SETTING_PAGE,
      page: () => const SystemPermissionSettingPage(),
      binding: SystemPermissionSettingBinding(),
    ),
    GetPage(
      name: Routes.UNITY_VIEW_PAGE,
      page: () => UnityViewPage(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: _Paths.TC_DOC_PAGE,
      page: () => TcDocPageView(),
      binding: TcDocPageBinding(),
      transition: Transition.downToUp,
      popGesture: false,
      fullscreenDialog: true,
    ),
    GetPage(
      name: _Paths.TC_DOC_ADD_GROUP_PAGE,
      page: () => TcDocAddGroupPageView(),
      binding: TcDocAddGroupPageBinding(),
    ),
    GetPage(
      name: _Paths.TC_DOC_GROUPS_PAGE,
      page: () => TcDocGroupsPageView(),
      binding: TcDocGroupsPageBinding(),
    ),

    GetPage(
      name: Routes.DOCUMENT_ONLINE,
      page: () => OnlineDocumentPage(),
      binding: OnlineDocumentBinding(),
    ),
    GetPage(
      name: Routes.DOCUMENT_SEARCH,
      page: () => DocumentSearchPage(),
      binding: DocumentSearchBinding(),
    ),
    GetPage(
      name: Routes.DOCUMENT_INFO,
      page: () => ViewDocumentInfoPage(),
      binding: ViewDocumentInfoBinding(),
    ),
    GetPage(
      name: Routes.DOCUMENT_SELECT,
      page: () => DocumentSelectPage(),
      binding: DocumentSelectBinding(),
      transition: Transition.downToUp,
      popGesture: false,
      fullscreenDialog: true,
    ),
    GetPage(
      name: Routes.WALLET_HOME_PAGE,
      page: () => WalletHomePage(),
      binding: WalletHomeBinding(),
    ),
    GetPage(
      name: Routes.WALLET_COLLECT_DETAIL_PAGE,
      page: () => WalletCollectDetailPage(),
      binding: WalletCollectDetailBinding(),
    ),
    GetPage(
      name: Routes.WALLET_VERIFIED_PAGE,
      page: () => const WalletVerifiedPage(),
      binding: WalletVerifiedBinding(),
    ),
    GetPage(
      name: _Paths.SCAN_QR_CODE,
      page: () => ScanQrCodeView(),
      binding: ScanQrCodeBinding(),
    ),
    GetPage(
      name: _Paths.DYNAMIC_VIEW_PREVIEW,
      page: () => DynamicViewPreviewView(),
      binding: DynamicViewPreviewBinding(),
    ),
  ];
}
