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

/// - ????????????
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

  // ??????????????????????????????
  double chatViewOffset = TextChatViewBottomPadding;
  double kDefaultOverScrollOffset = 36;
  ChatViewScrollState chatViewScrollState = ChatViewScrollState.none;

  ///??????????????? Controller
  BottomRightButtonController bottomRightButtonController;

  ///??????????????? Controller
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
    // ???????????????model????????????????????????????????????????????????????????????
    inputModel.robotCmdListener = displayedCmdsModel;

    bottomRightButtonController = BottomRightButtonController.to(channelId);
    topRightButtonController = TopRightButtonController.to(channelId);

    /// ?????????????????????????????????????????????????????????????????????????????????????????????????????? n ????????????
    /// ????????????????????????????????????????????????????????????
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
            //return;//????????????????????????????????????
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
          ///ios??????????????????????????????fanbook????????????
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
      // TODO ???????????????
      /// Web ???????????????????????????????????????itemTrailingEdge????????????????????????????????????????????????index == 0?????????????????????????????????
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

    /// web??????????????????????????????????????????????????????????????????????????????????????????top right???????????????web????????????????????????????????????
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
      // ??????????????????
      SoundPlayManager().stop();
    }
  }

  ///????????????????????? ??????????????????????????????
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
      //target == null ??????????????????????????????????????????
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
          AtList(), // ???, // ??? ???@ ??????
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: GifSearchView(inputModel.channelId),
        ),

        /// ?????????????????????????????????????????????????????????, ???????????????????????????????????????
        if (ChatTargetsModel.instance.selectedChatTarget is GuildTarget &&
            ![ChatChannelType.dm, ChatChannelType.group_dm]
                .contains(widget.model.channel.type))
          ChangeNotifierProvider(
            create: (_) => ChannelSelectorModel(inputModel: inputModel),
            builder: (_, child) => ChannelSelectorView(),
          ),

        // ArticlePicker(), // link ??????
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
              "??????????????????????????????????????????".tr,
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
                    showToast("???????????????".tr);
                  } else {
                    showToast("??????????????????".tr);
                  }
                },
                child: Text('????????????'.tr,
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
                                                      "%s ????????????".trArgs([""]),
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
        logger.warning("??????????????????????????????");
      }
    }

    // TODO ???????????????????????????????????????????????????????????????????????? loading ?????????
    // if (model.channelId == JPushUtil.launchParametersChannelId) {
    //   // ?????????????????????????????????????????????????????????????????????????????????loading??????
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
              //iOS ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
              //Android ????????????????????????????????????
              if (!UniversalPlatform.isIOS) FocusScope.of(context).unfocus();
            },
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (notification) {
                /// TO DO ??????flutter???????????????????????????keyboardDismissBehavior??????????????????????????????
                // ??????scrollview??????????????????
                final FocusScopeNode focusScope = FocusScope.of(context);
                if (UniversalPlatform.isIOS &&
                    notification.dragDetails != null &&
                    focusScope.hasFocus) {
                  focusScope.unfocus();

                  ///FocusScope.of(context).unfocus()
                  ///???????????????????????????????????????UIKitView??????TextInput????????????
                  ///flutter???????????????????????????????????????????????????
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
                              "???(?????????)???????????????????????????????????????????????????????????????????????????App???????????????".tr),
                        );
                      }
                    }
                  }

                  /// ??????????????????????????????????????? padding
                  /// List.padding ?????????????????????????????????????????????
                  if (index == itemCount - 1) {
                    /// TODO ?????? List ??????????????????????????????????????? BUG??????????????? List.padding ??????
                    return BottomLoadingView(model.channelId);
                  }

                  /// ??????????????????????????????????????????????????????????????? UI ??????
                  /// TODO ?????? List ??????????????????????????????????????? BUG?????????????????????????????????
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

                  // ???????????????????????????
                  if (!MessageUtil.canISeeThisMessage(current)) {
                    /// ?????????????????????????????????????????? index ????????????
                    return const SizedBox(height: 1);
                  }

                  // ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
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

                      /// ??????????????????????????????????????????
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
      // ??????????????????????????????????????????
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
    // ????????????
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

    ///GlobalState.selectedChannel ???????????? widget.model.channel ???
    ///??????????????????????????? (?????????????????????????????????????????????????????????)
    /// todo ????????????????????????
    if (GlobalState.selectedChannel.value?.id != widget.model.channelId) {
      return;
    }
    if (HomeScaffoldController.to.canChatWindowVisible) {
      ///??????????????? ??????????????????,upLastRead ??????????????????
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
                  '??????????????????????????????Ta??????'.tr,
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

                  //?????????????????????????????????????????????????????????
                  if (isInBlacklist) {
                    title = "????????????".tr;
                    color = redTextColor;
                  } else {
                    switch (type) {
                      case RelationType.pendingOutgoing:
                        title = '?????????'.tr;
                        color = goldColor;
                        break;
                      case RelationType.pendingIncoming:
                        title = '?????????'.tr;
                        color = goldColor;
                        break;
                      case RelationType.friend:
                        //do nothing
                        break;
                      default:
                        title = '????????????'.tr;
                        color = Colors.blue;
                        break;
                    }
                  }

                  return GestureDetector(
                    onTap: () {
                      //?????????????????????????????????????????????????????????
                      if (isInBlacklist) {
                        controller.removeFromBlackList(userId);
                      } else {
                        if (type == RelationType.pendingIncoming) {
                          //?????????
                          FriendApplyPageController.to.agree(
                            userId,
                            isShowToast: true,
                          );
                        } else if (type == RelationType.friend ||
                            type == RelationType.pendingOutgoing) {
                          //???????????????????????????
                          //do nothing
                        } else {
                          //????????????
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
              "??????TA".tr,
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1),
              style: TextStyle(fontSize: 12, color: primaryColor),
            ),
          ],
        ));
  }
}
