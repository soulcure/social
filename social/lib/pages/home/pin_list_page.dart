import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/pin_list_model.dart';
import 'package:im/pages/home/model/stick_message_controller.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/routes.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/widgets/app_bar/web_appbar.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/refresh/refresh.dart';
import 'package:im/widgets/svg_tip_widget.dart';

class PinListPage extends StatefulWidget {
  final ChatChannel channel;

  const PinListPage({this.channel});

  @override
  _PinListPageState createState() => _PinListPageState();
}

class _PinListPageState extends State<PinListPage> {
  PinListModel _model;
  final ScrollController _scrollController = ScrollController();
  StickMessageController stickMessageController;
  TextChannelController textChannelController;

  @override
  void initState() {
    _model = PinListModel(channel: widget.channel);
    //进入pin列表后，先清除pin记录（清除外露的红点）
    _model.clearUnreadBox();
    stickMessageController =
        StickMessageController.to(channelId: widget.channel?.id);
    textChannelController =
        TextChannelController.to(channelId: widget.channel?.id);
    super.initState();
  }

  @override
  void dispose() {
    _model.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: OrientationUtil.portrait
            ? const CustomAppbar(
                title: 'Pin',
              )
            : WebAppBar(
                title: 'Pin',
                backAction: Get.back,
              ),
        body: GetBuilder<StickMessageController>(
          tag: widget.channel?.id ?? GlobalState.selectedChannel?.value?.id,
          builder: (controller) {
            return Refresher(
                model: _model,
                enableRefresh: false,
                scrollController: _scrollController,
                builder: (context) {
                  final stickMessageBean = controller.stickMessageBean;
                  final isEmpty =
                      stickMessageBean == null && _model.list.isEmpty;
                  return CustomScrollView(
                    physics:
                        isEmpty ? const NeverScrollableScrollPhysics() : null,
                    controller: _scrollController,
                    slivers: [
                      if (isEmpty)
                        _buildEmptyView()
                      else ...[
                        ..._buildStickyList(),
                        ..._buildPinList(
                            showHeader: !(isEmpty ||
                                (_model.list.isNotEmpty && isEmpty) ||
                                (_model.list.isEmpty && !isEmpty)))
                      ]
                    ],
                  );
                  // }
                });
          },
        ));
  }

  SliverFillViewport _buildEmptyView() {
    return SliverFillViewport(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.only(bottom: 100),
          child: SvgTipWidget(
            svgName: SvgIcons.noPin,
            text: '暂无内容'.tr,
            desc: '将重要信息“Pin”到这里，让\n%s更容易发现！'.trArgs(
                [if (GlobalState.isDmChannel) "会话成员".tr else "频道成员".tr]),
          ),
          // child: DefaultTipWidget(
          //   icon: IconFont.buffChatPin,
          //   iconSize: 34,
          //   iconBackgroundColor: Theme.of(context).backgroundColor,
          //   text:
          //       '将重要信息“Pin”到这里，让\n${GlobalState.isDmChannel ? "会话成员".tr : "频道成员".tr}更容易发现！',
          // ),
        ),
        childCount: 1,
      ),
    );
  }

  Widget _buildNoticeHeader() {
    return Container(
        width: double.infinity,
        height: 44,
        alignment: Alignment.center,
        // padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        color: Colors.white,
        child: Stack(
          children: [
            Align(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  sizeWidth12,
                  Icon(IconFont.buffChatNotice,
                      size: 20, color: Theme.of(context).primaryColor),
                  sizeWidth4,
                  Expanded(
                      child: Text(
                    "正在置顶的消息".tr,
                    maxLines: 1,
                    style: const TextStyle(
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1),
                    overflow: TextOverflow.ellipsis,
                  )),
                  sizeWidth12,
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Divider(
                height: 0.5,
                color: const Color(0xFF8F959E).withOpacity(0.15),
              ),
            ),
          ],
        ));
  }

  Container _buildPinHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      width: double.infinity,
      alignment: Alignment.bottomLeft,
      height: 23,
      child: const Text(
        "Pin",
        style: TextStyle(fontSize: 14, color: Color(0xFF8F959E)),
      ),
    );
  }

  Widget _buildStickMessageItem(MessageEntity entity, int index) {
    // final backgroundColor = _model.unreadList.contains(entity.messageId)
    //     ? pinBackgroundColor
    //     : Theme.of(context).backgroundColor;
    final backgroundColor = Theme.of(context).backgroundColor;
    return FadeBackgroundButton(
      padding: const EdgeInsets.all(16),
      backgroundColor: backgroundColor,
      tapDownBackgroundColor: backgroundColor,
      onTap: () {
        Get.back();
        if (!GlobalState.isDmChannel) HomeScaffoldController.to.gotoWindow(1);
        textChannelController.gotoMessage(entity.messageId,
            showDefaultErrorToast: true);
      },
      onLongPress: () {
        stickMessageController.showActions(context, entity);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserInfo.consume(entity.userId, builder: (context, user, widget) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RealtimeAvatar(
                  userId: user.userId,
                  size: 40,
                ),
                sizeWidth8,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          user.showName(
                                  hideGuildNickname: GlobalState.isDmChannel) ??
                              '',
                          style: Theme.of(context).textTheme.bodyText2.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              )),
                      Text(
                        '发布于  %s'.trArgs([formatDate2Str(entity.time)]),
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1
                            .copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Builder(builder: (context) {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(
                        minWidth: 20, maxWidth: 20, maxHeight: 30),
                    child: IconButton(
                      icon: Icon(
                        IconFont.buffMoreHorizontal,
                        size: 20,
                        color: OrientationUtil.landscape
                            ? Theme.of(context).textTheme.bodyText2.color
                            : const Color(0xFF8F959E).withOpacity(0.7),
                      ),
                      padding: const EdgeInsets.all(0),
                      onPressed: () =>
                          stickMessageController.showActions(context, entity),
                    ),
                  );
                })
              ],
            );
          }),
          sizeHeight10,
          if (stickMessageController.stickMessageBean != null)
            AbsorbPointer(
              absorbing: entity.content.type == MessageType.messageCard,
              child: TextChatUICreator.createItemContent(entity,
                  context: context,
                  index: index,
                  messageList: [
                    stickMessageController.stickMessageBean.message
                  ], onUnFold: (string) {
                if (!_model.unFoldMessageList.contains(string)) {
                  _model.unFoldMessageList.add(string);
                }
              }, isUnFold: (string) {
                return _model.unFoldMessageList.contains(string);
              }, isPinMessage: true),
            )
        ],
      ),
    );
  }

  Widget _buildItem(PinListEntity entity, int index) {
    final backgroundColor = _model.unreadList.contains(entity.message.messageId)
        ? CustomColor.pinBackgroundColor
        : Theme.of(context).backgroundColor;
    return FadeBackgroundButton(
      padding: const EdgeInsets.all(16),
      backgroundColor: backgroundColor,
      tapDownBackgroundColor: backgroundColor,
      onTap: () {
        ///这里的[true]是给从成员列表哪里点击进来后，点pin列表跳转直接到聊天页面
        Routes.pop(context, true);
        if (OrientationUtil.portrait && widget.channel == null)
          HomeScaffoldController.to.gotoWindow(1);
        textChannelController.gotoMessage(entity.message.messageId,
            showDefaultErrorToast: true);
      },
      onLongPress: OrientationUtil.portrait
          ? () {
              _model.showActions(context, entity.message);
            }
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserInfo.consume(entity.message.userId,
              builder: (context, user, widget) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RealtimeAvatar(
                  userId: user.userId,
                  size: 40,
                ),
                sizeWidth8,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          user.showName(
                                  hideGuildNickname: GlobalState.isDmChannel) ??
                              '',
                          style: Theme.of(context).textTheme.bodyText2.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              )),
                      Text(
                        '发布于  %s'.trArgs([formatDate2Str(entity.message.time)]),
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1
                            .copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: OrientationUtil.portrait
                      ? const BoxConstraints(
                          minWidth: 20, maxWidth: 20, maxHeight: 30)
                      : const BoxConstraints(maxWidth: 35, maxHeight: 30),
                  child: Builder(builder: (context) {
                    return IconButton(
                      icon: Icon(
                        IconFont.buffMoreHorizontal,
                        size: 20,
                        color: OrientationUtil.landscape
                            ? Theme.of(context).textTheme.bodyText2.color
                            : const Color(0xFF8F959E).withOpacity(0.7),
                      ),
                      padding:
                          const EdgeInsets.only(top: 2, bottom: 2, left: 2),
                      onPressed: () =>
                          _model.showActions(context, entity.message),
                    );
                  }),
                )
              ],
            );
          }),
          sizeHeight10,
          AbsorbPointer(
            absorbing: entity.message.content.type == MessageType.messageCard,
            child: TextChatUICreator.createItemContent(entity.message,
                context: context,
                index: index,
                messageList: _model.list.map((e) => e.message).toList(),
                quoteL1: OrientationUtil.portrait ? null : 'Pin',
                //区分视频controller的分布
                onUnFold: (string) {
              if (!_model.unFoldMessageList.contains(string)) {
                _model.unFoldMessageList.add(string);
              }
            }, isUnFold: (string) {
              return _model.unFoldMessageList.contains(string);
            }, isPinMessage: true),
          )
        ],
      ),
    );
  }

  List<Widget> _buildPinList({bool showHeader}) {
    return [
      if (showHeader) SliverToBoxAdapter(child: _buildPinHeader()),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildSeparatedListElement(index,
              itemBuilder: (index) => _buildItem(_model.list[index], index),
              separatorBuilder: (index) => Divider(
                    thickness: 8,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  )),
          childCount: _model.list.length * 2,
        ),
      ),
    ];
  }

  List<Widget> _buildStickyList() {
    if (stickMessageController.stickMessageBean == null) return [];
    return [
      SliverToBoxAdapter(
        child: _buildNoticeHeader(),
      ),
      SliverToBoxAdapter(
        child: _buildStickMessageItem(
            stickMessageController.stickMessageBean.message, 0),
      )
    ];
  }

  Widget _buildSeparatedListElement(int index,
      {Function(int index) itemBuilder, Function(int index) separatorBuilder}) {
    if (index.isEven) {
      return itemBuilder(index ~/ 2);
    } else {
      return separatorBuilder(index ~/ 2);
    }
  }
}
