import 'dart:async';
import 'dart:math';

import 'package:fb_utils/fb_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/circle_post_data_model.dart';
import 'package:im/app/modules/circle/models/circle_post_like_list_data_model.dart';
import 'package:im/app/modules/circle/views/portrait/widgets/custom_tabbar_indicator.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_util.dart';
import 'package:im/app/modules/circle_detail/entity/circle_detail_message.dart';
import 'package:im/app/modules/circle_detail/factory/abstract_circle_detail_factory.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_detail_empty_comment.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_detail_reload_layout.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/widgets/fb_scrollbar.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/common.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/input_prompt/at_selector_model.dart';
import 'package:im/pages/home/view/bottom_bar/at_list_base.dart';
import 'package:im/pages/home/view/bottom_bar/im_bottom_bar.dart';
import 'package:im/pages/home/view/record_view/record_sound_state.dart';
import 'package:im/pages/home/view/text_chat/message_tools.dart';
import 'package:im/pages/home/view/text_chat/show_message_tooltip.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/pages/home/view/text_chat_view.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/list_view/position_list_view/src/positioned_list.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/scroll_physics.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' as refresh;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rxdart/rxdart.dart' show DebounceExtensions;

class CircleVideoComment extends StatefulWidget {
  const CircleVideoComment(this._model, this._commentTotalCallback, {key})
      : super(key: key);
  final CirclePostDataModel _model;

  /// * 回复总数更新
  final Function _commentTotalCallback;

  @override
  _CircleVideoCommentState createState() => _CircleVideoCommentState();
}

class _CircleVideoCommentState extends State<CircleVideoComment> {
  InputModel inputModel;
  CircleDetailController c;

  /// 点赞列表model
  CirclePostLikeListDataModel _postLikeListDataModel;
  RequestType requestType = RequestType.normal;
  refresh.RefreshController _refreshController;

  String get postId => widget._model?.postInfoDataModel?.postId;

  CommentMessageEntity selectedMessage;

  @override
  void initState() {
    _postLikeListDataModel =
        CirclePostLikeListDataModel(postId: postId, recordsDataModelList: []);
    _refreshController = refresh.RefreshController();
    super.initState();
    loadLikeList();
  }

  @override
  void dispose() {
    _refreshController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CircleDetailController>(
      init: CircleDetailController(
        CircleDetailData(widget._model),
        videoTag: CircleDetailController.VideoTag,
      ),
      tag: '$postId${CircleDetailController.VideoTag}',
      dispose: (state) {
        _refreshComment(state.controller);
        removeScrollListener();
        inputModel?.dispose();
      },
      builder: (controller) => GestureDetector(
        onTap: () => FocusScope.of(context)?.unfocus(),
        child: Container(
          height: Get.size.height * .85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10),
              topLeft: Radius.circular(10),
            ),
          ),
          child: () {
            if (c == null) {
              c = controller;
              addScrollListener();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  tabs: _tabs(controller),
                  padding: const EdgeInsets.only(bottom: 1),
                  labelColor: appThemeData.textTheme.bodyText2.color,
                  unselectedLabelColor: appThemeData.textTheme.headline2.color,
                  controller: controller.tabController,
                  isScrollable: true,
                  labelPadding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w400, fontSize: 14),
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14),
                  indicator: MyUnderlineTabIndicator(
                    borderSide: BorderSide(width: 2, color: primaryColor),
                  ),
                  onTap: (_) {
                    inputModel?.textFieldFocusNode?.unfocus();
                  },
                ),
                divider,
                Expanded(
                  child: TabBarView(
                    controller: c.tabController,
                    physics: const TabViewScrollPhysics(),
                    children: [
                      getReplyTab(c),
                      getLikeTab(c),
                    ],
                  ),
                ),
              ],
            );
          }(),
        ),
      ),
    );
  }

  List<Widget> _tabs(CircleDetailController controller) {
    return [
      Tab(text: '回复 %s'.trArgs([controller.totalReplyNum])),
      Tab(text: '点赞 %s'.trArgs([controller.totalLikes])),
    ];
  }

  /// * 回复列表tab
  Widget getReplyTab(CircleDetailController controller) {
    widget?._commentTotalCallback(controller.totalReplyNum);
    if (controller.initialing) return buildLoadingWidget(Get.context);
    if (controller.initialError) {
      if (postIsDelete(controller.requestCode))
        return buildEmptyLayout(Get.context);
      else
        return CircleDetailReloadLayout(
          onPressed: () async {
            await controller.refreshAll();
          },
        );
    }

    if (inputModel == null) {
      inputModel = InputModel(
        channelId: controller.channelId,
        guildId: controller.guildId,
        type: ChatChannelType.guildCircle,
      );
      inputModel.contentChangeStream
          .debounceTime(const Duration(seconds: 1))
          .listen((value) {
        CircleDetailUtil.updateInputRecord(
            controller.postId, inputModel.reply?.messageId, value);
      });
      Future.delayed(500.milliseconds).then((_) {
        //打开回复列表后，自动弹起键盘
        if (mounted) inputModel?.textFieldFocusNode?.requestFocus();
      });
    }
    final channel = controller.channel;
    return WillPopScope(
      onWillPop: () {
        closeToolTip();
        return Future.value(true);
      },
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: inputModel),
          ChangeNotifierProvider<AtSelectorModel>(
              create: (_) => AtSelectorModel(inputModel, channel)),
          ChangeNotifierProvider.value(value: RecordSoundState()),
        ],
        child: Column(
          children: [
            Expanded(
              child: _commentList(controller),
            ),
            if (channel?.id != null)
              ImBottomBar(
                channel,
                key: controller.inputKey,
              ),
          ],
        ),
      ),
    );
  }

  void loadLikeList() {
    _postLikeListDataModel.initFromNet(isDesc: false).then((value) {
      if (mounted) setState(() {});
    });
  }

  /// * 点赞列表tab
  Widget getLikeTab(CircleDetailController controller) {
    return refresh.SmartRefresher(
      controller: _refreshController,
      enablePullUp: true,
      enablePullDown: false,
      footer: CustomFooter(
        height: 58,
        builder: (context, mode) {
          return footBuilder(context, mode,
              requestType: requestType, showDivider: false);
        },
      ),
      onLoading: () {
        requestType = RequestType.normal;
        _postLikeListDataModel
            .needMorePost(isDesc: false)
            .then((value) => setState(() {}))
            .whenComplete(_refreshController.loadComplete)
            .catchError((error) {
          if (Http.isNetworkError(error))
            requestType = RequestType.netError;
          else
            requestType = RequestType.dataError;
          _refreshController.loadFailed();
        });
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
        itemBuilder: (context, index) {
          final dataModel =
              _postLikeListDataModel.postListDetailDataModelAtIndex(index);
          return SizedBox(
            height: 52,
            child: Row(
              children: [
                RealtimeAvatar(
                  userId: dataModel.userId,
                  guildId: controller.guildId,
                  size: 32,
                  tapToShowUserInfo: true,
                  enterType: EnterType.fromCircle,
                ),
                sizeWidth10,
                RealtimeNickname(
                  userId: dataModel.userId,
                  style: appThemeData.textTheme.bodyText1,
                  showNameRule: ShowNameRule.remarkAndGuild,
                  guildId: controller.guildId,
                ),
              ],
            ),
          );
        },
        itemCount: _postLikeListDataModel.postLikeListCount,
      ),
    );
  }

  void _refreshComment(CircleDetailController controller) {
    if (controller.needRefreshWhenPop) {
      Future(() {
        if (Get.isRegistered<CircleController>()) {
          CircleController.to.updateItem(
              widget._model.postInfoDataModel.topicId, widget._model);
        }
      });
    }
  }

  /// * 加载进度 或 回复为空
  Widget _commentStatusWidget(CircleDetailController controller) {
    final isFloorsEmpty = controller.replyListIsEmpty;
    final initialLoading =
        controller.initialing || (controller.isLoading && isFloorsEmpty);
    final loadingError = controller.initialError;
    Widget keepHeight(Widget child) => SizedBox(height: 300, child: child);
    if (initialLoading)
      return keepHeight(
        buildLoadingWidget(Get.context),
      );
    if (isFloorsEmpty && !loadingError)
      return keepHeight(
        const CircleDetailEmptyComment(),
      );
    return sizedBox;
  }

  /// * 回复列表
  Widget _commentList(CircleDetailController controller) {
    return Stack(children: <Widget>[
      NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          final FocusScopeNode focusScope = FocusScope.of(context);
          if (notification.dragDetails != null && focusScope.hasFocus) {
            focusScope.unfocus();
            FbUtils.hideKeyboard();
          }
          return false;
        },
        child: !controller.replyListIsEmpty
            ? LayoutBuilder(builder: (context, constraints) {
                controller.updateListViewDimension(constraints.maxHeight);

                return FBScrollbar(
                  child: PositionedList(
                    padding: const EdgeInsets.only(top: 2),
                    key: controller.listKey,
                    positionedIndex:
                        min(controller.initialIndex, controller.itemCount - 1),
                    alignment: controller.initialAlignment,
                    controller: controller.scrollController,
                    itemCount: controller.itemCount,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return SizedBox(
                          key: controller.topUiKey,
                          child: AbstractCircleDetailFactory.instance
                              .buildListTopLoading(controller),
                        );
                      } else if (index == controller.itemCount - 1) {
                        return SizedBox(key: controller.bottomUiKey);
                      } else {
                        return _replyItem(
                            controller, index - controller.headerSize, context);
                      }
                    },
                  ),
                );
              })
            : ListView(children: [_commentStatusWidget(controller)]),
      ),
      AtList(),
    ]);
  }

  /// * 单个回复
  Widget _replyItem(
      CircleDetailController controller, int index, BuildContext context) {
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

  ///是否显示'回复Ta'按钮
  bool shouldShowReplyButton(CommentMessageEntity msg) {
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

  void addScrollListener() {
    c?.itemPositionsNotifier?.itemPositions?.addListener(_onScroll);
  }

  void removeScrollListener() {
    c?.itemPositionsNotifier?.itemPositions?.removeListener(_onScroll);
  }

  ///监听列表滚动
  void _onScroll() {
    if (c == null || c.isLoading || c.replyListIsEmpty) return;
    final positions = c?.itemPositionsNotifier?.itemPositions?.value
        ?.where((position) => position.itemLeadingEdge < 1);
    if (positions.isEmpty) return;

    final topIndex = positions
        .where((position) => position.itemTrailingEdge > 0)
        .reduce((minValue, position) {
      return position.itemTrailingEdge < minValue.itemTrailingEdge
          ? position
          : minValue;
    }).index;
    // print('getChat onScroll: $topIndex - $bottomIndex, $numBottomInvisible');
    /// 滚动到顶部
    if (!c.reachStart && topIndex <= (c.headerSize - 1)) {
      //加载上一页
      c.loadList();
    }
  }
}
