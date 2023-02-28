import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_manager/flutter_audio_manager.dart';
import 'package:get/get.dart';
import 'package:im/app/controllers/audio_room_controller.dart';
import 'package:im/app/modules/direct_message/views/direct_message_view.dart';
import 'package:im/app/modules/guide/components/task_status_panel.dart';
import 'package:im/app/modules/home/views/components/chat_index/guild_banner/guild_banner.dart';
import 'package:im/app/modules/task/introduction_ceremony/views/task_introduction_tips.dart';
import 'package:im/app/modules/task/task_util.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/global.dart';
import 'package:im/quest/fb_quest_config.dart';
import 'package:im/hybrid/webrtc/room/audio_room.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/chat_index/components/guild_channel_list/landscape_guild_channel_list.dart';
import 'package:im/pages/guild_setting/circle/entry/cross_platform_circle_entry_view.dart';
import 'package:im/pages/home/home_page.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/audio/audio_chat_popup.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/themes/web_light_theme.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/only.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/share_link_popup/share_link_popup.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:quest_system/quest_system.dart';
import 'package:tuple/tuple.dart';

class LandscapeGuildDetailView extends StatelessWidget {
  const LandscapeGuildDetailView({
    Key key,
    @required this.target,
  }) : super(key: key);

  final BaseChatTarget target;

  Widget _buildAudioWidget() {
    return ChangeNotifierProvider.value(
      value: GlobalState.mediaChannel,
      child: Consumer<ValueNotifier<Tuple2<BaseChatTarget, ChatChannel>>>(
        builder: (context, v, child) {
          final roomId = GlobalState.mediaChannel.value?.item2?.id;
          if (roomId == null) return const SizedBox();
          return FadeBackgroundButton(
            onTap: () => HomePage.showAudioRoom(
                roomId), //HomePage.showAudioRoom(context, roomId),
            tapDownBackgroundColor: Theme.of(context).highlightColor,
            backgroundColor: Theme.of(context).backgroundColor,
            child: GetBuilder<AudioRoomController>(
              tag: roomId,
              id: AudioRoomController.audioBarObject,
              builder: (c) {
                if (c.joined.value == JoinStatus.unJoined)
                  return const SizedBox();
                final AudioUser item = c.users[0];
                return Container(
                  height: 90,
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: const Color(0xFF8F959E).withOpacity(0.2))),
                  ),
                  padding: const EdgeInsets.only(
                      left: 8, right: 8, top: 10, bottom: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        children: [
                          Stack(
                            children: <Widget>[
                              RealtimeAvatar(userId: item.userId, size: 32),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Only(
                                  showIndex: item.talking ? 1 : 0,
                                  children: <Widget>[
                                    const SizedBox(),
                                    // 说话状态
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF43B581),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        IconFont.buffNaviMic,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          sizeWidth8,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.roomName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      height: 1,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2125)),
                                ),
                                sizeHeight4,
                                Text(c.guildName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        height: 1,
                                        color: Color(0xFF6D6F73))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      sizeHeight12,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          InkWell(
                            onTap: () {
                              c.toggleAudioOutput();
                            },
                            child: ObxValue<Rx<AudioInput>>((v) {
                              return Icon(
                                AudioChatPopup.getAudioIconData(v.value.port),
                                size: 20,
                              );
                            }, c.audioOutput),
                          ),
                          InkWell(
                            onTap: () {
                              c.stream.add(ButtonType.toggleMicro);
                            },
                            // 静音状态
                            child: ObxValue((isMuted) {
                              return Icon(
                                isMuted.value
                                    ? IconFont.buffMicrophoneOff
                                    : IconFont.buffMicrophoneOn,
                                color: isMuted.value
                                    ? DefaultTheme.dangerColor
                                    : const Color(0xFF646A73),
                                size: 20,
                              );
                            }, c.muted),
                          ),
                          InkWell(
                            onTap: () {
                              c.closeAndDispose(msg: "语音聊天已结束");
                            },
                            child: const Icon(
                              IconFont.buffAudioRoomQuit,
                              size: 20,
                              color: DefaultTheme.dangerColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GuildBanner(
          target: target,
        ),
        Expanded(
            child: ChangeNotifierProvider.value(
                value: target,
                child: ObxValue<RxBool>((rxIsShow) {
                  return Column(
                    children: [
                      QuestBuilder<QuestGroup>.id(
                          QuestId([QIDSegGroup.quickStart, "-", target.id]),
                          builder: (quest) {
                        if (quest == null ||
                            quest.status == QuestStatus.completed)
                          return ValidPermission(
                            permissions: [
                              Permission.CREATE_INSTANT_INVITE,
                            ],
                            builder: (value, isOwner) {
                              if (value)
                                return _inviteWidget(context);
                              else
                                return const SizedBox();
                            },
                          );

                        return TaskStatusPanel(questGroup: quest);
                      }),
                      if (target != null)
                        CrossPlatformCircleEntryView(key: ValueKey(target.id)),
                      Divider(
                        color: appThemeData.dividerColor.withOpacity(0.1),
                        height: .5,
                      ),
                      Expanded(
                        child: target == null
                            ? DirectMessageView()
                            : LandscapeGuildChannelList(),
                      ),
                      if (rxIsShow.value)
                        ObxValue<RxString>((title) {
                          return TaskIntroductionTips(
                            taskStyle: TaskStyle.Channel,
                            content: title?.value?.hasValue ?? false
                                ? title?.value
                                : '完成新成员验证，开始畅聊'.tr,
                          );
                        }, TaskUtil.instance.taskEntityTitle),
                    ],
                  );
                }, TaskUtil.instance.isNewGuy))),

        _buildAudioWidget(),

        /// 个人信息
        Builder(builder: (context) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(11, 0, 11, 16),
            child: FadeBackgroundButton(
              onTap: () => Routes.pushPersonalPage(context),
              tapDownBackgroundColor: Theme.of(context).highlightColor,
              backgroundColor: Theme.of(context).backgroundColor,
              boxShadow: const [
                BoxShadow(color: Color(0x33717D8D), blurRadius: 16)
              ],
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                decoration: webBorderDecoration.copyWith(
                    borderRadius: BorderRadius.circular(0),
                    color: Colors.transparent),
                child: Consumer<LocalUser>(
                  builder: (context, user, _) {
                    return Row(
                      children: <Widget>[
                        Stack(
                          children: <Widget>[
                            Avatar(url: user.avatar, radius: 16),
                          ],
                        ),
                        sizeWidth16,
                        Expanded(
                          child: Text(
                            user.nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ),
                        const Icon(
                          IconFont.webCircleSetUp,
                          size: 22,
                        )
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        })
      ],
    );
  }

  Padding _inviteWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 11, left: 12, right: 12, bottom: 7),
      child: FadeButton(
        throttleDuration: const Duration(seconds: 1),
        onTap: () => showShareLinkPopUp(
          context,
          direction: TooltipDirection.right,
          margin: const EdgeInsets.only(left: 204),
        ),
        padding: const EdgeInsets.symmetric(vertical: 7.5),
        decoration: BoxDecoration(
          color: appThemeData.dividerColor.withOpacity(.15),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(IconFont.buffModuleMenuOpen, size: 16),
            sizeWidth6,
            Text(
              '邀请成员'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
