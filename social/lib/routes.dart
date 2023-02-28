import 'dart:async';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/api.dart';
import 'package:im/api/entity/circle_detail_list_bean.dart';
import 'package:im/api/entity/sticker_bean.dart';
import 'package:im/app/modules/accept_invite/controllers/accept_invite_param.dart';
import 'package:im/app/modules/channel_command_setting_page/views/channel_command_setting_page_view.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_detail/views/circle_delete_page.dart';
import 'package:im/app/modules/circle_video_page/controllers/circle_video_page_controller.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/sub/doc_list_controller.dart';
import 'package:im/app/modules/file/views/file_preview_page_view.dart';
import 'package:im/app/modules/group_message/views/group_chat_view.dart';
import 'package:im/app/modules/mute/views/mute_time_setting_page.dart';
import 'package:im/app/modules/redpack/send_pack/views/send_redpack_page.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/extension/uri_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/factory/app_factory.dart';
import 'package:im/global.dart';
import 'package:im/hybrid/webrtc/tools/rtc_log.dart';
import 'package:im/live_provider/pages/assistants/add_assistants_page.dart';
import 'package:im/live_provider/pages/room_list_page.dart';
import 'package:im/pages/bot_market/bot_market_page_view.dart';
import 'package:im/pages/channel/channel_creation_page/create_channel_select_role_user_page.dart';
import 'package:im/pages/channel/modify_channel_page.dart';
import 'package:im/pages/circle/content/circle_post_image_item.dart';
import 'package:im/pages/friend/common_friend_page.dart';
import 'package:im/pages/guild/common_guild_page.dart';
import 'package:im/pages/guild/insert_flow_page.dart';
import 'package:im/pages/guild/join_guild.dart';
import 'package:im/pages/guild/landscape_create_guild_page_pop.dart';
import 'package:im/pages/guild/share_guild_poster_page.dart';
import 'package:im/pages/guild_setting/channel/add_overwrite_page.dart';
import 'package:im/pages/guild_setting/channel/channel_permission_page.dart';
import 'package:im/pages/guild_setting/channel/overwrite_page.dart';
import 'package:im/pages/guild_setting/channel/update_channel_cate_page.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/menu_button/menu_button.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/reply_page/reply_page.dart';
import 'package:im/pages/guild_setting/circle/circle_news_page.dart';
import 'package:im/pages/guild_setting/circle/circle_setting/circle_management_page.dart';
import 'package:im/pages/guild_setting/circle/circle_setting/circle_view_style_page.dart';
import 'package:im/pages/guild_setting/circle/circle_setting/model/circle_management_model.dart';
import 'package:im/pages/guild_setting/circle/circle_setting/topic_name_editor_page.dart';
import 'package:im/pages/guild_setting/guild/guild_manage_page.dart';
import 'package:im/pages/guild_setting/guild/guild_modify_page.dart';
import 'package:im/pages/guild_setting/guild/guild_opt_data_page.dart';
import 'package:im/pages/guild_setting/guild/guild_setting_page.dart';
import 'package:im/pages/guild_setting/member/member_manage_page.dart';
import 'package:im/pages/guild_setting/member/member_manager_invite_page.dart';
import 'package:im/pages/guild_setting/member/member_setting_page.dart';
import 'package:im/pages/guild_setting/role/classify_permission_page.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/guild_setting/role/role_setting_page.dart';
import 'package:im/pages/home/home_page.dart';
import 'package:im/pages/home/json/file_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/pin_list_page.dart';
import 'package:im/pages/home/view/dock.dart';
import 'package:im/pages/home/view/text_chat/items/sticker_item.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/sub_page/at_page/at_list_page.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/sub_page/channel_list.dart';
import 'package:im/pages/ledou/detail_page.dart';
import 'package:im/pages/ledou/ledou_page.dart';
import 'package:im/pages/ledou/transaction_page.dart';
import 'package:im/pages/login/country_page/country_page.dart';
import 'package:im/pages/login/get_captcha.dart';
import 'package:im/pages/login/login_modify_info_page.dart';
import 'package:im/pages/login/login_page.dart';
import 'package:im/pages/login/login_threshold.dart';
import 'package:im/pages/login/model/country_model.dart';
import 'package:im/pages/pay/earning_list_page.dart';
import 'package:im/pages/personal/clean_cache_page.dart';
import 'package:im/pages/personal/modify_info_page.dart';
import 'package:im/pages/personal/notification_settings.dart';
import 'package:im/pages/personal/notify_set_page.dart';
import 'package:im/pages/personal/personal_page.dart';
import 'package:im/pages/personal/privacy_set_page.dart';
import 'package:im/pages/personal/shield_set_page.dart';
import 'package:im/pages/personal/suggest_feedback_page.dart';
import 'package:im/pages/search/search_message_page.dart';
import 'package:im/pages/splash/protocal_page.dart';
import 'package:im/pages/tool/html_page.dart';
import 'package:im/pages/tool/url_handler/app_store_link_handler.dart';
import 'package:im/pages/topic/topic_page.dart';
import 'package:im/pages/video_call/model/video_model.dart';
import 'package:im/pages/video_call/video_page.dart';
import 'package:im/utils/deeplink_processor.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/preparing_home_page.dart';
import 'package:im/utils/track_route.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/web/pages/channel/channel_setup_page.dart';
import 'package:im/web/pages/circle/circle_management_page_web.dart' as web;
import 'package:im/web/pages/circle/create_moment_dialog.dart';
import 'package:im/web/pages/main/main_model.dart';
import 'package:im/web/pages/personal/html_page/page.dart' as web;
import 'package:im/web/pages/personal/login_modify_info_dialog.dart';
import 'package:im/web/pages/personal/personal_page.dart' as web;
import 'package:im/web/utils/show_dialog.dart';
import 'package:im/web/utils/web_toast.dart';
import 'package:im/web/widgets/slider_sheet/show_slider_sheet.dart';
import 'package:im/widgets/custom/custom_page_route_b2t.dart';
import 'package:im/widgets/custom/custom_route.dart';
import 'package:im/widgets/dynamic_widget/dynamic_page.dart';
import 'package:im/widgets/horizontal_back_page_route/horizontal_back_page_route.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api/data_model/user_info.dart';
import 'app/modules/accept_invite/views/web_accept_invite_view.dart';
import 'app/modules/circle/controllers/circle_controller.dart';
import 'app/modules/circle/models/models.dart';
import 'app/modules/circle/views/circle_publish_page.dart';
import 'app/modules/circle_search/views/circle_search_view.dart';
import 'app/modules/direct_message/views/direct_chat_page.dart';
import 'app/modules/document_online/entity/doc_item.dart';
import 'app/modules/document_online/info/controllers/doc_link_preview_controller.dart';
import 'app/modules/document_online/search/controllers/document_search_controller.dart';
import 'app/modules/task/introduction_ceremony/open_task_introduction_ceremony.dart';
import 'app/routes/app_pages.dart' as get_pages show Routes;
import 'common/permission/permission.dart';
import 'pages/guild/guild_nickname_page.dart';
import 'pages/guild/landscape_join_guild_page.dart';
import 'pages/guild/welcome_page.dart';
import 'pages/guild_setting/circle/circle_detail_page/circle_page.dart';
import 'pages/guild_setting/circle/circle_detail_page/reply_page/reply_page.dart';
import 'pages/guild_setting/circle/circle_setting/circle_desc_editor_page.dart';
import 'pages/guild_setting/circle/circle_setting/circle_name_editor_page.dart';
import 'pages/guild_setting/circle/circle_setting/circle_setting_page.dart';
import 'pages/guild_setting/circle/circle_setting/topic_editor_page.dart';
import 'pages/guild_setting/circle/circle_setting/topic_management_page.dart';
import 'pages/guild_setting/guild/guild_emo_page.dart';
import 'pages/home/view/record_view/sound_play_manager.dart';
import 'pages/oauth/fanbook_oauth_page.dart';
import 'pages/personal/about_us_page.dart';
import 'web/pages/setting/guild_setup_page.dart';
import 'web/utils/confirm_dialog/confirm_dialog.dart';

const String audioRoomRoute = "audio_popup";
const String audioRoomPopRoute = "video_popup";
const String protocalRoute = "protocal";
const String loginRoute = "login";
const String consoleRoute = "console";
const String createChannelRoute = "createChannel";
const String roomListRoute = "roomListRoute";
const String videoRoomRoute = "videoRoom";
const String videoRoomTextRoute = "videoRoomText";
const String personalRoute = "personal";
const String modifyUserInfoRoute = "modifyUserInfo";
const String loginCaptchaRoute = "loginCaptcha";
const String privacySetRoute = "privacySet";
const String notificationSetRoute = "notificationSetRoute";
const String shieldSetRoute = "shieldSet";
const String suggestFeedbackRoute = "suggestFeedback";
const String aboutUsRoute = "aboutUs";
const String circlePageRoute = "circlePageRoute";
const String circleReplyPageRoute = "circleReplyPageRoute";
const String circleManagementPageRoute = "circleManagement";
const String circleSettingPageRoute = "circleSetting";
const String circleNameEditorPageRoute = "circleNameEditor";
const String circleDescEditorPageRoute = "circleDescEditor";
const String topicManagementPageRoute = "topicManagement";
const String topicEditorPageRoute = "topicEditor";
const String topicNameEditorPageRoute = "topicNameEditor";
const String notifySetRoute = "notifySet";
const String loginModifyUserInfoRoute = "loginModifyUserInfo";
const String acceptInviteRoute = "acceptInvite";
const String createGuildRoute = "createGuild";
const String joinGuildRoute = "joinGuild";
const String invalidInviteRoute = "invalidInvite";
const String videoPage = "videoPage";
const String commonGuildRoute = "commonGuild";
const String commonFriendRoute = "commonFriend";
const String topicRoute = "topic";
const String guildSettingRoute = "guildSetting";
const String roleSettingRoute = "roleSetting";
const String memberManageRoute = "memberManage";
const String memberManageInviteRoute = "memberManageInvite";
const String memberSettingRoute = "memberSetting";
const String channelSettingRoute = "channelSetting";
const String channelPermissionRoute = "channelPermission";
const String addOverwriteRoute = "addOverwrite";
const String guildManageRoute = "guildManage";
const String guildEmoManageRoute = "guildEmoManage";
const String stickerRoute = "stickerRouter";
const String guildOptDataRoute = "guildOptData";
const String createChannelCateRoute = "createChannelCate";
const String guildModifyRoute = "guildModify";
const String htmlRoute = "html";
const String countryRoute = "country";
const String pinListRoute = "pinList";
const String remarkModification = "remarkModification";
const String circleMainPageRoute = "circleMainPage";
const String circleNewsPageRoute = "circleNewsPage";
const String circleSearchView = "circleSearchView";
const String richEditorAtListRoute = "richEditorAtList";
const String richEditorChannelListRoute = "richEditorChannelList";
const String richTunInputPopRoute = "richTunInputPopRoute";
const String botMarketRoute = "botMarket";
const String botIntroductionRoute = "botIntroduction";
const String botFatherRoute = "botFather";
const String searchMessageRoute = "searchMessage";
const String insertFlowRoute = "insertFlow";
const String guildEditInfoRoute = "guildEditInfo";
const String guildEditNameRoute = "guildEditName";
const String taskCenterRoute = "taskCenter";
const String cleanCacheRoute = "cleanCacheRoute";
const String botSettingRoute = "botSettingRoute";
const String earningListRoute = "earningList";
const String ledouRoute = "ledou";
const String ledouDetailRoute = "ledouDetail";
const String liveH5Route = "liveH5";
const String liveCreateRoom = "liveCreateRoom"; // 此值与live外包模块代码保持一致
const String guildNicknameSettingRoute = "guildNicknameSetting";
const String shareGuildPosterRoute = "shareGuildPosterRoute";
const String shareCirclePosterRoute = "shareCirclePosterRoute";
const String welcomeRoute = "welcomePageRoute";
const String createChannelSelectRoute = "createChannelSelectRoute";
const String notificationManagerRoute = "notificationManagerRoute";
const String fanbookOAuthRoute = "fanbookOAuthRoute";
const String directChatViewRoute = "directChatViewRoute";
const String dynamicPageRoute = "dynamicPageRoute";
const String addAssistantsPageRoute = "addAssistantsPageRoute";
const String muteTimeSettingPageRoute = "muteTimeSettingPageRoute";
const String circleDeletePageRoute = "circleDeletePageRoute";

typedef CustomAnimRouteBuilder<T> = CustomPageAnimRouter<T> Function(
    Widget child);

class Routes {
  static String currentRoute;
  static String previousRoute;

  static Future<T> push<T>(
    BuildContext context,
    Widget page,
    String name, {
    bool replace = false,
    bool fullScreenDialog = false,
    bool fadeIn = false,
    bool fadeInThrough = false,
    bool horziontalBack = false,
    CustomAnimRouteBuilder<T> animRouteBuilder,
    bool isModal = false,
  }) {
    previousRoute = currentRoute;
    currentRoute = name;

    Route<T> route;
    if (animRouteBuilder != null) {
      route = animRouteBuilder(page);
    } else if (fadeIn) {
      route = CustomRoute(
        page,
        settings: RouteSettings(name: name),
      );
    } else if (fadeInThrough) {
      route = FadeThroughPageRouter(
        page,
        settings: RouteSettings(name: name),
      );
    } else if (horziontalBack) {
      route = HorizontalBackPageRoute(
          builder: (_) => page,
          settings: RouteSettings(name: name),
          fullscreenDialog: fullScreenDialog);
    } else if (isModal) {
      // route = FullScreenModalRoute(child: page);
      return Get.dialog(page, name: name, useSafeArea: false);
    } else {
      route = MaterialPageRoute(
          builder: (_) => page,
          settings: RouteSettings(name: name),
          fullscreenDialog: fullScreenDialog);
    }

    if (replace) {
      return Global.navigatorKey.currentState.pushReplacement(route);
    } else {
      return Global.navigatorKey.currentState.push<T>(route);
    }
  }

  ///　FIXME 当前方法只给homepage使用，其它页面调用请考虑一下。当时这里检测到验证码登录方式时，登录页没dispose
  static Future<T> pushRemoveUtil<T>(
    BuildContext context,
    Widget page,
    String name, {
    bool fadeIn = false,
    bool fadeInThrough = false,
  }) {
    previousRoute = currentRoute;
    currentRoute = name;

    Route<T> route;
    if (fadeIn) {
      route = CustomRoute(
        page,
        settings: RouteSettings(name: name),
      );
    } else if (fadeInThrough) {
      route = FadeThroughPageRouter(
        page,
        settings: RouteSettings(name: name),
      );
    } else {
      route = MaterialPageRoute(
          builder: (_) => page, settings: RouteSettings(name: name));
    }
    return Global.navigatorKey.currentState
        .pushAndRemoveUntil(route, (route) => route == null);
  }

  // ignore: type_annotate_public_apis
  static void pop<T>(BuildContext context, [T object]) {
    return Navigator.pop<T>(context, object);
  }

  static Future pushHomePage(BuildContext context,
      {String queryString = ''}) async {
    await preparingHomePage();

    /// 检查是否存在需要处理的deep link，如果存在则不启动home page，直接跳转到deep link对应的页面
    if (await DeepLinkProcessor.instance.process()) {
      return;
    }
    return push(
        context, HomePage(), '${app_pages.Routes.HOME}${queryString ?? ''}',
        replace: true,
        fadeInThrough: OrientationUtil.landscape && !kIsWeb,
        fadeIn: OrientationUtil.portrait || kIsWeb);
  }

  static Future popAndPushHomePage(BuildContext context,
      {String queryString = ''}) async {
    await preparingHomePage();

    /// 检查是否存在需要处理的deep link，如果存在则不启动home page，直接跳转到deep link对应的页面
    if (await DeepLinkProcessor.instance.process()) {
      return;
    }
    return pushRemoveUtil(
        context, HomePage(), '${app_pages.Routes.HOME}${queryString ?? ''}',
        fadeInThrough: OrientationUtil.landscape,
        fadeIn: OrientationUtil.portrait);
  }

  static Future pushProtocalPage(
    BuildContext context, {
    bool replace = false,
    bool fadeIn = true,
  }) {
    return push(
      context,
      ProtocalPage(),
      protocalRoute,
      replace: replace,
      fadeIn: fadeIn,
    );
  }

  static Future pushLoginPage(BuildContext context,
      {String mobile,
      CountryModel country,
      bool replace = false,
      bool fadeIn = true,
      bool binding = false,
      bool showCover = true,
      String thirdParty = "",
      LoginType loginType = LoginType.LoginTypePhoneNum,
      String queryString = ''}) {
    return push(
        context,
        LoginPage(
            mobile: mobile,
            country: country,
            binding: binding,
            showCover: showCover,
            loginType: loginType,
            thirdParty: thirdParty),
        '$loginRoute${queryString ?? ''}',
        replace: replace,
        fadeIn: fadeIn);
  }

  static Future popAndPushLoginPage(String mobile, CountryModel country) {
    return Global.navigatorKey.currentState.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (ctx) {
            return LoginPage(
              mobile: mobile,
              country: country,
            );
          },
          settings: const RouteSettings(name: loginRoute),
        ),
        (route) => false);
  }

  static Future pushChannelCreation(BuildContext context, String guildId,
      {String cateId}) {
    if (OrientationUtil.landscape)
      return showAnimationDialog(
          context: context,
          builder: (_) =>
              appFactory.createChannelCreation(guildId, cateId: cateId));
    return push(
        context,
        appFactory.createChannelCreation(guildId, cateId: cateId),
        createChannelRoute,
        fullScreenDialog: true);
  }

  static Future pushInsertFlowPage(BuildContext context, {String tipText}) {
    return push(
        context,
        InsertFlowPage(
          tipText: tipText,
        ),
        insertFlowRoute,
        fullScreenDialog: true);
  }

  static Future pushModifyChannelPage(
      BuildContext context, ChatChannel channel) {
    if (OrientationUtil.landscape)
      return showSliderModal(context, body: ModifyChannelPage(channel));
    return push(context, ModifyChannelPage(channel), createChannelRoute);
  }

  static Future pushVideoPage(
    BuildContext context,
    String userId, {
    bool isCaller = true,
    String roomId,
    bool isVideo = false,
    bool autoAnswer = false,
    VideoModel oldModel,
  }) {
    return push(
        context,
        VideoPage(
          userId,
          isCaller,
          roomId: roomId,
          isVideo: isVideo,
          autoAnswer: autoAnswer,
          oldModel: oldModel,
        ),
        videoPage);
  }

  static Future pushRtcLogPage(BuildContext context) {
    return push(context, RtcLog(), consoleRoute);
  }

  static Future pushPersonalPage(BuildContext context) {
    if (OrientationUtil.landscape)
      return push(context, web.PersonalPage(), personalRoute,
          animRouteBuilder: (child) => FadeThroughPageRouter(child));
    return push(context, PersonalPage(), personalRoute);
  }

  static Future pushModifyUserInfoPage(BuildContext context) {
    return push(context, ModifyUserInfoPage(), modifyUserInfoRoute);
  }

  static Future pushLoginCaptchaPage(
    BuildContext context, {
    @required int mobile,
    @required CountryModel country,
    bool fadeIn = false,
    String thirdParty = "",
    LoginType loginType = LoginType.LoginTypePhoneNum,
  }) {
    return push(
        context,
        LoginCaptchaPage(mobile, country, thirdParty, loginType),
        kIsWeb ? null : loginCaptchaRoute,
        fadeIn: fadeIn);
  }

  static Future pushNotifySetPage(BuildContext context) {
    return push(context, NotifySetPage(), notifySetRoute);
  }

  static Future pushPrivacySetPage(BuildContext context) {
    return push(context, PrivacySetPage(), privacySetRoute);
  }

  static Future pushNotificationSettingsPage(BuildContext context) {
    return push(context, NotificationSettings(), notificationSetRoute);
  }

  static Future pushShieldSetPage(BuildContext context) {
    if (OrientationUtil.landscape)
      return showSliderModal(context, body: ShieldSetPage());
    return push(context, ShieldSetPage(), shieldSetRoute);
  }

  static Future pushSuggestFeedbackPage(BuildContext context) {
    return push(context, SuggestFeedbackPage(), suggestFeedbackRoute);
  }

  static Future pushAboutUsPage(BuildContext context) {
    if (OrientationUtil.landscape)
      return showSliderModal(context, body: AboutUsPage());
    return push(context, AboutUsPage(), aboutUsRoute);
  }

  static Future pushCirclePage(
    BuildContext context, {
    ExtraData extraData,
    CirclePostDataModel model,
    Function(Map info) modifyCallBack,
    List<CirclePostDataModel> circlePostDataModels,
    String circleListTopicId = '_all',
    bool toComment,
    Function(Object data) onBack,
  }) async {
    ///todo 横屏后面根据产品需求适配
    if (OrientationUtil.landscape)
      return showSliderModal(
        context,
        body: CirclePage(
          circlePostDataModel: model,
          extraData: extraData,
          // circleOwnerId: circleOwnerId,
          modifyCallBack: modifyCallBack,
        ),
      );

    ///是否需要参加入门仪式
    if (OpenTaskIntroductionCeremony.openTaskInterface()) return Future.value();

    return Get.toNamed(app_pages.Routes.CIRCLE_DETAIL,
        arguments: CircleDetailData(
          model,
          extraData: extraData,
          circlePostDataModels: circlePostDataModels,
          circleListTopicId: circleListTopicId,
          modifyCallBack: modifyCallBack,
          toComment: toComment,
          onBack: onBack,
        ));
  }

  static Future pushCircleReplyPage(
      BuildContext context, ReplyDetailBean replyDetailBean) {
    if (OrientationUtil.landscape)
      return showSliderModal(context,
          body: ReplyPage(replyDetailBean: replyDetailBean));
    return push(context, ReplyPage(replyDetailBean: replyDetailBean),
        circleReplyPageRoute);
  }

  static Future pushCircleDescEditorPage(
    BuildContext context,
    CircleInfoModel state,
  ) {
    return push(
        context, CircleDescEditorPage(state), circleDescEditorPageRoute);
  }

  static Future pushTopicManagementPage(
    BuildContext context,
    TopicsModel topicsState,
  ) {
    return push(
      context,
      TopicManagementPage(topicsState),
      topicManagementPageRoute,
    );
  }

  static Future pushTopicEditorPage(
    BuildContext context,
    TopicsModel topicsState,
  ) {
    return push(context, TopicEditorPage(topicsState), topicEditorPageRoute);
  }

  static Future pushTopicNameEditorPage(BuildContext context, TopicsModel model,
      {int topicIndex = 0, bool isCreateTopic = false}) {
    return push(
        context,
        TopicNameEditorPage(
            topicIndex: topicIndex,
            topicsModel: model,
            isCreateTopic: isCreateTopic),
        topicNameEditorPageRoute);
  }

  static Future pushCircleManagementPage(
    BuildContext context,
    CircleInfoDataModel circleModel,
  ) {
    if (OrientationUtil.landscape)
      return push(context, web.CircleManagementPage(circleModel),
          circleManagementPageRoute,
          animRouteBuilder: (child) => FadeThroughPageRouter(child));
    return push(
      context,
      CircleManagementPage(circleModel),
      circleManagementPageRoute,
    );
  }

  static Future pushCircleSettingPage(
      BuildContext context, CircleInfoModel circleInfoState) {
    return push(
        context, CircleSettingPage(circleInfoState), circleSettingPageRoute);
  }

  static Future pushCircleNameEditorPage(
    BuildContext context,
    CircleInfoModel state,
  ) {
    return push(
      context,
      CircleNameEditorPage(state),
      circleNameEditorPageRoute,
    );
  }

  static Future pushLoginModifyUserInfoPage(BuildContext context,
      {bool isFirstIn = false}) {
    if (OrientationUtil.landscape)
      return showLoginModifyUserInfoDialog(context);
    return push(
        context,
        LoginModifyUserInfoPage(
          isFirstIn: isFirstIn,
        ),
        loginModifyUserInfoRoute);
  }

  static Future pushAcceptInvitePage(
    String guildId,
    String inviterId,
    String inviteCode, {
    String channelId,
    String postId,
    bool isExpire = false,
    InvitePageFrom invitePageFrom = InvitePageFrom.defaultPage,
  }) {
    if (OrientationUtil.portrait)
      return Get.toNamed(
        app_pages.Routes.ACCEPT_INVITE,
        arguments: AcceptInviteParam(
          guildId: guildId,
          inviterId: inviterId,
          inviteCode: inviteCode,
          channelId: channelId,
          postId: postId,
          isExpire: isExpire,
        ),
      );
    else {
      return showAnimationDialog(
        context: Global.navigatorKey.currentContext,
        routeSettings: RouteSettings(
          arguments: AcceptInviteParam(
            guildId: guildId,
            inviterId: inviterId,
            inviteCode: inviteCode,
            channelId: channelId,
            postId: postId,
            isExpire: isExpire,
          ),
        ),
        builder: (_) => WebAcceptInviteView(),
        barrierColor: Colors.black54,
      );
    }
  }

  ///打开服务器文件页面
  static void pushGuildDocument(String guildId) {
    Get.toNamed(get_pages.Routes.DOCUMENT_ONLINE, arguments: guildId)
        .then((value) {
      final List<String> list = EntryTypeExtension.allEntryTypeName();
      list.forEach((tag) {
        if (Get.isRegistered<DocListController>(tag: tag)) {
          Get.delete<DocListController>(tag: tag);
        }
      });
      return null;
    });
  }

  ///打开全新的服务器搜索新页面
  static void pushSearchDocumentPage(String guildId, int initialIndex) {
    Get.toNamed(
      get_pages.Routes.DOCUMENT_SEARCH,
      arguments: SearchParams(guildId, initialIndex),
    );
  }

  ///打开选择我的文件页面
  static Future<DocItem> pushSelectDocument(String guildId) async {
    final res =
        await Get.toNamed(get_pages.Routes.DOCUMENT_SELECT, arguments: guildId);
    if (res is DocItem) {
      return res;
    }
    return null;
  }

  static Future pushCircleMainPage(
      BuildContext context, String guildId, String channelId,
      {bool autoPushCircleMessage = false, String topicId}) async {
    if (OrientationUtil.landscape) {
      GlobalState.selectedChannel.value = null;
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      ChatTargetsModel.instance.selectedChatTarget.notifyListeners();
      MainRouteModel.instance.pushCirclePage(
        guildId,
        channelId,
        autoPushCircleMessage: autoPushCircleMessage,
      );
      return Future.value();
    }

    /// 如果内存还有CircleController，那就代表在改服务器圈子里面点击详情，这时候直接返回改变index即可
    if (Get.isRegistered<CircleController>()) {
      Get.until((route) =>
          route.settings.name == app_pages.Routes.CIRCLE ||
          route.settings.name == app_pages.Routes.HOME);
      CircleController.to.updateTabIndex(topicId);
      return;
    }

    return Get.toNamed(app_pages.Routes.CIRCLE,
        arguments: CircleControllerParam(guildId, channelId,
            topicId: topicId, autoPushCircleMessage: autoPushCircleMessage));
  }

  /// * 打开圈子沉浸式视频
  static Future pushCircleVideo(
      BuildContext context, CircleVideoPageControllerParam paramData) async {
    const routeName = app_pages.Routes.CIRCLE_VIDEO_PAGE;
    Route route = PageRouterObserver.instance.getRouteByName(routeName);
    if (route != null) {
      ///沉浸式已打开,需要先关闭它
      // debugPrint('getChat pushCircleVideo route: $route');
      Global.navigatorKey.currentState.removeRoute(route);
      route = PageRouterObserver.instance.getRouteByName('video_comment');
      await Get.delete<CircleVideoPageController>();

      ///同时关闭打开的回复列表弹窗
      if (route != null) Global.navigatorKey.currentState.removeRoute(route);
      await Future.delayed(200.milliseconds);
    }

    return Get.toNamed(
      routeName,
      arguments: paramData,
    );
  }

  static Future pushCircleNewsPage(BuildContext context, String circleId) {
    if (OrientationUtil.landscape)
      return showSliderModal(context, body: CircleNewsPage(circleId));
    return push(context, CircleNewsPage(circleId), circleNewsPageRoute);
  }

  static Future pushCircleSearchPage(
      BuildContext context, String guildId, String channelId) {
    if (OrientationUtil.landscape)
      return showSliderModal(context,
          body: CircleSearchView(guildId: guildId, channelId: channelId));

    return Get.to(
      () => CircleSearchView(guildId: guildId, channelId: channelId),
    );
  }

  static Future pushCreateGuildPage(BuildContext context,
      {String batchGuidType = ''}) {
    return Get.dialog(CreateGuildPagePop(batchGuidType: batchGuidType));
  }

  static Future pushJoinGuildPage(BuildContext context) {
    if (OrientationUtil.landscape)
      return showSliderModal(context, body: LandscapeJoinGuildPage());
    return push(context, JoinGuildPage(), joinGuildRoute,
        fullScreenDialog: true);
  }

  static Future pushCommonGuildPage(BuildContext context, String relationId) {
    return push(context, CommonGuildPage(relationId), commonGuildRoute);
  }

  static Future pushCommonFriendPage(BuildContext context, String relationId,
      {bool hideGuildName = false, String guildId}) {
    return push(
        context,
        CommonFriendPage(
          relationId,
          hideGuildName: hideGuildName,
          guildId: guildId,
        ),
        commonFriendRoute);
  }

  static Future pushTopicPage(BuildContext context, MessageEntity message,
      {String gotoMessageId, bool isTopicShare = false}) {
    if (message == null)
      return Future.error(
          Exception("Can't open topic page with null thread starter."));
    //final tcController = TextChannelController.to(channelId: message.channelId);
    if (OrientationUtil.landscape) {
      return showSliderModal(
        context,
        body: TopicPage(message: message, gotoMessageId: gotoMessageId),
      );
    }

    // return Get.toNamed(app_pages.Routes.TOPIC_PAGE,
    //         arguments: TopicParam(message, gotoMessageId, isTopicShare))
    //     .then((param) {
    //   if (param is TopicBackParam) {
    //     final c = TextChannelController.to(channelId: param.channelId);
    //     c.animationToMessageId(param.guildId, param.channelId, param.messageId);
    //   }
    // });

    final topicPage = TopicPage(
        message: message,
        gotoMessageId: gotoMessageId,
        isTopicShare: isTopicShare);

    return push(context, topicPage, app_pages.Routes.TOPIC_PAGE,
            horziontalBack: true)
        .then((param) {
      currentRoute = previousRoute;
      if (param is TopicBackParam) {
        final c = TextChannelController.to(channelId: param.channelId);
        c.animationToMessageId(param.guildId, param.channelId, param.messageId);
      }
    });
  }

  /// - 跳转到文件预览
  static Future pushFilePreviewPage(BuildContext context, FileEntity entity) {
    return push(
        context, FilePreviewPageView(entity), app_pages.Routes.FILE_PREVIEW);
  }

  static Future pushGuildSettingPage(BuildContext context, String guildId) {
    if (OrientationUtil.landscape)
      return push(context, GuildSetupPage(guildId), guildSettingRoute,
          animRouteBuilder: (child) => FadeThroughPageRouter(child));
    return push(context, GuildSettingPage(guildId), guildSettingRoute);
  }

  static Future pushRoleSettingPage(BuildContext context, String guildId,
      {Role role, bool isCreateRole = false}) {
    return push(
        context,
        RoleSettingPage(guildId, role?.id ?? '', isCreateRole: isCreateRole),
        roleSettingRoute);
  }

  static Future pushClassifyPermissionPage(
      BuildContext context, String guildId, Role role) {
    return push(
        context,
        ClassifyPermissionPage(
          guildId: guildId,
          role: role,
        ),
        roleSettingRoute);
  }

  static Future pushMemberManagePage(BuildContext context, String guildId) {
    return push(context, MemberManagePage(guildId), memberManageRoute);
  }

  static Future pushBlackListPage(BuildContext context, String guildId) {
    return Get.toNamed(get_pages.Routes.BLACK_LIST_PAGE, arguments: guildId);
  }

  ///isSingleRedPack 是否为私信红包
  static Future pushSendRedPackPage(RedPackParams redPackParams) {
    return Get.toNamed(get_pages.Routes.SEND_RED_PACK,
        arguments: redPackParams);
  }

  static Future pushMemberSettingPage(
      BuildContext context, String guildId, UserInfo member) {
    return push(
        context,
        MemberSettingPage(
          guildId: guildId,
          member: member,
        ),
        memberSettingRoute);
  }

  static Future pushMemberManageInvitePage(
      BuildContext context, String guildId) {
    return push(
        context,
        MemberManagerInvitePage(
          guildId: guildId,
        ),
        memberManageInviteRoute);
  }

  static Future pushCircleViewStylePage(
    BuildContext context,
    TopicsModel topicsModel,
    int topicIndex,
  ) {
    if (OrientationUtil.landscape)
      return showSliderModal(context,
          body: CircleViewStylePage(topicsModel, topicIndex));
    return push(context, CircleViewStylePage(topicsModel, topicIndex),
        channelPermissionRoute);
  }

  static Future pushChannelPermissionPage(
      BuildContext context, ChatChannel channel) {
    if (OrientationUtil.landscape)
      return showSliderModal(context, body: ChannelPermissionPage(channel));
    return push(
        context, ChannelPermissionPage(channel), channelPermissionRoute);
  }

  static Future pushOverwritePage(
      BuildContext context, PermissionOverwrite overwrite, ChatChannel channel,
      {bool replace = false}) {
    return push(
        context,
        OverwritePage(
          overwriteId: overwrite.id,
          channel: channel,
        ),
        channelSettingRoute,
        replace: replace);
  }

  static Future pushAddOverwritePage(BuildContext context, ChatChannel channel,
      int type, List<String> filterIds) {
    return push(
        context,
        AddOverwritePage(channel: channel, type: type, filterIds: filterIds),
        addOverwriteRoute);
  }

  static Future pushGuildManagePage(BuildContext context) {
    return push(context, GuildManagePage(), guildManageRoute);
  }

  static Future pushGuildEmoManagePage(BuildContext context, String guildId) {
    return push(context, GuildEmoPage(guildId), guildEmoManageRoute);
  }

  static Future pushStickPage(BuildContext context, StickerBean bean) {
    if (OrientationUtil.landscape)
      return showWebConfirmDialog(
        context,
        title: '',
        width: 400,
        height: 300,
        showCloseIcon: true,
        hideFooter: true,
        body: StickerPage(
          bean: bean,
        ),
      );
    return push(
        context,
        StickerPage(
          bean: bean,
        ),
        stickerRoute);
  }

  static Future pushGuildOptDataPage(BuildContext context, String guildId) {
    return push(context, GuildOptDataPage(guildId), guildOptDataRoute);
  }

  static Future pushUpdateChannelCatePage(BuildContext context, String guildId,
      {ChatChannel channelCate}) {
    return push(
        context,
        UpdateChannelCatePage(
          guildId,
          channelCate: channelCate,
        ),
        createChannelCateRoute);
  }

  static Future pushGuildModifyPage(BuildContext context, String guildId) {
    return push(context, GuildModifyPage(guildId), guildModifyRoute);
  }

  static Future pushHtmlPage(
    BuildContext context,
    String url, {
    String title,
    bool appendTokenToUrl = false,
    bool isReplace = false,
  }) async {
    if (!(url.startsWith('http://') || url.startsWith('https://')))
      url = 'http://$url';

    /// TODO  只要外部入口使用预设，这里就没必要加 App Store 逻辑
    final interceptor = AppStoreLinkHandler();
    if (UniversalPlatform.isIOS && interceptor.match(url))
      return interceptor.handle(url);

    if (kIsWeb) {
      return launch(url, forceWebView: true, webOnlyWindowName: "test")
          .catchError((e) {
        showWebToast('无效的链接地址');
      });
    }

    return push(
      context,
      HtmlPage(
        initialUrl: url,
        title: title,
        isNormalURL: !appendTokenToUrl,
      ),
      htmlRoute,
      replace: isReplace,
    );
  }

  static Future pushHtmlPageWithUri(
    BuildContext context,
    Uri uri, {
    String title,
    bool appendTokenToUrl = false,
    bool isReplace = false,
  }) {
    if (kIsWeb) {
      return launch(uri.toString(),
          forceWebView: true, webOnlyWindowName: "test");
    }

    return push(
      context,
      HtmlPage(
        initialUri: uri,
        title: title,
        isNormalURL: !appendTokenToUrl,
      ),
      htmlRoute,
      replace: isReplace,
    );
  }

  static Future pushToTipOffPage(
    BuildContext context, {
    String guildId = '',
    @required String accusedUserId,
    @required String accusedName,
    int complaintType = 2,
  }) {
    final _accusedNickName =
        accusedName; //Uri.encodeQueryComponent(accusedName);
    final userName =
        Global.user.username; //Uri.encodeQueryComponent(Global.user.username);
    final nickName =
        Global.user.nickname; //Uri.encodeQueryComponent(Global.user.nickname);

    final Map<String, String> params = {
      "complaint_type": complaintType.toString(),
      "accused_id": accusedUserId,
      "accused_name": _accusedNickName,
      "user_name": userName,
      "user_id": Global.user.id,
      "nickname": nickName,
      "udx": "93${DateTime.now().millisecondsSinceEpoch}3c"
    };

    if (guildId.hasValue) {
      params["guild_id"] = guildId;
      final guild = ChatTargetsModel.instance.chatTargets
          .firstWhere((e) => e.id == guildId, orElse: () => null);
      if (guild != null) {
        params["guid_name"] = guild.name ?? ' ';
      }
    }

    final uri =
        Uri.parse('${Config.useHttps ? "https" : "http"}://${ApiUrl.reportUrl}')
            .addParams(params);

    // final String url =
    //     Uri.parse('https://${ApiUrl.reportUrl}').addParams(params).toString();
    //   url =
    //       'https://${ApiUrl.reportUrl}?complaint_type=$complaintType&accused_id=$accusedUserId&accused_name=$_accusedNickName&user_name=$userName&user_id=${Global.user.id}&nickname=$nickName&udx=93${DateTime.now().millisecondsSinceEpoch}3c';

    if (OrientationUtil.landscape)
      return web.showToTipOffPage(context,
          accusedUserId: accusedUserId, accusedName: accusedName);
    return pushHtmlPageWithUri(context, uri,
        title: "举报".tr, appendTokenToUrl: true);
  }

  static Future pushCountryPage(BuildContext context) {
    return push(context, const CountryPage(), countryRoute);
  }

  static Future<List> pushRichEditorAtListPage(BuildContext context,
      {@required String guildId, ChatChannel channel}) {
    final Completer<List> completer = Completer();
    push(
        context,
        AtListPage(
          guildId: guildId,
          channel: channel,
          onSelect: (list) {
            Get.back();
            completer.complete(list);
          },
          onClose: () {
            Get.back();
            completer.complete([]);
          },
        ),
        richEditorAtListRoute,
        fullScreenDialog: true);
    return completer.future;
  }

  static Future pushRichEditorChannelListPage(BuildContext context) {
    final Completer<ChatChannel> completer = Completer();
    push(context, RichEditorChannelListPage(
      onSelect: (channel) {
        Get.back();
        completer.complete(channel);
      },
    ), richEditorAtListRoute, fullScreenDialog: true);
    return completer.future;
  }

  static Future<CirclePostInfoDataModel> pushCreateMomentPage(
    BuildContext context,
    String guildId,
    String channelId, {
    List<CircleTopicDataModel> topics,
    CircleTopicDataModel defaultTopic,
    CirclePostInfoDataModel circleDraft,
    List<CirclePostImageItem> assetList,
  }) async {
    if (OrientationUtil.landscape) {
      return showDialog(
        context: context,
        builder: (context) => CreateMomentDialog(
          guildId,
          channelId,
          defaultTopic: defaultTopic,
          optionTopics: topics,
        ),
      );
    }

    return push<CirclePostInfoDataModel>(
      context,
      CirclePublishPage(
        guildId,
        channelId,
        optionTopics: topics,
        defaultTopic: defaultTopic,
        circleDraft: circleDraft,
        assetList: assetList,
      ),
      richEditorAtListRoute,
      fullScreenDialog: true,
    );
  }

  static Future pushPinListPage(BuildContext context, {ChatChannel channel}) {
    if (OrientationUtil.landscape) {
      showSliderModal(context,
          body: PinListPage(
            channel: channel,
          ));
      return Future.value(false);
    }
    return push(
        context,
        PinListPage(
          channel: channel,
        ),
        pinListRoute);
  }

  // static Future pushExternalSharePage(BuildContext context, ExternalShareModel model, {bool replace = false}) {
  //   return push(context, ExternalSharePage(model),"externalSharePage",replace: replace);
  // }
  //
  // static Future pushExternalShareChannelListPage(BuildContext context,ExternalShareModel model, GuildTarget guild) {
  //   return push(context, ExternalShareChannelListPage(model, guild),"externalShareChannelListPage");
  // }

  static void backHome() {
    /// TODO: 2021/12/20 应该由Home页面负责处理，并不应该交由路由控制器处理
    // 在以下路由的时候不能后退到home，否则可能导致黑屏
    final cannotBack = [loginRoute, loginCaptchaRoute, loginModifyUserInfoRoute]
        .contains(currentRoute);
    if (!Global.navigatorKey.currentState.canPop() || cannotBack) return;

    Global.navigatorKey.currentState.popUntil((route) {
      if (kIsWeb) {
        return route.settings.name?.split('?')?.first == app_pages.Routes.HOME;
      }

      /// 此处暂时先兼容,防止黑屏出现
      return route.settings.name == app_pages.Routes.HOME;
    });
  }

  static void pushRobotMarket() {
    push(Global.navigatorKey.currentContext, BotMarketPageView(),
        botMarketRoute);
  }

  static void pushChannelCommandShortcutsSettings(ChatChannel channel) {
    if (OrientationUtil.landscape) {
      showSliderModal(
        Global.navigatorKey.currentContext,
        body: ChannelCommandSettingPageView(),
      );
      return;
    }

    Get.toNamed(get_pages.Routes.CHANNEL_COMMAND_SETTING_PAGE,
        arguments: channel);
  }

  static Future pushSearchMessagePage(BuildContext context, String guildId,
      {String channelId}) {
    if (OrientationUtil.landscape) {
      showSliderModal(context,
          body: SearchMessagePage(guildId, channelId: channelId));
      return Future.value();
    }

    return Get.to(SearchMessagePage(guildId, channelId: channelId),
        fullscreenDialog: true);
  }

  static Future pushMiniProgram(String appId) {
    return Get.toNamed(get_pages.Routes.MINI_PROGRAM_PAGE,
        parameters: {'appId': appId});
  }

  static Future pushAddAssistantsPage(
      String guildId, List<FBUserInfo> defaultSelectedUsers) {
    return push(
      Global.navigatorKey.currentContext,
      AddAssistantsPage(
        guildId: ChatTargetsModel.instance.selectedChatTarget.id,
        defaultSelectedUsers: defaultSelectedUsers,
      ),
      addAssistantsPageRoute,
    );
  }

  static Future pushCleanCachePage(BuildContext context) {
    return push(context, CleanCachePage(), cleanCacheRoute);
  }

  static void pushEarningListPage() {
    push(Global.navigatorKey.currentContext, EarningListPage(),
        earningListRoute);
  }

  static void pushLedouPage() {
    push(Global.navigatorKey.currentContext, LeDouPage(), ledouRoute);
  }

  static void pushLedouTransactionPage() {
    push(
      Global.navigatorKey.currentContext,
      LedouTransactionPage(),
      ledouDetailRoute,
    );
  }

  static void pushLedouDetailPage(TransactionDetailViewModel viewModel) {
    push(
      Global.navigatorKey.currentContext,
      TransactionDetailPage(viewModel),
      ledouDetailRoute,
    );
  }

  static void pushToH5LivePage(String url) {
    final params = {"inFanbook": "true"};
    url = Uri.parse(url).addParams(params).toString();
    push(
      Global.navigatorKey.currentContext,
      HtmlPage(
        initialUrl: url,
      ),
      liveH5Route,
    );
  }

  static void pushChannelSetupPage(ChatChannel channel) {
    push(Global.navigatorKey.currentContext, ChannelSetupPage(channel),
        botFatherRoute,
        animRouteBuilder: (child) => FadeThroughPageRouter(child));
  }

  static Future pushGuildNicknamePage(BuildContext context, String guildId) {
    return push(
        context,
        GuildNicknameSettingPage(
          guildId: guildId,
        ),
        guildNicknameSettingRoute);
  }

  static Future pushShareGuildPosterPage(GuildTarget guild, String shareLink,
      {VoidCallback onCopy}) {
    return push(
      Global.navigatorKey.currentContext,
      ShareGuildPosterPage(guild: guild, shareLink: shareLink, onCopy: onCopy),
      shareGuildPosterRoute,
      isModal: true,
    );
  }

  static Future pushWelcomePage() {
    return push(
        Global.navigatorKey.currentContext, WelcomePage(), welcomeRoute);
  }

  static Future pushChannelRoleOrUserSelectPage(String guildId, String cateId) {
    return push(Global.navigatorKey.currentContext,
        CreateChannelRoleOrUserSelectPage(guildId, cateId), createChannelRoute);
  }

  static Future pushNotificationManagerPage() {
    return push(Global.navigatorKey.currentContext,
        appFactory.createNotificationManager(), notificationManagerRoute);
  }

  static Future pushFanbookAuthPage({
    @required String clientId,
    String state,
  }) {
    return push(
        Global.navigatorKey.currentContext,
        FanbookOAuthPage(
          clientId: clientId,
          state: state,
        ),
        fanbookOAuthRoute,
        fullScreenDialog: true);
  }

  static Future pushDirectChatPage(ChatChannel channel) {
    // 私信同一个好友时无需做跳转
    // 情况1：当前打开私信页面再次私信无需做任何处理
    // 情况2：进入直播频道（此时路由名是home),进入回放或直播时多次点击私信只需要Pop掉上面的页面
    if (TextChannelController.dmChannel?.id == channel.id) {
      if (Get.currentRoute != directChatViewRoute) {
        Global.navigatorKey.currentState.popUntil((route) =>
            route.settings.name == directChatViewRoute ||
            route.settings.name == app_pages.Routes.HOME);
      }
      return Future.value();
    }
    // 从文字频道进入直播功能时，路由名是roomListRoute(和直播频道不一样,直播频道处于home页面）
    // 这种路由环境下点击私信不应该backHome
    if (Get.currentRoute != roomListRoute) {
      backHome();
    }

    final page = channel.type == ChatChannelType.group_dm
        ? GroupChatView(channel)
        : DirectChatPage(channel: channel);

    TextChannelController.dmChannel = channel;
    return push(Global.navigatorKey.currentContext, page, directChatViewRoute,
            horziontalBack: true)
        .then((value) {
      if (TextChannelController.dmChannel == channel) {
        TextChannelController.dmChannel = null;
        if (Get.isRegistered<TextChannelController>(tag: channel.id)) {
          Get.delete<TextChannelController>(tag: channel.id);
        }
      }
      SoundPlayManager().forceStop(); // 同时停止播放语音
      Dock.updateDock();

      ///清除所有tag
      DocLinkPreviewController.removeAll();
    });
  }

  static Future pushDynamicPage({
    Map<String, dynamic> json,
    MessageEntity message,
    String title,
  }) {
    return push(Global.navigatorKey.currentContext,
        DynamicPage(json: json, message: message), dynamicPageRoute);
  }

  /// 频道内直播入口
  static Future pushChannelLivePage(BuildContext context) {
    return push(context, const RoomListPage(), roomListRoute);
  }

  /// - 禁言时长设置入口
  static Future pushMuteTimeSettingPage(
    BuildContext context,
    String guildId,
    String userId,
  ) {
    return push(
        context,
        MuteTimeSettingPage(
          guildId: guildId,
          userId: userId,
        ),
        muteTimeSettingPageRoute);
  }

  static void gotoHome() {
    if (hasHomePage) {
      /// 加载过主页，直接回退到主页
      Routes.backHome();
    } else {
      /// 未加载过主页，清空回退栈后加载主页
      Routes.popAndPushHomePage(Global.navigatorKey.currentContext);
    }
  }

  /// 是否加载过主页面
  static bool get hasHomePage =>
      PageRouterObserver.instance.hasPage(app_pages.Routes.HOME);

  /// - 删除动态
  static Future pushCircleDeletePage(
    BuildContext context,
    String channelId,
    String topicId,
    String postId, {
    Function(MenuButtonType type, {List param}) onSuccess,
    Function(int code, MenuButtonType type) onError,
  }) {
    return push(
        context,
        CircleDeletePage(
            param: CircleDeleteParam(
          channelId: channelId,
          topicId: topicId,
          postId: postId,
          onSuccess: onSuccess,
          onError: onError,
        )),
        circleDeletePageRoute);
  }
}
