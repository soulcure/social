import 'dart:async';
import 'dart:math';

import 'package:fb_utils/fb_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app.dart';
import 'package:im/app/modules/friend_apply_page/controllers/friend_apply_page_controller.dart';
import 'package:im/app/modules/friend_list_page/controllers/friend_list_page_controller.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages;
import 'package:im/app/theme/app_colors.dart';
import 'package:im/core/widgets/fb_scrollbar.dart';
import 'package:im/db/db.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/bot_commands/landscape_popup_list.dart';
import 'package:im/pages/bot_commands/model/displayed_cmds_model.dart';
import 'package:im/pages/bot_commands/popup_list.dart';
import 'package:im/pages/friend/relation.dart';
import 'package:im/pages/friend/widgets/relation_utils.dart';
import 'package:im/pages/home/components/bottom_right_button/bottom_loading.dart';
import 'package:im/pages/home/components/bottom_right_button/bottom_right_button.dart';
import 'package:im/pages/home/components/bottom_right_button/bottom_right_button_controller.dart';
import 'package:im/pages/home/components/bottom_right_button/top_right_button.dart';
import 'package:im/pages/home/components/bottom_right_button/top_right_button_controller.dart';
import 'package:im/pages/home/json/add_friend_tips_entity.dart';
import 'package:im/pages/home/json/message_entity_extension.dart';
import 'package:im/pages/home/json/redpack_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/ban_controller.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/events.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/input_prompt/at_selector_model.dart';
import 'package:im/pages/home/model/input_prompt/channel_selector_model.dart';
import 'package:im/pages/home/model/stick_message_controller.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/pages/home/view/bottom_bar/at_list_base.dart';
import 'package:im/pages/home/view/bottom_bar/text_chat_bottom_bar.dart';
import 'package:im/pages/home/view/bottom_bar/web_bottom_bar.dart';
import 'package:im/pages/home/view/content_loading.dart';
import 'package:im/pages/home/view/record_view/record_sound_state.dart';
import 'package:im/pages/home/view/record_view/sound_play_manager.dart';
import 'package:im/pages/home/view/text_chat/items/add_friend_tips_item.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/home/view/text_chat/message_tools.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/pages/home/view/text_chat_constraints.dart';
import 'package:im/pages/topic/controllers/topic_controller.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/message_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/button/custom_icon_button.dart';
import 'package:im/widgets/gesture/custom_vertical_drag_detector.dart';
import 'package:im/widgets/list_physics.dart';
import 'package:im/widgets/list_view/proxy_index_list.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart' show DebounceExtensions;
import 'package:sliding_sheet/sliding_sheet.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../global.dart';
import '../gif_search_view.dart';
import 'bottom_bar/channel_selector_view.dart';
import 'bottom_bar/text_chat_bottom_bar.dart';

enum ChatViewScrollState {
  none,
  scrollEnd,
  scrollOffset,
}

const TextChatViewBottomPadding = 6.0;

/// - 聊天页面
class TextChatView extends StatefulWidget {
  final TextChannelController model;
  final Widget bottomBar;

  const TextChatView({
    @required this.model,
    @required this.bottomBar,
    Key key,
  }) : super(key: key);

  @override
  _TextChatViewState createState() => _TextChatViewState();
}

class _TextChatViewState extends State<TextChatView>
    with WidgetsBindingObserver {
  ProxyController proxyController;
  ProxyIndexListener proxyListener;
  InputModel inputModel;
  DisplayedCmdsController displayedCmdsModel;

  StreamSubscription _newMessageSubscription;

  bool _showItemContextMenu = false;
  final List<String> _unFoldMessageList = [];

  // 聊天公屏过度滑动距离
  double chatViewOffset = TextChatViewBottomPadding;
  double kDefaultOverScrollOffset = 36;
  ChatViewScrollState chatViewScrollState = ChatViewScrollState.none;

  ///右下角按钮 Controller
  BottomRightButtonController bottomRightButtonController;

  ///右上角按钮 Controller
  TopRightButtonController topRightButtonController;

  int listItemCount = 0;
  MessageEntity selectedMessage;

  double get richInputHeight =>
      Get.window.physicalSize.height / Get.pixelRatio * 0.8;

  Worker _onWindowChangeListener;

  SheetController _cmdController;

  @override
  void initState() {
    proxyController = widget.model.proxyController;
    proxyListener = widget.model.proxyListener;
    _cmdController = SheetController();
    final channelId = widget.model.channelId;

    inputModel = InputModel(
        channelId: channelId,
        guildId: widget.model.guildId,
        type: widget.model.channel.type,
        onReplyChange: (m, c) {
          final inputRecord = Db.textFieldInputRecordBox.get(channelId);
          Db.textFieldInputRecordBox.put(
              channelId,
              InputRecord(
                  replyId: m?.messageId,
                  content: c,
                  richContent: inputRecord?.richContent));
          if (m != null) inputModel.textFieldFocusNode.requestFocus();
        });
    inputModel.contentChangeStream
        .debounceTime(const Duration(seconds: 1))
        .listen((value) {
      final inputRecord = Db.textFieldInputRecordBox.get(channelId);
      Db.textFieldInputRecordBox.put(
        channelId,
        InputRecord(
          replyId: inputModel.reply?.messageId,
          content: value,
          richContent: inputRecord?.richContent,
        ),
      );
    });
    displayedCmdsModel = Get.put(
        DisplayedCmdsController(_cmdController, channelId),
        tag: channelId);
    // 机器人指令model监听用户输入状态，来决定是否展示指令按钮
    inputModel.robotCmdListener = displayedCmdsModel;

    bottomRightButtonController = BottomRightButtonController.to(channelId);
    topRightButtonController = TopRightButtonController.to(channelId);

    /// 如果用户不在列表底部，当有新消息收到时，会保留滚动位置，并且提醒用户 n 条新消息
    /// 但是，如果是自己发送的消息，则不需要提醒
    _newMessageSubscription =
        TextChannelUtil.instance.stream.listen((event) async {
      if (event is NewMessageEvent) {
        if (OrientationUtil.landscape) {
          final TopicController tc = TopicController.to();
          if (tc.channelId == event.message.channelId) {
            widget.model.topicPageJumpToBottom();
          }
        } else if (Get.currentRoute == get_pages.Routes.TOPIC_PAGE &&
            App.appLifecycleState == AppLifecycleState.resumed) {
          final TopicController tc = TopicController.to();

          if (tc.channelId == event.message.channelId &&
              tc.messageId == event.message.quoteL1) {
            widget.model.topicPageJumpToBottom();
            //return;//话题返回，频道消息到底部
          }
        } else if (Get.currentRoute == '/RichTunInputPop' &&
            Get.previousRoute == get_pages.Routes.TOPIC_PAGE &&
            App.appLifecycleState == AppLifecycleState.resumed) {
          final TopicController tc = TopicController.to();
          if (tc.channelId == event.message.channelId) {
            widget.model.topicPageJumpToBottom();
            return;
          }
        }

        if (event.message.channelId != widget.model.channelId) return;
        bool canScroll = false;
        if (event.force) {
          canScroll = true;
        } else {
          if (ChatViewScrollState.scrollOffset == chatViewScrollState) {
            canScroll = false;
          } else {
            canScroll = widget.model.numBottomInvisible <= 1;
          }
        }
        if (event.jump && canScroll && !_showItemContextMenu) {
          ///ios手机调用支付包支付，fanbook会在后台
          if (event.message.userId == Global.user.id &&
              event.message.content is RedPackEntity) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.model.jumpToBottom();
            });
            return;
          }

          if (App.appLifecycleState == AppLifecycleState.resumed) {
            bottomRightButtonController.isSelfJumpBottom = true;
            widget.model.jumpToBottom();
          }
        }
      }
    });

    _onWindowChangeListener =
        ever(HomeScaffoldController.to.windowIndex, _onWindowChange);

    proxyListener?.itemPositionsListener?.itemPositions?.addListener(_onScroll);

    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void dispose() {
    inputModel.dispose();
    _onWindowChangeListener.dispose();
    proxyListener?.itemPositionsListener?.itemPositions
        ?.removeListener(_onScroll);
    _newMessageSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    bottomRightButtonController?.clear();
    topRightButtonController?.clear();

    final channelId = widget.model.channelId;
    Get.delete<TopRightButtonController>(tag: channelId);
    Get.delete<DisplayedCmdsController>(tag: channelId);
    super.dispose();
  }

  int _listIndex2MessageIndex(int index) => index;

  void _onScroll() {
    final m = widget.model;
    final positions =
        proxyListener?.itemPositionsListener?.itemPositions?.value;
    if (positions == null || positions.isEmpty) {
      debugPrint('text chat view onscroll position empty');
      return;
    }
    final topIndex = positions
        .where((position) => position.itemTrailingEdge > 0)
        .reduce((minValue, position) {
      // TODO 能不能简化
      /// Web 刚加入服务器的时候，会存在itemTrailingEdge相同的几条数据，导致永远滑动不到index == 0，所以无法拉去历史数据
      if (minValue.itemTrailingEdge == position.itemTrailingEdge) {
        if (position.index < minValue.index)
          return position;
        else
          return minValue;
      }
      return position.itemTrailingEdge < minValue.itemTrailingEdge
          ? position
          : minValue;
    }).index;
    if (topIndex <= 0) {
      kDefaultOverScrollOffset = 64;
      if (m.canReadHistory) m.loadHistory();
    }
    final bottomIndex = positions
        .where((position) => position.itemLeadingEdge < 1)
        .reduce((max, position) =>
            position.itemLeadingEdge > max.itemLeadingEdge ? position : max)
        .index;
    m.topIndex = max(0, topIndex);
    m.bottomIndex = max(0, bottomIndex - 2);

    final numBottomInvisible =
        _listIndex2MessageIndex(listItemCount - 1 - bottomIndex);
    if (numBottomInvisible <= 0) {
      kDefaultOverScrollOffset = 36;
      m.loadMore();
    }
    m.numBottomInvisible = numBottomInvisible;
    // final numUnread = ChannelUtil.instance.getUnread(m.channel.id);

    /// web右下角的未读数依赖于以下此段逻辑，在此做一些微调，建议在后续top right的逻辑加到web后统一处理，优化一下代码
    if (HomeScaffoldController.to.canChatWindowVisible ||
        kIsWeb ||
        Get.currentRoute == directChatViewRoute) {
      if (!kIsWeb) topRightButtonController.updateNumUnread();

      bottomRightButtonController.updateByScroll();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // 停止声音播放
      SoundPlayManager().stop();
    }
  }

  ///右下角按钮逻辑 已经移动到单独的组件
  void _updateBottomButton({bool isSync = false, bool isUpNow = false}) {
    final m = widget.model;
    if (m.numBottomInvisible <= 0 &&
        HomeScaffoldController.to.canChatWindowVisible &&
        m.listIsIdentical()) {
      final MessageEntity item = m.internalList.lastMessage;
      ChannelUtil.instance.setUnreadAndSync(item, sync: isSync, upNow: isUpNow);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: inputModel),
        // ChangeNotifierProvider.value(value: widget.model),
        ChangeNotifierProvider<AtSelectorModel>(
            create: (_) => AtSelectorModel(inputModel, widget.model.channel)),
        ChangeNotifierProvider.value(value: RecordSoundState.instance),
      ],
      //target == null 应该是处于私聊状态，不用封禁
      child: Stack(children: [
        buildGetBuilder(),
        GetBuilder<BanController>(
          init: BanController(widget.model.channel.guildId),
          tag: widget.model.channel.guildId,
          builder: (c) {
            if (c.isBan()) {
              return Container(color: Colors.white);
            }
            return const SizedBox();
          },
        ),
      ]),
    );
  }

  Widget buildGetBuilder() {
    return GetBuilder<TextChannelController>(
        init: TextChannelController(widget.model.channel),
        tag: widget.model.channel.id,
        builder: (c) {
          return NotificationListener(onNotification: (n) {
            if (n is ScrollToBottomNotification) {
              widget.model.jumpToBottom(delay: Duration.zero);
            }
            if (n is ResendMessageNotification) {
              widget.model.resend(n.message);
            }
            return true;
          }, child: LayoutBuilder(builder: (context, constraints) {
            return TextChatConstraints(
                context: context,
                constraints: constraints,
                child: Stack(
                  children: [
                    Column(
                      children: <Widget>[
                        const Divider(),
                        if (widget.model.channel?.type == ChatChannelType.dm)
                          _buildBlockBanner(),
                        _buildStickBanner(),
                        if (widget.model.channel?.type == ChatChannelType.dm)
                          _addFriendTips(),
                        Expanded(child: _buildChatView()),
                        if (OrientationUtil.portrait)
                          widget.bottomBar
                        else
                          WebBottomBar(
                            widget.model.channel,
                          ),
                      ],
                    ),
                  ],
                ));
          }));
        });
  }

  Widget _buildChatView() {
    return Stack(
      children: <Widget>[
        _buildList(),
        if (!kIsWeb)
          Positioned(
              top: 60, right: 0, child: TopRightButton(widget.model.channelId)),
        _buildBottomButton(),
        if (widget.model.channel.type != ChatChannelType.dm)
          AtList(), // 私, // 聊 无@ 列表
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: GifSearchView(inputModel.channelId),
        ),

        /// 如果是服务器中的频道，有选择频道的功能, 并且不属于私聊和部落聊天页
        if (ChatTargetsModel.instance.selectedChatTarget is GuildTarget &&
            ![ChatChannelType.dm, ChatChannelType.group_dm]
                .contains(widget.model.channel.type))
          ChangeNotifierProvider(
            create: (_) => ChannelSelectorModel(inputModel: inputModel),
            builder: (_, child) => ChannelSelectorView(),
          ),

        // ArticlePicker(), // link 列表
        // EmojiPicker(),
        _maskView(),
        _robotCmdsList(),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Positioned(
        bottom: 0,
        right: 0,
        child: Center(
          child: BottomRightButton(widget.model.channelId),
        ));
  }

  Widget _buildBlockBanner() {
    return GetBuilder<FriendListPageController>(builder: (c) {
      final blackListIsContain = c.blackListIsContain(widget.model.guildId);
      if (!blackListIsContain) return const SizedBox();
      return Container(
        width: double.infinity,
        height: 38,
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
                child: Text(
              "你已屏蔽对方，对方无法私聊你".tr,
              maxLines: 1,
              style:
                  Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            )),
            CupertinoButton(
                padding: const EdgeInsets.all(0),
                onPressed: () async {
                  if (FriendListPageController.to
                      .blackListIsContain(widget.model.guildId)) {
                    await FriendListPageController.to
                        .removeFromBlackList(widget.model.guildId);
                    showToast("已解除屏蔽".tr);
                  } else {
                    showToast("已被解除屏蔽".tr);
                  }
                },
                child: Text('解除屏蔽'.tr,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.visible)),
          ],
        ),
      );
    });
  }

  Widget _buildStickBanner() {
    return GetBuilder<StickMessageController>(
        init: StickMessageController.to(channelId: widget.model.channelId),
        tag: widget.model.channelId,
        builder: (stickMessageController) {
          return AnimatedBuilder(
              animation: stickMessageController.animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: stickMessageController.animationController,
                  child: SizeTransition(
                    sizeFactor: stickMessageController.animationController,
                    axisAlignment: -1,
                    child: Builder(
                      builder: (context) {
                        final stickMessageBean =
                            stickMessageController.stickMessageBean;
                        if (stickMessageBean == null ||
                            stickMessageBean.isStickRead) {
                          return sizedBox;
                        }

                        final stickMessage = stickMessageBean.message;
                        final stickUserId = stickMessageController
                            .stickMessageBean?.stickUserId;
                        return FutureBuilder<String>(
                            future: stickMessageController.toStringStrFuture,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.hasError)
                                return const SizedBox();
                              return GestureDetector(
                                onTap: () {
                                  widget.model
                                      .gotoMessage(stickMessage.messageId);
                                },
                                child: Container(
                                    height: 49,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    color: const Color(0xFFFFF2D9),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Container(
                                              color: const Color(0xFFD9940B),
                                              height: 30,
                                              width: 2),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                RealtimeNickname(
                                                  userId: stickUserId,
                                                  suffix:
                                                      "%s 置顶了：".trArgs([""]),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    height: 1.25,
                                                    color: Color(0xFFD9940B),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                sizeHeight2,
                                                Text(
                                                  snapshot.data,
                                                  maxLines: 1,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyText1
                                                      .copyWith(
                                                          fontSize: 13,
                                                          height: 1.23,
                                                          color: const Color(
                                                              0xFF663E05)),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                )
                                              ],
                                            ),
                                          ),
                                          sizeWidth12,
                                          CustomIconButton(
                                              size: 14,
                                              iconColor:
                                                  const Color(0xFF646A73),
                                              iconData:
                                                  IconFont.buffNavBarCloseItem,
                                              padding: const EdgeInsets.all(2),
                                              onPressed: stickMessageController
                                                  .readAllStickMessage)
                                        ],
                                      ),
                                    )),
                              );
                            });
                      },
                    ),
                  ),
                );
              });
        });
  }

  Widget _buildList() {
    final model = widget.model;
    final list = model.messageList;

    print(
        'model.showLoading: ${model.showLoading}, list.isEmpty: ${list.isEmpty}');
    if (!kIsWeb && model.showLoading && list.isEmpty)
      return const ContentLoadingView();

//      if (list.isEmpty && widget.model.newMessagePosition != 0)
//        return const SizedBox();

    final itemCount = list.length + 2;
    var initialScrollIndex = itemCount;
    if (model.newMessagePosition > 0) {
      if (model.newMessagePosition >= list.length) {
        logger.warning("未读消息超出消息总数");
      }
    }

    // TODO 先去掉加载中，解决点击推送列表跳动。之后改成浮动 loading 的方案
    // if (model.channelId == JPushUtil.launchParametersChannelId) {
    //   // 如果是从通知点击进来并且没有显示新消息，那么需要加载个loading状态
    //   itemCount++;
    //   JPushUtil.clearLaunchParameters();
    // }
    listItemCount = itemCount;

    bool useForceIndex = false;

    if ((model.numBottomInvisible > 0 ||
            !model.listIsIdentical() ||
            model.loadMoreForceUpdate) &&
        model.forceInitialIndex != null &&
        itemCount > model.forceInitialIndex) {
      useForceIndex = model.useForceIndex ?? true;
      initialScrollIndex = model.forceInitialIndex;
      model.forceInitialIndex = null;
      model.useForceIndex = null;
      model.loadMoreForceUpdate = false;
      model.listKey = ValueKey(model.listKey.value + 1);
    }

    final initialAlignment = useForceIndex
        ? ProxyInitialAlignment.top
        : ProxyInitialAlignment.bottom;

    if (model.isJumpBottom ?? false) {
      chatViewOffset = TextChatViewBottomPadding;
      chatViewScrollState = ChatViewScrollState.scrollEnd;
      model.isJumpBottom = false;
    }

    return LayoutBuilder(builder: (context, constraints) {
      return TextChatConstraints(
          constraints: constraints,
          context: context,
          child: CustomVerticalDragDetector(
            onStart: (_) {
              //iOS 在长按公屏头像的时候，会触发键盘隐藏；然后往输入框插入文字，如果键盘隐藏动画还没有结束就无法再弹起来
              //Android 原逻辑没有问题，先不改动
              if (!UniversalPlatform.isIOS) FocusScope.of(context).unfocus();
            },
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (notification) {
                /// TO DO 升级flutter版本之后，可以通过keyboardDismissBehavior属性来控制键盘的隐藏
                // 监听scrollview滚动隐藏键盘
                final FocusScopeNode focusScope = FocusScope.of(context);
                if (UniversalPlatform.isIOS &&
                    notification.dragDetails != null &&
                    focusScope.hasFocus) {
                  focusScope.unfocus();

                  ///FocusScope.of(context).unfocus()
                  ///以上方法，在某些时候无法让UIKitView中的TextInput失去焦点
                  ///flutter新版中可以验证下，然后删除以下代码
                  FbUtils.hideKeyboard();
                }

                if (notification.metrics is FixedScrollMetrics) {
                  chatViewScrollState = (notification.metrics.pixels ==
                              notification.metrics.maxScrollExtent ||
                          notification.metrics.pixels ==
                              TextChatViewBottomPadding)
                      ? ChatViewScrollState.scrollEnd
                      : ChatViewScrollState.scrollOffset;
                  if (kDefaultOverScrollOffset == 36) {
                    chatViewOffset = notification.metrics.pixels -
                        notification.metrics.maxScrollExtent +
                        kDefaultOverScrollOffset;
                  } else {
                    chatViewOffset = notification.metrics.pixels -
                        notification.metrics.minScrollExtent -
                        kDefaultOverScrollOffset;
                  }
                }
                return false;
              },
              child: FBScrollbar(
                  child: ProxyIndexList(
                // ignore: avoid_redundant_argument_values
                physics: kIsWeb ? null : const SlowListPhysics(),
                padding: const EdgeInsets.only(top: 24),
                key: model.listKey,
                initialIndex: initialScrollIndex,
                initialAlignment: initialAlignment,
                initialOffset: chatViewOffset,
                controller: proxyController,
                indexListener: proxyListener,
                itemCount: listItemCount,
                builder: (context, index) {
                  if (index == 0) {
                    if (list.isNotEmpty && list.first.content is StartEntity) {
                      return sizedBox;
                    } else {
                      if (model.canReadHistory) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: CupertinoActivityIndicator.partiallyRevealed(),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                              "╮(╯▽╰)╭当前暂无查看该频道历史消息的权限，历史消息在退出App后自动清空".tr),
                        );
                      }
                    }
                  }

                  /// 列表的倒数第三个元素是底部 padding
                  /// List.padding 不能在跳转到底部时包含这个边距
                  if (index == itemCount - 1) {
                    /// TODO 随着 List 版本的更新，可能修复了这个 BUG，可以使用 List.padding 代替
                    return BottomLoadingView(model.channelId);
                  }

                  /// 列表最后两个元素是空元素，用来避免跳转时的 UI 跳动
                  /// TODO 随着 List 版本的更新，可能修复了这个 BUG，可以试着去掉这个做法
                  if (index >= itemCount) {
                    return const SizedBox(
                      height: 1,
                      width: 1,
                    );
                  }
                  index -= 1;

                  Widget top;

                  final current = list[index];
                  final previous = index >= 1 ? list[index - 1] : null;
                  final next = index + 1 < list.length ? list[index + 1] : null;

                  if (current.content is StartEntity) {
                    return TextChatUICreator.createStartItem(
                        context, widget.model.channel);
                  } else if (current.content is AddFriendTipsEntity) {
                    return AddFriendTipsItem(entity: current.content);
                  }

                  // 判断是否为隐身消息
                  if (!MessageUtil.canISeeThisMessage(current)) {
                    /// 如果没有高度，会导致视口内的 index 计算错误
                    return const SizedBox(height: 1);
                  }

                  // 判断是否被时间戳分隔了，如果显示时间戳，即时是同一个用户说的话，也需要显示头像、名字等信息
                  bool shouldShowUserInfo;
                  if (current.content is WelcomeEntity) {
                    shouldShowUserInfo = false;
                  } else {
                    shouldShowUserInfo =
                        MessageEntityExtension.shouldShowUserInfo(
                            previous, current, next,
                            underNewMessageSeparator:
                                model.newMessagePosition > 0 &&
                                    index ==
                                        list.length - model.newMessagePosition);
                    if (shouldShowUserInfo) top = const SizedBox(height: 16);
                  }

                  final Widget child = TextChatUICreator.createItem(
                    context,
                    index,
                    list,
                    guidId: widget.model.guildId,
                    createQuote: current.deleted == 0,
                    shouldShowUserInfo: shouldShowUserInfo,
                    refererChannelSource: RefererChannelSource.ChatMainPage,
                    padding: current.content is WelcomeEntity
                        ? const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8)
                        : EdgeInsets.only(
                            left: shouldShowUserInfo ? 0 : 56,
                            top: 4,
                            bottom: 4),
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      if (current.quoteL1 != null && !current.isRecalled) {
                        final m = await MessageUtil.getMessage(
                            current.quoteL1, current.channelId);
                        await Routes.pushTopicPage(context, m,
                            gotoMessageId: current.messageId);
                      } else if (OrientationUtil.portrait) {
                        if (!current.isNormal) return;
                        setState(() {
                          if (shouldShowReplyButton(current))
                            replyMessage(context, current);
                          else
                            selectedMessage = current;
                        });
                      }
                    },
                    onOpenMenu: () => _showItemContextMenu = true,
                    onCloseMenu: () => _showItemContextMenu = false,
                    onUnFold: (string) {
                      if (!_unFoldMessageList.contains(string)) {
                        _unFoldMessageList.add(string);
                      }
                    },
                    isUnFold: _unFoldMessageList.contains,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (current.messageIdBigInt ==
                          topRightButtonController.firstUnreadId)
                        TextChatUICreator.newMessageDivider(),

                      /// 自然日不同时，显示时间分割线
                      if (previous != null &&
                          (previous.time.day != current.time.day ||
                              previous.time.month != current.time.month ||
                              previous.time.year != current.time.year))
                        _buildTimeSeparator(
                            current, previous.time.year != current.time.year),

                      if (top != null) top,
                      child,
                      Visibility(
                          visible: shouldShowReplyButton(current),
                          child: GestureDetector(
                            onTap: () {
                              replyMessage(context, current);
                              setState(() {
                                selectedMessage = null;
                              });
                            },
                            child: const ReplyButton(),
                          )),
                    ],
                  );
                },
              )),
            ),
          ));
    });
  }

  bool shouldShowReplyButton(MessageEntity<MessageContentEntity> msg) {
    if (msg.content is RichTextEntity) {
      final richText = msg.content as RichTextEntity;
      // 富文本包含链接不显示回复按钮
      if (richText.document.toDelta().toList().any(
          (e) => e.attributes != null && e.attributes.containsKey("link"))) {
        return false;
      }
    }
    return selectedMessage == msg && MessageTools.canReply(message: msg);
  }

  Widget _buildTimeSeparator(MessageEntity item, bool crossYear) {
    final timeString =
        MessageEntityExtension.buildTimeSeparator(item, crossYear);

    return Container(
      height: 32,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      const Color(0xFFD4D5D6).withOpacity(0.5),
                      Colors.white
                    ],
                  ),
                )),
          ),
          sizeWidth12,
          Text(
            timeString,
            style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 12),
          ),
          sizeWidth12,
          Expanded(
            child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFD4D5D6).withOpacity(0.5),
                      Colors.white
                    ],
                  ),
                )),
          ),
        ],
      ),
    );
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

  Widget _robotCmdsList() {
    return OrientationUtil.portrait
        ? Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: 0,
            child: RobotCmdsPopupList(
              channelId: widget.model.channelId,
              controller: _cmdController,
            ),
          )
        : Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LandscapeRobotCmdsPopupList(widget.model.channelId),
          );
  }

  void _onWindowChange(_) {
    if (kIsWeb) return;

    ///GlobalState.selectedChannel 的赋值比 widget.model.channel 快
    ///如果不相等，则返回 (修复：切换频道后，清零了旧频道的未读数)
    /// todo 未来改成引用对比
    if (GlobalState.selectedChannel.value?.id != widget.model.channelId) {
      return;
    }
    if (HomeScaffoldController.to.canChatWindowVisible) {
      ///点击或滑入 进入聊天页面,upLastRead 立即上报模式
      _updateBottomButton(isSync: true, isUpNow: true);
    } else {
      widget.model.newMessagePosition = 0;
      ChannelUtil.instance.upLastReadSend();
    }
  }

  Widget _addFriendTips() {
    final String userId =
        widget.model.channel?.recipientId ?? widget.model.channel?.guildId;
    return GetBuilder<FriendListPageController>(
      builder: (controller) {
        if (controller.isMyFriend(userId) || controller.isBot(userId)) {
          return const SizedBox();
        } else {
          return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(
                  '添加好友，可以随时与Ta聊天'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                RelationUtils.consumer(userId,
                    builder: (context, type, widget) {
                  String title = '';
                  Color color;
                  final bool isInBlacklist =
                      controller.blackListIsContain(userId);

                  //屏蔽对方后，解除屏蔽优先于好友申请操作
                  if (isInBlacklist) {
                    title = "解除屏蔽".tr;
                    color = redTextColor;
                  } else {
                    switch (type) {
                      case RelationType.pendingOutgoing:
                        title = '待通过'.tr;
                        color = goldColor;
                        break;
                      case RelationType.pendingIncoming:
                        title = '待接受'.tr;
                        color = goldColor;
                        break;
                      case RelationType.friend:
                        //do nothing
                        break;
                      default:
                        title = '添加好友'.tr;
                        color = Colors.blue;
                        break;
                    }
                  }

                  return GestureDetector(
                    onTap: () {
                      //屏蔽对方后，解除屏蔽优先于好友申请操作
                      if (isInBlacklist) {
                        controller.removeFromBlackList(userId);
                      } else {
                        if (type == RelationType.pendingIncoming) {
                          //待通过
                          FriendApplyPageController.to.agree(
                            userId,
                            isShowToast: true,
                          );
                        } else if (type == RelationType.friend ||
                            type == RelationType.pendingOutgoing) {
                          //已经是好友和待接受
                          //do nothing
                        } else {
                          //添加好友
                          FriendApplyPageController.to.apply(userId);
                        }
                      }
                    },
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 14, color: color),
                    ),
                  );
                }),
              ],
            ),
          );
        }
      },
    );
  }
}

class ReplyButton extends StatelessWidget {
  const ReplyButton();

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left: 56),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5.5),
        decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WebsafeSvg.asset(
              "assets/svg/huifu.svg",
              color: Get.theme.primaryColor,
              width: 12,
              height: 12,
            ),
            const SizedBox(width: 5),
            Text(
              "回复TA".tr,
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1),
              style: TextStyle(fontSize: 12, color: primaryColor),
            ),
          ],
        ));
  }
}
