import 'dart:async';
import 'dart:math';

import 'package:fanbook_circle_detail_list/fanbook_circle_detail_list.dart';
import 'package:fb_utils/fb_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app.dart';
import 'package:im/app/modules/circle/views/widgets/loading_indicator.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_util.dart';
import 'package:im/app/modules/circle_detail/entity/circle_detail_message.dart';
import 'package:im/app/modules/circle_detail/factory/abstract_circle_detail_factory.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_detail_comment_total_replay.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_detail_reload_layout.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/fb_scrollbar.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/common.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/position_button.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/input_prompt/at_selector_model.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/home/view/bottom_bar/at_list_base.dart';
import 'package:im/pages/home/view/bottom_bar/im_bottom_bar.dart';
import 'package:im/pages/home/view/content_loading.dart';
import 'package:im/pages/home/view/record_view/record_sound_state.dart';
import 'package:im/pages/home/view/text_chat/message_tools.dart';
import 'package:im/pages/home/view/text_chat/show_message_tooltip.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/pages/home/view/text_chat_view.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/gesture/custom_vertical_drag_detector.dart';
import 'package:im/widgets/scroll_physics.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart' show DebounceExtensions;

import '../controllers/circle_detail_controller.dart';

/// * ???????????????
// ignore: must_be_immutable
class CircleDetailView extends StatefulWidget {
  CircleDetailData paramData;

  CircleDetailView({this.paramData});

  @override
  _CircleDetailViewState createState() => _CircleDetailViewState();
}

class _CircleDetailViewState extends State<CircleDetailView> {
  CircleDetailData paramData;

  CircleDetailController controller;
  InputModel inputModel;

  String get guildId => controller?.guildId;

  String get channelId => controller?.channelId;

  String get topicId => controller?.topicId;

  String get postId => controller?.postId;

  ChatChannel get channel => controller?.channel;

  // ????????????????????????
  bool _showItemContextMenu = false;

  StreamSubscription _newMessageSubscription;
  StreamSubscription<bool> _keyboardSubscription;

  CommentMessageEntity selectedMessage;

  //????????????????????????
  CommentMessageEntity showTipMessage;

  //??????????????????item???key
  GlobalKey showTipKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    paramData = widget.paramData ?? Get.arguments;
    controller = CircleDetailController.to(postId: paramData.postId);
    inputModel = InputModel(
      channelId: topicId,
      guildId: guildId,
      type: ChatChannelType.guildCircle,
    );
    inputModel.contentChangeStream
        .debounceTime(const Duration(seconds: 1))
        .listen((value) {
      CircleDetailUtil.updateInputRecord(
          postId, inputModel.reply?.messageId, value);
    });
    addScrollListener();
    _newMessageSubscription = controller.eventStream.listen((event) {
      if (event is NewMessageEvent) {
        bool canJumpToBottom = false;
        if (event.force) {
          canJumpToBottom = true;
        } else {
          canJumpToBottom = !controller.replyListIsEmpty &&
              controller.numBottomInvisible != null &&
              controller.numBottomInvisible <= 1;
        }
        if (canJumpToBottom && !_showItemContextMenu) {
          if (App.appLifecycleState == AppLifecycleState.resumed) {
            controller.brController?.isSelfJumpBottom = true;
            controller.jumpToBottom(delay: 200.milliseconds);
            controller.clearUnread(upNow: false);
          }
        }
      }
    });
    if (UniversalPlatform.isAndroid) {
      _keyboardSubscription =
          KeyboardVisibilityController().onChange.listen((visible) {
        //android??????????????????????????????????????????onFocusChange?????????????????????????????????
        if (visible) {
          showLayer();
        } else {
          //???????????????????????????????????????????????????????????????????????????
          Future.delayed(300.milliseconds).then((_) {
            try {
              final bottom = Get.mediaQuery.viewInsets.bottom;
              final inputBottom =
                  controller.inputKey.currentContext.size.height;
              if (bottom < 100 && inputBottom < 200) hideLayer();
            } catch (_) {
              hideLayer();
            }
          });
        }
      });
    }
  }

  void addScrollListener() {
    controller.itemPositionsNotifier.itemPositions?.addListener(_onScroll);
  }

  void removeScrollListener() {
    controller.itemPositionsNotifier.itemPositions?.removeListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CircleDetailController>(
        tag: paramData.postId,
        dispose: (state) => closeToolTip(),
        builder: (c) {
          return Scaffold(
            backgroundColor: Get.theme.backgroundColor,
            resizeToAvoidBottomInset: false,
            appBar: AbstractCircleDetailFactory.instance
                .showAppBar(c, context: context),
            body: GestureDetector(
              onTap: () => FocusScope.of(context)?.unfocus(),
              child: _buildBody(context),
            ),
          );
        });
  }

  Widget _buildBody(BuildContext context) {
    // final isLoading = controller.initialLoading && controller.extraData != null;
    final postDeleted = postIsDelete(controller.requestCode);
    final initialError = controller.initialError;
    // if (isLoading) return buildLoadingWidget(Get.context);
    //????????????????????????????????????????????????
    if (initialError && postDeleted) return buildEmptyLayout(Get.context);
    if (initialError &&
        (controller.fromDmList || controller.fromPush) &&
        !postDeleted) return _buildReloadLayout;

    //topicId?????????????????????,????????????
    if (inputModel.channelId.noValue) inputModel.channelId = topicId;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: inputModel),
        ChangeNotifierProvider<AtSelectorModel>(
            create: (_) => AtSelectorModel(inputModel, channel)),
        ChangeNotifierProvider.value(value: RecordSoundState()),
      ],
      child: Column(
        children: [
          Expanded(child: _buildContentLayout()),
          ObxValue((v) {
            if (v?.value ?? false)
              return _inputLoadingView();
            else
              return ImBottomBar(
                channel,
                key: controller.inputKey,
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    showLayer();
                  } else {
                    hideLayer();
                  }
                },
              );
          }, controller.showLoading),
        ],
      ),
    );
  }

  /// * ??????????????????????????????view
  Widget get _buildReloadLayout => CircleDetailReloadLayout(
        onPressed: () async {
          await controller.refreshAll(showLoadingStatus: true);
        },
      );

  /// * ????????????????????????????????????
  Widget _buildContentLayout() {
    return Stack(children: <Widget>[
      Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (notification) {
                final FocusScopeNode focusScope = FocusScope.of(context);
                if (UniversalPlatform.isIOS &&
                    notification.dragDetails != null &&
                    focusScope.hasFocus) {
                  focusScope.unfocus();
                  //??????????????????????????????????????????UIKitView??????TextInput????????????
                  FbUtils.hideKeyboard();
                }
                return false;
              },
              child: _buildList(),
            ),
          ),
        ],
      ),
      AtList(),
      Positioned(
          top: 100, right: 0, child: TopPositionButton(controller.postId)),
      Positioned(
          bottom: 1, right: 0, child: BottomPositionButton(controller.postId)),
      ObxValue((v) {
        // ???????????????
        if (v?.value ?? false)
          return Container(
            constraints: const BoxConstraints.expand(),
            alignment: Alignment.center,
            color: appThemeData.backgroundColor,
            child: const ContentLoadingView(),
          );
        else
          return sizedBox;
      }, controller.showLoading),
    ]);
  }

  /// * ????????????????????????????????????
  Widget _buildList() {
    // print("rebuild circle detail list with key ${controller.listKey.value}, initialIndex ${controller.initialIndex}, alignment ${controller.initialAlignment}");
    final childView =
        FBScrollbar(child: LayoutBuilder(builder: (context, constraints) {
      controller.updateListViewDimension(constraints.maxHeight);

      return FanbookCircleDetailList(
        physics: const CircleDetailScrollPhysics(),
        padding: const EdgeInsets.only(top: 2),
        key: controller.listKey,
        controller: controller.scrollController,
        emptyReplyWidget: controller.replyListIsEmpty
            ? SizedBox(key: controller.bottomUiKey, child: _buildEmpty())
            : null,
        initialIndex: min(controller.initialIndex, controller.itemCount - 1),
        alignment: controller.initialAlignment,
        onUnderscroll: controller.loadList,
        itemPositionsNotifier: controller.itemPositionsNotifier,
        replyItemCount: controller.itemCount,
        replyItemBuilder: _buildItem,
        pinItemHeight: 40,
        buildPinItem: controller.replyListIsEmpty ? null : _buildCommentHeader,
        pinNotifier: controller.pinNotifier,
        detailWidget: _buildHeadFloor(),
      );
    }));

    return CustomVerticalDragDetector(
      onStart: (_) {
        //iOS ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
        if (!UniversalPlatform.isIOS) FocusScope.of(context).unfocus();
      },
      child: childView,
    );
  }

  /// * listIsCommon???
  /// - true: index???0???1, 2????????????????????????????????????????????????
  /// - false: index???0???1, 2???????????? sizedBox???sizedBox?????????
  Widget _buildItem(BuildContext context, int index) {
    // debugPrint('getChat -> index: $index');
    if (index == 0) {
      return _buildListTopLoading();
    } else if (index == controller.itemCount - 1) {
      /// ?????????????????????
      return _buildListBottomLoading();
    } else {
      final item = _replyItem(index - controller.headerSize, context);
      final current = controller.replyList[index - controller.headerSize];
      if (showTipMessage?.commentId == current.commentId) {
        // ?????????????????????????????????????????????????????????????????????:
        // ?????????????????????????????????????????????showMessageTooltip?????????
        showTipMessage = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (showTipKey.currentContext != null) {
            showMessageTooltip(
              showTipKey.currentContext,
              message: current,
              reply: () => replyMessage(context, current),
            );
          }
        });
        return Builder(key: showTipKey, builder: (c) => item);
      }
      return item;
    }
  }

  /// * ????????????
  Widget _replyItem(int index, BuildContext context) {
    final current = controller.replyList[index];
    final child = TextChatUICreator.createItem(
      context,
      index,
      controller.replyList,
      guidId: controller.guildId,
      shouldShowUserInfo: true,
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          if (shouldShowReplyButton(current))
            replyMessage(context, current);
          else
            selectedMessage = current;
        });
      },
      onOpenMenu: () => _showItemContextMenu = true,
      onCloseMenu: () => _showItemContextMenu = false,
      showTipErrorCallback: () {
        setState(() {
          showTipMessage = current;
        });
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
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
  }

  ///????????????'??????Ta'??????
  bool shouldShowReplyButton(CommentMessageEntity msg) {
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

  ///??????????????????
  void _onScroll() {
    if (controller.isLoading || controller.replyListIsEmpty) return;

    final positions = controller.itemPositionsNotifier.itemPositions.value
        ?.where((position) => position.itemLeadingEdge < 1);
    if (positions.isEmpty) return;

    int topIndex, bottomIndex;

    try {
      topIndex = positions
          .where((position) => position.itemTrailingEdge > 0)
          .reduce((minValue, position) {
        return position.itemTrailingEdge < minValue.itemTrailingEdge
            ? position
            : minValue;
      }).index;

      bottomIndex = positions
          .where((position) => position.itemLeadingEdge < 1)
          .reduce((max, position) =>
              position.itemLeadingEdge > max.itemLeadingEdge ? position : max)
          .index;
    } catch (e) {
      // where ?????????????????????reduce ????????????????????? return ??????
      return;
    }

    final headerSize = controller.headerSize;

    controller.topIndex = max(0, topIndex - headerSize);
    if (bottomIndex < headerSize) {
      controller.bottomIndex = null;
    } else {
      controller.bottomIndex =
          max(0, min(controller.replySize - 1, bottomIndex - headerSize));
    }

    final numBottomInvisible = controller.itemCount - 1 - bottomIndex;
    controller.numBottomInvisible = numBottomInvisible;
    if (!controller.isUpdateByScroll) return;

    /// ???????????????
    if (numBottomInvisible <= 0 &&
        !controller.reachEnd &&
        controller.pinNotifier.value) {
      ///???????????????
      controller.loadList(loadMore: true);
    }

    if (controller.replyListIsEmpty) return;
    if (controller.trController.hasAt && controller.topIndex != null)
      controller.trController.updateFirstBean(
          firstComment: controller.replyList[controller.topIndex]);
    if (controller.brController.hasUnread && controller.bottomIndex != null) {
      controller.brController.updateLastBean(
          lastComment: controller.replyList[controller.bottomIndex]);
    }
  }

  Widget _buildListBottomLoading() {
    if (controller.reachEnd) return SizedBox(key: controller.bottomUiKey);
    return Padding(
      key: controller.bottomUiKey,
      padding: const EdgeInsets.all(8),
      child: const CupertinoActivityIndicator.partiallyRevealed(),
    );
  }

  Widget _buildListTopLoading() {
    if (controller.reachStart || !controller.pinNotifier.value)
      return const SizedBox();
    return const Padding(
      padding: EdgeInsets.all(8),
      child: CupertinoActivityIndicator(),
    );
  }

  ///listIsCommon???false??????????????????
  Widget _buildCommentHeader(bool pinned) => CircleDetailCommentTotalReply(
        controller.totalReplyNum,
        pinned,
        () {
          controller.reset();
          //?????????,???????????? ??? ?????????????????????
          removeScrollListener();
          FocusScope.of(context).unfocus();

          addScrollListener();
          controller.trController?.clear();
        },
      );

  Widget _buildEmpty() {
    final isFloorsEmpty = controller.replyListIsEmpty;
    final initialLoading =
        controller.initialing || (controller.isLoading && isFloorsEmpty);
    // final loadingError = controller.footerRequestType != RequestType.normal;

    if (initialLoading)
      return SizedBox(height: 300, child: buildLoadingWidget(Get.context));
    // if (isFloorsEmpty && !loadingError)
    //   return keepHeight(const CircleDetailEmptyComment());
    return sizedBox;
  }

  ///??????????????????????????????????????????????????????
  Widget _buildHeadFloor() {
    return Stack(
      key: controller.topUiKey,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AbstractCircleDetailFactory.instance.createImageVideoSwipe(
              controller,
              bottom: 2,
              onTapVideo: controller.onTapVideo,
              onLongPressImage: controller.onLongPressImage,
            ),
            AbstractCircleDetailFactory.instance
                .createArticleTitle(controller.title),
            if (controller.quillController != null)
              AbstractCircleDetailFactory.instance.createArticleRich(
                controller,
                content: controller.circleContent,
                data: controller.data,
                top: 8,
                bottom: 0,
              )
            else
              sizeHeight10,
            AbstractCircleDetailFactory.instance.createCircleDetailDocView(
                controller.data?.docItem, controller.onDocClick),
            AbstractCircleDetailFactory.instance.createAtUsers(
              controller.data,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              textStyle: appThemeData.textTheme.bodyText2.copyWith(
                  fontSize: 16,
                  color: appThemeData.dividerColor.withOpacity(1)),
            ),
            AbstractCircleDetailFactory.instance.createTimeView(
              controller.data,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              textStyle: TextStyle(
                  fontSize: 14,
                  color: appThemeData.dividerColor.withOpacity(1)),
            ),
            sizeHeight4,
            AbstractCircleDetailFactory.instance
                .createLikeView(paramData.postId),
          ],
        ),
        ObxValue((v) {
          //????????????????????????????????????
          if (v?.value ?? false)
            return Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: CircleLayerView(onTap: () {
                hideLayer(isFold: true);
              }),
            );
          else
            return sizedBox;
        }, controller.showLayer),
      ],
    );
  }

  /// * ???????????????
  Widget _inputLoadingView() {
    return Container(
      height: 92,
      color: const Color(0xFFF7F8FB),
      child: Column(
        children: [
          sizeHeight8,
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 16),
                  height: 40,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: appThemeData.backgroundColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(left: 12),
                    width: 121,
                    height: 20,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: appThemeData.dividerColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
              loadingCircle(28,
                  margin: const EdgeInsets.symmetric(horizontal: 10))
            ],
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                loadingCircle(28),
                loadingCircle(28),
                loadingCircle(28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ????????????
  void showLayer() {
    controller.showLayer.value = true;
  }

  /// ????????????
  void hideLayer({bool isFold = false}) {
    controller.showLayer.value = false;
    if (isFold) FocusScope.of(context)?.unfocus();
  }

  @override
  void dispose() {
    super.dispose();
    inputModel?.dispose();
    _newMessageSubscription?.cancel();
    _keyboardSubscription?.cancel();
    removeScrollListener();
  }
}
