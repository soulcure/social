import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_text_field/flutter_text_field.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/mute/views/mute_listener_widget.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/components/bottom_right_button/bottom_loading.dart';
import 'package:im/pages/home/components/bottom_right_button/top_right_button_controller.dart';
import 'package:im/pages/home/json/message_entity_extension.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/model/universal_rich_input_controller.dart';
import 'package:im/pages/home/view/bottom_bar/keyboard_container.dart';
import 'package:im/pages/home/view/content_loading.dart';
import 'package:im/pages/home/view/text_chat/items/text_item.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/pages/home/view/text_chat_constraints.dart';
import 'package:im/pages/home/view/text_chat_view.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/message_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/list_physics.dart';
import 'package:im/widgets/list_view/proxy_index_list.dart';
import 'package:oktoast/oktoast.dart';
import 'package:rich_input/rich_input.dart';

import '../../../global.dart';
import 'unity_rich_text_item.dart';

void showChannelDialog(BuildContext context) {
  showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return ChannelDialog(
          mute: true,
          closeAction: Get.back,
          channelId: GlobalState.selectedChannel.value.id,
        );
      });
}

class ChannelDialog extends StatefulWidget {
  final String channelId;
  final VoidCallback closeAction;
  final VoidCallback openSettingAction;
  final Function(bool) changeVoiceAction;
  final bool mute;
  const ChannelDialog(
      {Key key,
      this.channelId,
      this.mute = false,
      this.closeAction,
      this.openSettingAction,
      this.changeVoiceAction})
      : super(key: key);

  @override
  _ChannelDialogState createState() => _ChannelDialogState();
}

class _ChannelDialogState extends State<ChannelDialog> {
  double chatViewOffset = TextChatViewBottomPadding;
  ChatViewScrollState chatViewScrollState = ChatViewScrollState.none;
  int listItemCount = 0;
  final List<String> _unFoldMessageList = [];
  UniversalRichInputController universalController =
      UniversalRichInputController();
  final _focusNode = FocusNode();
  bool _textFieldVisible = false;
  final ValueNotifier<bool> _canSend = ValueNotifier(false);
  final ValueNotifier<bool> _mute = ValueNotifier(false);
  bool validChannel = false;
  bool get isOwner {
    final gt = ChatTargetsModel.instance.selectedChatTarget;
    if (gt == null) return false;
    return (gt as GuildTarget).ownerId == Global.user.id;
  }

  Widget _item(
      TextChannelController model, int index, Iterable<MessageEntity> list,
      {bool shouldShowUserInfo = false,
      UnFoldTextItemCallback onUnFold,
      IsUnFoldTextItemCallback isUnFold}) {
    final model = TextChannelController.to(channelId: widget.channelId);
    final current = list.elementAt(index);

    if (current.isRecalled || current.isDeleted) return sizedBox;

    Widget item;
    switch (current.content.runtimeType) {
      case TextEntity:
        item = TextItem(
          current,
          isUnFold,
          onUnFold,
          sendByMyself: current.userId == Global.user.id,
          pureText: true,
        );
        break;
      case RichTextEntity:
        item = UnityRichTextItem(
            message: current, isUnFold: isUnFold, onUnFold: onUnFold);
        break;
      default:
        item = unSupportWidget(model);
    }

    if (shouldShowUserInfo) {
      /// UserInfo
      item = Padding(
          padding: const EdgeInsets.only(left: 12),
          child: TextChatUICreator.buildUserInfoRow2(
              context, model.guildId, 'guidName', current,
              disableOnTap: true, content: item));
    }

    return Padding(
      padding: EdgeInsets.only(
          left: shouldShowUserInfo ? 0 : 56, top: 4, bottom: 4, right: 12),
      child: item,
    );
  }

  static Widget unSupportWidget(TextChannelController model) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: const Color(0xff8F959E).withOpacity(0.3), width: 0.5),
          borderRadius: const BorderRadius.all(Radius.circular(8))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
            child: Text(
              '发布了一条消息，请在 #${model.channel.name} 频道中查看',
              style: const TextStyle(fontSize: 15, color: Color(0xff8F959E)),
            ),
          ),
        ],
      ),
    );
  }

  /// 这里的逻辑主要是照搬 text_chat_view.dart - buildList
  /// 主要是改变item渲染，与删除部分逻辑，无做任何新增逻辑
  Widget _buildList(TextChannelController model) {
    final list = model.messageList;

    if (model.showLoading && list.isEmpty)
      return const ContentLoadingView(
        backgroundColor: Colors.transparent,
        contentColor: Colors.white,
      );

    final itemCount = list.length + 2;
    var initialScrollIndex = itemCount;
    if (model.newMessagePosition > 0) {
      if (model.newMessagePosition >= list.length) {
        logger.warning("未读消息超出消息总数");
      }
    }

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

    if (list.length == 1 && list.first.content is StartEntity) {
      return emptyMessageWidget();
    }

    return LayoutBuilder(builder: (context, constraints) {
      return TextChatConstraints(
          constraints: constraints,
          context: context,
          child: CupertinoScrollbar(
              child: ProxyIndexList(
            physics: const SlowListPhysics(),
            padding: const EdgeInsets.only(top: 24),
            key: model.listKey,
            initialIndex: initialScrollIndex,
            initialAlignment: initialAlignment,
            initialOffset: chatViewOffset,
            controller: model.proxyController,
            indexListener: model.proxyListener,
            itemCount: listItemCount,
            builder: (context, index) {
              if (index == 0) {
                if (list.isNotEmpty && list.first.content is StartEntity) {
                  return const SizedBox(height: 1);
                } else {
                  if (model.canReadHistory) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: CupertinoActivityIndicator.partiallyRevealed(),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("╮(╯▽╰)╭当前暂无查看该频道历史消息的权限，历史消息在退出App后自动清空".tr),
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
                return const SizedBox(height: 1);
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
                shouldShowUserInfo = MessageEntityExtension.shouldShowUserInfo(
                    previous, current, next,
                    underNewMessageSeparator: model.newMessagePosition > 0 &&
                        index == list.length - model.newMessagePosition);
                if (shouldShowUserInfo) top = const SizedBox(height: 16);
              }

              final Widget child = _item(
                model,
                index,
                list,
                shouldShowUserInfo: shouldShowUserInfo,
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
                  /// 自然日不同时，显示时间分割线
                  if (previous != null &&
                      (previous.time.day != current.time.day ||
                          previous.time.month != current.time.month ||
                          previous.time.year != current.time.year))
                    _buildTimeSeparator(
                        current, previous.time.year != current.time.year),

                  if (top != null) top,
                  child,
                ],
              );
            },
          )));
    });
  }

  // 公屏的逻辑抽取
  Widget _buildTimeSeparator(MessageEntity item, bool crossYear) {
    final timeString =
        MessageEntityExtension.buildTimeSeparator(item, crossYear);

    return Container(
      height: 32,
      alignment: Alignment.center,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Color(0xFFD4D5D6), Color(0xFFEFE7DD)],
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD4D5D6), Color(0xFFEFE7DD)],
                  ),
                )),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    universalController.addListener(textFieldUpdate);
    _mute.value = widget.mute;
    final gt = ChatTargetsModel.instance.selectedChatTarget;
    if (gt != null && widget.channelId != null) {
      final gp = PermissionModel.getPermission(gt.id);
      if (gt.getChannel(widget.channelId) != null &&
          PermissionUtils.isChannelVisible(gp, widget.channelId)) {
        validChannel = true;
        TextChannelController.to(channelId: widget.channelId).joinChannel();
        TextChannelController.to(channelId: widget.channelId)
            .proxyListener
            ?.itemPositionsListener
            ?.itemPositions
            ?.addListener(_onScroll);
        TopRightButtonController.to(widget.channelId).updateNumUnread();
      }
    }
    super.initState();
  }

  // 滑动到顶部的getList
  void _onScroll() {
    final m = TextChannelController.to(channelId: widget.channelId);
    final positions =
        m.proxyListener?.itemPositionsListener?.itemPositions?.value;
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
      if (m.canReadHistory) m.loadHistory();
    }
    final bottomIndex = positions
        .where((position) => position.itemLeadingEdge < 1)
        .reduce((max, position) =>
            position.itemLeadingEdge > max.itemLeadingEdge ? position : max)
        .index;
    m.topIndex = max(0, topIndex);
    m.bottomIndex = max(0, bottomIndex - 2);

    final numBottomInvisible = listItemCount - 1 - bottomIndex;
    if (numBottomInvisible <= 0) {
      m.loadMore();
    }
  }

  @override
  void dispose() {
    universalController.removeListener(textFieldUpdate);
    TextChannelController.to(channelId: widget.channelId)
        .proxyListener
        ?.itemPositionsListener
        ?.itemPositions
        ?.removeListener(_onScroll);
    ValueNotifier(false);
    super.dispose();
  }

  void textFieldUpdate() {
    _canSend.value = universalController.text.isNotEmpty;
  }

  Widget emptyChannelWidget() {
    return Material(
      color: Colors.transparent,
      child: Center(
          child: SizedBox(
        height: 504,
        width: 336,
        child: Stack(
          children: [
            Image.asset(
              'assets/community/background.png',
              height: 504,
              width: 336,
              centerSlice: const Rect.fromLTRB(12, 12, 116, 116),
            ),
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/community/empty_channel.png',
                    width: 150,
                    height: 150,
                  ),
                  sizeHeight12,
                  Text(
                    '频道信号丢失了'.tr,
                    textAlign: TextAlign.center,
                    style: appThemeData.textTheme.bodyText2,
                  ),
                  sizeHeight24,
                  if (isOwner)
                    FadeButton(
                      onTap: () => widget.openSettingAction?.call(),
                      child: const Icon(
                        IconFont.buffSetting,
                        size: 30,
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
                right: 4,
                top: 4,
                child: FadeButton(
                  onTap: widget.closeAction?.call,
                  child: Image.asset(
                    'assets/community/close.png',
                    width: 56,
                    height: 56,
                  ),
                ))
          ],
        ),
      )),
    );
  }

  Widget emptyMessageWidget() {
    return Center(
        child: SizedBox(
      height: 504,
      width: 336,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/community/empty_message.png',
            width: 150,
            height: 150,
          ),
          sizeHeight12,
          Text(
            '一条友善的发言会让人心情愉悦\n 来说点什么吧'.tr,
            textAlign: TextAlign.center,
            style: appThemeData.textTheme.bodyText2,
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.channelId.noValue || !validChannel) {
      return emptyChannelWidget();
    }
    return GetBuilder<TextChannelController>(
        tag: widget.channelId,
        builder: (controller) {
          return GestureDetector(
            onTap: () {
              if (_textFieldVisible) {
                setState(() {
                  _textFieldVisible = false;
                });
              }
            },
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_textFieldVisible) {
                        setState(() {
                          _textFieldVisible = false;
                        });
                      }
                    },
                    child: Center(
                      child: SizedBox(
                        width: 336,
                        height: 560,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 504,
                              child: Stack(
                                alignment: AlignmentDirectional.topCenter,
                                clipBehavior: Clip.none,
                                children: [
                                  // 背景
                                  Image.asset(
                                    'assets/community/background.png',
                                    height: 504,
                                    width: 336,
                                    centerSlice:
                                        const Rect.fromLTRB(12, 12, 116, 116),
                                  ),
                                  // 聊天列表
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: _buildList(controller),
                                  ),
                                  // 标题
                                  Positioned(
                                    top: -20,
                                    child: Stack(
                                      alignment: AlignmentDirectional.center,
                                      children: [
                                        Image.asset(
                                          'assets/community/title.png',
                                          height: 60,
                                          width: 160,
                                          centerSlice: const Rect.fromLTRB(
                                              12, 12, 116, 52),
                                        ),
                                        Text(
                                          controller.channel.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: appThemeData
                                              .textTheme.bodyText1
                                              .copyWith(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                      right: 4,
                                      top: 4,
                                      child: FadeButton(
                                        onTap: widget.closeAction?.call,
                                        child: Image.asset(
                                          'assets/community/close.png',
                                          width: 56,
                                          height: 56,
                                        ),
                                      ))
                                ],
                              ),
                            ),
                            Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                sizeWidth8,
                                MuteListenerWidget(
                                  builder: (isMuted, mutedTime) {
                                    return ValidPermission(
                                      channelId: widget.channelId,
                                      permissions: [
                                        Permission.SEND_MESSAGES,
                                      ],
                                      builder: (isAllowed, isOwner) {
                                        final muted = isMuted || !isAllowed;
                                        return FadeButton(
                                          onTap: () {
                                            if (muted) {
                                              showToast('你已被禁言，请解除禁言后再尝试发言');
                                              return;
                                            }
                                            setState(() {
                                              _textFieldVisible = true;
                                            });
                                          },
                                          child: Image.asset(
                                            'assets/community/send_button.png',
                                            width: 56,
                                            height: 56,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                const Expanded(
                                  child: sizedBox,
                                ),
                                ValueListenableBuilder(
                                    valueListenable: _mute,
                                    builder: (context, value, __) {
                                      return FadeButton(
                                        onTap: () {
                                          _mute.value = !_mute.value;
                                          widget.changeVoiceAction
                                              ?.call(_mute.value);
                                        },
                                        child: Image.asset(
                                          value
                                              ? 'assets/community/volume_button_off.png'
                                              : 'assets/community/volume_button_on.png',
                                          width: 56,
                                          height: 56,
                                        ),
                                      );
                                    }),
                                if (isOwner)
                                  FadeButton(
                                    onTap: () =>
                                        widget.openSettingAction?.call(),
                                    child: Image.asset(
                                      'assets/community/setting_button.png',
                                      width: 56,
                                      height: 56,
                                    ),
                                  ),
                                sizeWidth8,
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 输入框
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Visibility(
                      visible: _textFieldVisible,
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          color: appThemeData.scaffoldBackgroundColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: getTextField(),
                                  ),
                                  const SizedBox(width: 12),
                                  RepaintBoundary(
                                      child: GestureDetector(
                                    onTap: () => sendText(controller),
                                    child: ValueListenableBuilder(
                                        valueListenable: _canSend,
                                        builder: (context, canSend, _) {
                                          return Container(
                                            width: 32,
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 6, 0, 6),
                                            child: Icon(
                                              IconFont.buffTabSend,
                                              color: canSend
                                                  ? Theme.of(context)
                                                      .primaryColor
                                                  : const Color(0xFFC2C5CC),
                                              size: 28,
                                            ),
                                          );
                                        }),
                                  )),
                                ],
                              ),
                              KeyboardContainer(
                                focusNode: _focusNode,
                                backgroundColor:
                                    appThemeData.scaffoldBackgroundColor,
                                builder: (_) {
                                  return const SizedBox();
                                },
                                childHeight: 0,
                                selectIndex: null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  Widget getTextField() {
    const fontSize = 17.0;
    const minHeight = 42.0;
    const maxHeight = 145.0;

    Widget input;
    final hitText = '请输入留言'.tr;
    final hitTextStyle = TextStyle(
        color: Get.theme.disabledColor.withOpacity(.75), fontSize: 17);
    if (UniversalPlatform.isIOS) {
      input = RichTextField(
        controller: universalController.rawIosController,
        focusNode: _focusNode,
        textStyle:
            appThemeData.textTheme.bodyText2.copyWith(fontSize: fontSize),
        minHeight: minHeight,
        maxHeight: maxHeight,
        cursorColor: appThemeData.primaryColor,
        placeHolder: hitText,
        placeHolderStyle: hitTextStyle,
        autoFocus: true,
      );
    } else {
      input = RichInput(
        autofocus: true,
        selectionWidthStyle: BoxWidthStyle.max,
        selectionHeightStyle: BoxHeightStyle.max,
        enableSuggestions: false,
        controller: universalController.rawFlutterController,
        focusNode: _focusNode,
        style: Theme.of(context)
            .textTheme
            .bodyText2
            .copyWith(fontSize: fontSize, height: 1.35),
        keyboardType: TextInputType.multiline,
        maxLines: null,
        maxLength: 5000,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.fromLTRB(14, 8, 0, 7),
          isDense: true,
          counterText: "",
          border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(20),
              gapPadding: 0),
          fillColor: appThemeData.backgroundColor,
          filled: true,
          hintStyle: hitTextStyle,
          hintText: hitText,
        ),
        onEditingComplete: () {},
      );
    }
    return Container(
      alignment: Alignment.topRight,
      decoration: BoxDecoration(
          color: appThemeData.backgroundColor,
          borderRadius: BorderRadius.circular(5)),
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxHeight: maxHeight, minHeight: minHeight),
        child: input,
      ),
    );
  }

  void sendText(TextChannelController controller) {
    if (!_canSend.value) return;

    /// 去掉末尾换行符
    final text = universalController.text.replaceAll(RegExp(r"^\n+|\n+$"), "");

    final TextEntity textEntity = TextEntity.fromString(text);

    controller.sendContent(
      textEntity,
    );

    controller.jumpToBottom();

    universalController.clear();
  }
}
