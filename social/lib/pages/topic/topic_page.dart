import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/modules/task/introduction_ceremony/open_task_introduction_ceremony.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_mixin.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/gif_search_view.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/events.dart';
import 'package:im/pages/home/model/guild_topic_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/input_prompt/at_selector_model.dart';
import 'package:im/pages/home/model/input_prompt/channel_selector_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/bottom_bar/at_list_base.dart';
import 'package:im/pages/home/view/bottom_bar/channel_selector_view.dart';
import 'package:im/pages/home/view/bottom_bar/text_chat_bottom_bar.dart';
import 'package:im/pages/home/view/bottom_bar/web_bottom_bar.dart';
import 'package:im/pages/home/view/record_view/record_sound_state.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/pages/home/view/text_chat/web_message_hover_wrapper.dart';
import 'package:im/pages/home/view/text_chat_constraints.dart';
import 'package:im/pages/topic/scroll/scroll_flexible_widget.dart';
import 'package:im/pages/topic/topic_page_bottom_bar.dart';
import 'package:im/pages/topic/topic_share_widget.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/widgets/app_bar/web_appbar.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/dialog/action_confirm_dialog.dart';
import 'package:im/widgets/gesture/custom_vertical_drag_detector.dart';
import 'package:im/widgets/list_physics.dart';
import 'package:im/widgets/list_view/position_list_view/src/scrollable_positioned_list.dart';
import 'package:im/widgets/list_view/proxy_index_list.dart';
import 'package:im/widgets/load_more.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:provider/provider.dart';

import '../../global.dart';
import '../../icon_font.dart';
import '../../utils/universal_platform.dart';
import 'controllers/topic_controller.dart';

//传入参数
class TopicParam {
  final MessageEntity message;
  final String gotoMessageId;
  final bool isTopicShare;

  TopicParam(this.message, this.gotoMessageId, this.isTopicShare);
}

//返回参数
class TopicBackParam {
  final String guildId;
  final String channelId;
  final String messageId;

  TopicBackParam(this.guildId, this.channelId, this.messageId);
}

class TopicPage extends StatefulWidget {
  final MessageEntity message;
  final String gotoMessageId;
  final bool isTopicShare;

  const TopicPage({this.message, this.gotoMessageId, this.isTopicShare});

  static ProxyController proxyController;

  @override
  _TopicPageState createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> with GuildPermissionListener {
  InputModel _inputModel;
  String rootMessageId;
  ChatChannel channel;
  bool isShowDialog = false;

  MessageEntity message;
  String gotoMessageId;
  ProxyController proxyController;

  TopicController controller = TopicController.to();
  ScrollController scrollController = ScrollController();

  final ScrollController _userImageScrollController =
      ScrollController(); //listview的控制器
  /// 用来记录当前进入话题详情的时间
  final DateTime _enterPageDate = DateTime.now();

  @override
  void initState() {
    controller?.users?.clear();
    controller?.loadHistoryState = LoadMoreStatus.ready;
    controller?.isTureTop = false;
    proxyController = ProxyController.fromItemController(ItemScrollController(),
        scrollController: scrollController);
    TopicPage.proxyController = proxyController;

    _init();

    super.initState();
  }

  @override
  void dispose() {
    controller?.cancelGetReplyList();
    _inputModel?.dispose();
    TopicPage.proxyController = null;
    disposePermissionListener();
    Get.delete<TopicController>();

    super.dispose();
  }

  void _init() {
    final TopicParam topicParam = Get.arguments;

    message = topicParam?.message;
    gotoMessageId = topicParam?.gotoMessageId;
    bool isTopicShare = topicParam?.isTopicShare;

    message ??= widget.message;
    gotoMessageId ??= widget.gotoMessageId;
    isTopicShare ??= widget.isTopicShare;

    controller.initData(message, gotoMessageId, isTopicShare, scrollController);

    final dmChannel = TextChannelController.dmChannel?.id == message.channelId
        ? DirectMessageController.to.getChannel(message.channelId)
        : null;

    channel = dmChannel ??
        ChatTargetsModel.instance.selectedChatTarget
            ?.getChannel(message.channelId);

    ///fix 群聊进入话题详情页 channel 为null
    channel ??= DirectMessageController.to.getChannel(message.channelId);

    final cacheText =
        TopicController.getInputCache(message.messageId)?.content ?? '';
    _inputModel = InputModel(
      channelId: channel.id,
      guildId: message.guildId,
      type: message.type,
    );
    // 延时是因为 iOS 的 MethodChannel 可能还未建立
    delay(() {
      if (mounted) _inputModel.setValue(cacheText, reply: message);
    }, 100);
    _inputModel.textFieldFocusNode.addListener(() {
      // NOTE: 2022/2/22 必须要检测proxyController isAttached
      if (_inputModel.textFieldFocusNode.hasFocus &&
          proxyController.isAttached) {
        proxyController.jumpToIndex(controller.messages.length + 1,
            alignment: 1);
      }
    });

    _inputModel.contentChangeStream.listen((value) {
      final inputRecord = TopicController.getInputCache(controller.messageId);
      TopicController.updateInputCache(
          controller.messageId,
          InputRecord(
            replyId: _inputModel.reply?.messageId,
            content: value,
            richContent: inputRecord?.richContent,
          ));
    });

    rootMessageId = message.quoteL1 ?? message.messageId;

    addPermissionListener();

    _initLookers();
  }

  void _initLookers() {
    //围观判断是否具有表态权限
    if (message.guildId.hasValue && message.guildId != "0") {
      final GuildPermission gp = Db.guildPermissionBox.get(message.guildId);
      if (gp == null) return;

      final canReaction = PermissionUtils.oneOf(gp, [Permission.ADD_REACTIONS],
          channelId: message.channelId);
      if (!canReaction) return;
    }

    //自己不表态自己
    if (message.userId == Global.user.id) return;

    //私信话题详情不表态
    if (TextChannelController.dmChannel != null &&
        TextChannelController.dmChannel.type == ChatChannelType.dm) return;

    if (OrientationUtil.landscape) {
      final channel = GlobalState.selectedChannel.value;
      if (channel != null && channel.type == ChatChannelType.dm) return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 5)).then((_) {
        if (mounted) {
          controller.autoReaction();
          DLogManager.getInstance().extensionEvent(
            logType: 'dlog_app_lookon_topic_fb',
            extJson: {
              "guild_id": message.guildId,
              "chat_log_type": '1',
              "message_event_id": 'browse_topic',
              "channel_id": message.channelId,
              "message_id": message.messageId,
              "message_user_id": message.userId,
            },
          );
        }
      });
    });
    _userImageScrollController.addListener(() {
      if (_userImageScrollController.position.atEdge) {
        if (_userImageScrollController.position.pixels != 0) {
          // You're at the bottom.
          controller.loadMore();
        }
      }
    });
  }

  Widget getTitle(TextStyle style) {
    final text = Text('话题详情'.tr, style: style);
    final btn = GestureDetector(
      onTap: () {
        if (UniversalPlatform.isIOS) {
          onClick();
        }
      },
      onDoubleTap: () {
        if (UniversalPlatform.isAndroid) {
          onClick();
        }
      },
      child: text,
    );
    return btn;
  }

  ///列表回到顶部
  void onClick() {
    if (controller.loadHistoryState == LoadMoreStatus.loading) return;

    if (controller.loadHistoryState != LoadMoreStatus.noMore) {
      controller.loadHistoryState = LoadMoreStatus.toTop;
      controller.isTureTop = false;
    }
    proxyController.animationToIndex(0,
        duration: const Duration(milliseconds: 200));
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final chatTarget = ChatTargetsModel.instance?.selectedChatTarget;

    ///fix 服务台平台才能分享
    final canShowTopicShare = chatTarget != null && !GlobalState.isDmChannel;
    // && !PermissionUtils.isPrivateChannel(gp, widget.textChatModel.channelId)// 私密频道不可分享

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AtSelectorModel>(
            create: (_) => AtSelectorModel(_inputModel, channel)),
        ChangeNotifierProvider.value(value: _inputModel),
        ChangeNotifierProvider(create: (_) => RecordSoundState()),
      ],
      builder: (context, _) => NotificationListener(
        onNotification: (n) {
          if (n is ScrollToBottomNotification) {
            Future.delayed(n.delay, () {
              proxyController.jumpToIndex(1e8.toInt(), alignment: 1);
            });
          }
          if (n is ResendMessageNotification) {
            controller.resendMessage(n.message);
          }
          return true;
        },
        child: Scaffold(
            backgroundColor: Theme.of(context).backgroundColor,
            resizeToAvoidBottomInset: false,
            appBar: OrientationUtil.portrait
                ? CustomAppbar(
                    titleBuilder: getTitle,
                    backgroundColor: Colors.white,
                    leadingCallback: () {
                      Get.back();

                      /// 记录用户进入到结束的预览时长
                      final browseDuration =
                          (DateTime.now().millisecondsSinceEpoch -
                                  _enterPageDate.millisecondsSinceEpoch) ~/
                              1000;
                      DLogManager.getInstance().extensionEvent(
                        logType: 'dlog_app_lookon_topic_fb',
                        extJson: {
                          "guild_id": message.guildId,
                          "chat_log_type": '1',
                          "message_event_id": 'exit_topic',
                          "channel_id": message.channelId,
                          "message_id": message.messageId,
                          "message_user_id": message.userId,
                          "browse_duration": browseDuration,
                        },
                      );
                    },
                    actions: [
                      if (canShowTopicShare)
                        AppbarIconButton(
                          icon: IconFont.buffChatForward,
                          onTap: () {
                            final TopicController c = Get.find();
                            if (c.messages.isEmpty) return;
                            if (OpenTaskIntroductionCeremony
                                .openTaskInterface()) return;
                            shareTopic(context, message);
                          },
                        )
                    ],
                  )
                : WebAppBar(
                    title: "话题详情".tr,
                    backAction: Get.back,
                    tailing: canShowTopicShare
                        ? Builder(
                            builder: (context) {
                              return GetBuilder<TopicController>(
                                builder: (_c) => IconButton(
                                  icon: const Icon(
                                    IconFont.buffChatForward,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    if (_c.messages.isEmpty) return;
                                    if (OpenTaskIntroductionCeremony
                                        .openTaskInterface()) return;
                                    shareTopic(context, message);
                                  },
                                ),
                              );
                            },
                          )
                        : null,
                  ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                GetBuilder<TopicController>(
                  init: TopicController(),
                  builder: (c) {
                    if (c.users != null && c.users.isNotEmpty) {
                      return ScrollFlexibleWidget(
                        controller: scrollController,
                        flexibleSpace: userIcons(context),
                      );
                    } else {
                      return sizedBox;
                    }
                  },
                ),
                const Divider(),
                Expanded(
                    child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    ValidPermission(
                        permissions: const [],
                        builder: (value, _) {
                          return LayoutBuilder(builder: (context, constraints) {
                            return TextChatConstraints(
                              context: context,
                              constraints: constraints,
                              child: CustomVerticalDragDetector(
                                  onStart: (_) =>
                                      FocusScope.of(context).unfocus(),
                                  child: buildProxyIndexList()),
                            );
                          });
                        }),
                    if (channel.type != ChatChannelType.dm) AtList(),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: GifSearchView(_inputModel.channelId),
                    ),
                    if (ChatTargetsModel.instance.selectedChatTarget
                        is GuildTarget)
                      ChangeNotifierProvider(
                        create: (_) =>
                            ChannelSelectorModel(inputModel: _inputModel),
                        builder: (_, child) => ChannelSelectorView(),
                      ),
                    _maskView()
                  ],
                )),
                if (OrientationUtil.portrait)
                  TopicPageBottomBar(message.messageId, channel)
                else
                  WebBottomBar(
                    channel,
                    isFromTopicPage: true,
                  ),
              ],
            )),
      ),
    );
  }

  Widget userIcons(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 64,
      child: ListView.builder(
        controller: _userImageScrollController,
        padding: const EdgeInsets.only(left: 7, right: 7),
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: controller.users.length,
        itemBuilder: (context, index) {
          final userId = controller.users[index].userId;
          final isPush = controller.users[index].isPush;
          return GestureDetector(
              onTap: () {
                if (!kIsWeb) {
                  FocusScope.of(context).unfocus();
                }
                showUserInfoPopUp(
                  context,
                  userId: userId,
                  guildId: message.guildId,
                  showRemoveFromGuild:
                      GlobalState.selectedChannel.value?.type !=
                          ChatChannelType.dm,
                  enterType: GlobalState.selectedChannel.value?.type ==
                          ChatChannelType.dm
                      ? EnterType.fromDefault
                      : EnterType.fromServer,
                );
              },
              onLongPress: () async {
                final name = (await UserInfo.get(userId)).showName();
                context.read<InputModel>()
                  ..add(userId, name, atRole: false, addDirectly: true)
                  ..textFieldFocusNode.requestFocus();
              },
              child: AnimateAvatarWidget(userId, 40, isPush,
                  key: ValueKey(userId)));
        },
      ),
    );
  }

  Widget buildProxyIndexList() {
    return GetBuilder<TopicController>(builder: (_controller) {
      final messages = _controller.messages;
      if (messages.isEmpty) return const SizedBox();

      int initialIndex;
      ProxyInitialAlignment initialAlignment;
      if (_controller.isTopicShare) {
        initialIndex = 0;
        initialAlignment = ProxyInitialAlignment.top;
      } else {
        if (_controller.listScrollIndex != null) {
          initialIndex = _controller.listScrollIndex + 1;
          _controller.listScrollIndex = null;
          //initialAlignment = ProxyInitialAlignment.top;
        } else {
          initialIndex = messages.length + 3;
          initialAlignment = ProxyInitialAlignment.bottom;
        }
      }

      return ProxyIndexList(
        //key: _controller.listKey,
        physics: const SlowListPhysics(),
        initialIndex: initialIndex,
        initialAlignment: initialAlignment,
        controller: proxyController,
        indexListener: _controller.indexListener,
        builder: (context, index) {
          if (index == 0) {
            return const SizedBox();
          }
          index--;
          if (index >= messages.length) {
            return const SizedBox();
          }

          final message = messages[index];
          final List<Widget> children = [];
          final isDeletedMes = index > 0 && message.deleted == 1;

          if ((index == 0 || !message.isRecalled) && !isDeletedMes)
            children.add(Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
                child: TextChatUICreator.buildUserInfoRow(context, message,
                    guildId: message.guildId)));
          if (!isDeletedMes)
            children.add(TextChatUICreator.createItem(
                context, index, _controller.messages,
                guidId: _controller.messages[index].guildId,
                shouldShowUserInfo: false,
                onTap: () => FocusScope.of(context).unfocus(),
                createQuote: false,
                padding: message.isRecalled
                    ? const EdgeInsets.only(right: 6)
                    : const EdgeInsets.fromLTRB(16, 8, 0, 8),
                quoteL1: message.quoteL1 ?? message.messageId,
                isFromTopicPage: true,
                onUnFold: (string) {},
                isUnFold: (string) => true));
          if (index == 0 && messages.first.messageId == message.messageId)
            children
              ..add(Container(
                height: 1,
                color: Theme.of(context).scaffoldBackgroundColor,
                margin: const EdgeInsets.only(top: 8, bottom: 16),
              ))
              ..add(Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: buildReplyNum(context, _controller.messages.length - 1),
              ));
          if (OrientationUtil.portrait ||
              message.isRecalled ||
              message.deleted == 1)
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children);
          else
            return WebMessageHoverWrapper(
              isFromTopicPage: true,
              message: message,
              relay: () {
                Provider.of<InputModel>(context, listen: false).reply = message;
              },
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children),
            );
        },
        itemCount: messages.length + 3,
      );
    });
  }

  Widget _maskView() {
    // 删除按钮
    return Consumer<RecordSoundState>(builder: (context, state, child) {
      return state.second == 0
          ? Container()
          : Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: const Color(0x00000000),
            );
    });
  }

  @override
  String get guildPermissionMixinId => message.guildId;

  @override
  void onPermissionChange() {
    final gp = PermissionModel.getPermission(message.guildId);
    final isVisible =
        PermissionUtils.isChannelVisible(gp, controller.channelId);
    final selectChannelId = GlobalState?.selectedChannel?.value?.id;
    if (!isVisible && selectChannelId != controller.channelId) {
      if (isShowDialog == false) {
        isShowDialog = true;
        showDialog(
                context: Global.navigatorKey.currentContext,
                builder: (ctx) {
                  return ActionConfirmDialog(
                    title: "你没有权限访问此话题，请联系管理员".tr,
                    onConfirm: () {
                      Navigator.pop(Global.navigatorKey.currentContext, true);
                    },
                  );
                },
                barrierDismissible: false)
            .then((value) {
          if (value == true) {
            //退出当前话题
            if (Navigator.canPop(Global.navigatorKey.currentContext)) {
              Navigator.pop(Global.navigatorKey.currentContext);
            }
          }
        });
        isShowDialog = false;
      }
    }
  }
}

class AnimateAvatarWidget extends StatefulWidget {
  final String userId;
  final double size;
  final bool isPush;

  const AnimateAvatarWidget(this.userId, this.size, this.isPush, {Key key})
      : super(key: key);

  @override
  _AnimateAvatarWidgetState createState() => _AnimateAvatarWidgetState();
}

class _AnimateAvatarWidgetState extends State<AnimateAvatarWidget>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //渐变
    //FadeTransition
    return FadeTransition(
      opacity: widget.isPush
          ? _controller.drive(Tween(begin: 0, end: 1))
          : _controller.drive(Tween(begin: 1, end: 1)),
      child: Container(
        width: widget.size + 16,
        height: widget.size + 16,
        alignment: Alignment.center,
        child: RealtimeAvatar(
            userId: widget.userId, size: widget.size, useTexture: false),
      ),
    );

    //渐变+从小到大
    // return AnimatedBuilder(
    //   animation: _controller.drive(Tween(begin: 0, end: 1)),
    //   builder: (context, child) {
    //     return SizedBox(
    //       width: widget.size,
    //       height: widget.size,
    //       child: Opacity(
    //           opacity: _controller.value,
    //           child: RealtimeAvatar(
    //               userId: widget.userId,
    //               size: widget.size * _controller.value)),
    //     );
    //   },
    // );

    //从小到大
    //ScaleTransition
    // return ScaleTransition(
    //   scale: _controller.drive(Tween(begin: 0, end: 1)),
    //   child: RealtimeAvatar(userId: widget.userId, size: 48),
    // );
  }
}
