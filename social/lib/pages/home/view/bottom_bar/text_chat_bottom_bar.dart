import 'dart:async';
import 'dart:ui';

import 'package:fb_utils/fb_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_text_field/flutter_text_field.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/app/modules/mute/controllers/mute_list_controller.dart';
import 'package:im/app/modules/mute/views/mute_listener_widget.dart';
import 'package:im/app/modules/task/introduction_ceremony/views/task_introduction_tips.dart';
import 'package:im/app/modules/task/task_util.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/app/routes/app_pages.dart' as get_pages;
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/bot_commands/model/displayed_cmds_model.dart';
import 'package:im/pages/bot_commands/show_cmds_button.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/input_prompt/at_selector_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/pages/home/model/universal_rich_input_controller.dart';
import 'package:im/pages/home/view/bottom_bar/custom_keyboard.dart';
import 'package:im/pages/home/view/bottom_bar/emoji.dart';
import 'package:im/pages/home/view/bottom_bar/input_function_storage.dart';
import 'package:im/pages/home/view/bottom_bar/keyboard_container.dart';
import 'package:im/pages/home/view/bottom_bar/media_preview.dart';
import 'package:im/pages/home/view/record_view/record_sound_state.dart';
import 'package:im/pages/home/view/record_view/record_voice_view.dart';
import 'package:im/pages/home/view/record_view/sound_play_manager.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/rich_input_popup_tun.dart'
    if (dart.library.html) 'package:im/pages/home/view/text_chat/rich_editor/rich_input_popup.dart';
import 'package:im/pages/topic/controllers/topic_controller.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:provider/provider.dart';
import 'package:rich_input/rich_input.dart';

import '../../../../icon_font.dart';
import '../../../../routes.dart';
import '../../home_page.dart';
import '../check_permission.dart';
import 'chat_input_brace_formatter.dart';
import 'im_bottom_bar.dart';

Color _hintTextColor = Get.theme.disabledColor.withOpacity(.75);

const double _kInputMinHeight = 40;

const double _kInputMaxHeight = 151.6;

class ScrollToBottomNotification extends Notification {
  final Duration delay;

  const ScrollToBottomNotification([this.delay = Duration.zero]);
}

class TextChatBottomBar extends StatefulWidget {
  static double buttonBarHeight = 32;

  final ChatChannel channel;

  const TextChatBottomBar(this.channel, {Key key}) : super(key: key);

  @override
  TextChatBottomBarState createState() =>
      TextChatBottomBarState<TextChatBottomBar>();
}

enum FocusIndex {
  none,
  at, // 4
  emoji, // 1
  image, // 3
  voice, // 2
  redPacket,
  customKeyboard,
  robotCmds,
  storage, // 红包与直播, 之前的红包item移动到此处
}

class TextChatBottomBarState<T extends TextChatBottomBar> extends State<T>
    with SingleTickerProviderStateMixin {
  UniversalRichInputController inputController;
  final focusIndex = ValueNotifier(FocusIndex.none);

  final FocusNode _focusNode = FocusNode();

  FocusNode get focusNode => _focusNode;
  final ValueNotifier<bool> _canSend = ValueNotifier(false);
  final ValueNotifier<bool> _placeHolderVisible = ValueNotifier(false);

  InputModel inputModel;
  StreamSubscription _setTextValueStreamSubscription;

  VoidCallback windowIndexHandlerCallback;

  VoidCallback _updateChatWindowX;

  final double _bottomPopUpOpenedHeight = 230;
  StreamSubscription popupKeyboardSubscription;

  bool isTakingPic = false;

  /// 底部弹窗是否可见，选择更多中的'文件'跳转到选择页面，如果没有选择，继续显示底部，有选择则隐藏
  bool onBottomVisible = false;

  Worker _onWindowChangeListener;

  String currentRoute;

  String get channelId => widget.channel?.id;

  ChatChannel get channel => widget.channel;

  bool get isTopicPage => currentRoute == get_pages.Routes.TOPIC_PAGE;

  bool get isHomePage => currentRoute == get_pages.Routes.HOME;

  bool get isDirectChatPage => currentRoute == directChatViewRoute;

  /// 是否圈子详情或者沉浸式视频页
  bool get isCircleDetailPage =>
      widget.channel?.type == ChatChannelType.guildCircle;

  @override
  void initState() {
    currentRoute = Get.currentRoute;
    inputModel = context.read<InputModel>();
    inputController = inputModel.inputController;
    inputController.addListener(() {
      _canSend.value = inputController.text.trim().isNotEmpty;
      _placeHolderVisible.value = inputController.text.isNotEmpty;
      // todo start 和 baseOffset 有什么区别，为什么没用统一？
      final int from = UniversalPlatform.isIOS
          ? inputController.selection.start
          : inputController.selection.baseOffset;
      final bool atVisible =
          from > 0 && inputController.text.substring(from - 1, from) == '@';
      if (atVisible) {
        focusIndex.value = FocusIndex.at;
      } else if (focusIndex.value == FocusIndex.at) {
        focusIndex.value = FocusIndex.none;
      }

      /// 在安卓环境下对输入内容及光标位置变化进行记录比对以解决qq输入法输入成对括号后光标偏移量异常问题
      if (!inputController.useNativeInput) {
        ChatInputBraceTextFormatter.checkInputBraceStatus(inputController);
      }
    });

    focusIndex.addListener(() {
      if (focusIndex.value != FocusIndex.robotCmds) {
        _hideRobotCmds();
      }
    });

    /// 在dispose里面remove
    windowIndexHandlerCallback = () {
      if (HomeScaffoldController.to.windowIndex.value != 1) {
        SoundPlayManager().forceStop(); // 同时停止播放语音
      }
    };

    if (UniversalPlatform.isIOS) {
      _updateChatWindowX = () {
        /// 能够看到的 chat 面板的宽度占屏幕宽度比例
        const peekChatWindowWidth = 0.1;

        /// 创建间距
        const spaceBetweenWindow = 8;

        final _screenSize = Global.mediaInfo.size;
        final _sideWindowWidth = _screenSize.width * (1 - peekChatWindowWidth);
        final _maxChatWindowX = _sideWindowWidth + spaceBetweenWindow;

        if (HomePage.chatWindowXWithTextAlpha.value >= 0) {
          inputController.rawIosController.setAlpha(1);
        } else {
          final alpha = 1 -
              (HomePage.chatWindowXWithTextAlpha.value.abs() / _maxChatWindowX);
          if (alpha <= 0.2) {
            inputController.rawIosController.setAlpha(0);
          } else {
            inputController.rawIosController.setAlpha(alpha);
          }
        }
      };

      HomePage.chatWindowXWithTextAlpha.addListener(_updateChatWindowX);
    }

    _onWindowChangeListener = ever(HomeScaffoldController.to.windowIndex,
        (_) => windowIndexHandlerCallback());

    inputModel.textFieldFocusNode.addListener(focusChange);

    popupKeyboardSubscription = TextChannelUtil.instance.stream.listen((event) {
      if (event is! CustomKeyboardEvent) return;
      if ((event as CustomKeyboardEvent).channelId != channelId) return;
      final visible = (event as CustomKeyboardEvent).visible;
      if (visible) {
        _focusNode.requestFocus();
        focusIndex.value = FocusIndex.customKeyboard;
      } else {
        _focusNode.unfocus();
        focusIndex.value = FocusIndex.none;
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    focusIndex.dispose();
    popupKeyboardSubscription.cancel();
    _setTextValueStreamSubscription?.cancel();
    HomePage.chatWindowXWithTextAlpha.removeListener(_updateChatWindowX);
    _onWindowChangeListener?.dispose();
    _focusNode.dispose();
    inputModel.textFieldFocusNode.removeListener(focusChange);
    super.dispose();
  }

  void focusChange() {
    if (inputModel.textFieldFocusNode.hasFocus) {
      focusIndex.value = FocusIndex.none;
    }
    //  如果发现焦点没有了键盘还在，就强制执行关闭键盘的动作
    else if (!inputModel.textFieldFocusNode.hasFocus &&
        Get.mediaQuery.viewInsets.bottom > 0) {
      FbUtils.hideKeyboard();
    }
  }

  Widget _bottomExtendBar() {
    return KeyboardContainer(
      selectIndex: focusIndex,
      focusNode: _focusNode,
      childHeight: 230,
      backgroundColor: appThemeData.scaffoldBackgroundColor,
      builder: (context) {
        if (MediaQuery.of(context).orientation == Orientation.landscape)
          return const SizedBox();

        return _buildIfCustomKeyboardVisible(
          visibleBuilder: (m) => CustomKeyboard(m),
          invisibleChild: ValueListenableBuilder<FocusIndex>(
            valueListenable: focusIndex,
            builder: (context, index, child) => getExtendUI(index),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = Focus(
      focusNode: _focusNode,
      onFocusChange: _onFocusChange,
      child: Consumer<RecordSoundState>(
        builder: (context, recordSoundState, child) {
          return GestureDetector(
            onHorizontalDragStart: (_) {},
            onHorizontalDragCancel: () {},
            onHorizontalDragDown: (_) {},
            onHorizontalDragEnd: (_) {},
            onHorizontalDragUpdate: (_) {},
            child: Container(
              color: appThemeData.scaffoldBackgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (TaskUtil.instance.isNewGuy.value &&
                      widget.channel.type != ChatChannelType.dm &&
                      widget.channel.type != ChatChannelType.group_dm)
                    ObxValue<RxString>((title) {
                      return TaskIntroductionTips(
                        content: title?.value?.hasValue ?? false
                            ? title?.value
                            : '完成新成员验证，开始畅聊'.tr,
                      );
                    }, TaskUtil.instance.taskEntityTitle)
                  else ...[
                    Divider(
                        color: Theme.of(context)
                            .dividerTheme
                            .color
                            .withOpacity(.15)),
                    Stack(
                      children: [
                        if (isHomePage) getShortcutBar(),
                        Selector<InputModel, MessageEntity>(
                          selector: (_, m) => m.reply,
                          builder: (context, reply, _) =>
                              reply == null ? const SizedBox() : getRelayUI(),
                        ),
                      ],
                    ),
                    Visibility(
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      visible: recordSoundState.second == 0,
                      child: buildTextFieldRow(context),
                    ),
                    _buildIfCustomKeyboardVisible(
                      visibleBuilder: (_) => const SizedBox(),
                      invisibleChild: Column(
                        children: [
                          /// 工具栏
                          Visibility(
                            maintainSize: true,
                            maintainAnimation: true,
                            maintainState: true,
                            visible: recordSoundState.second == 0,
                            child: getToolBarUI(),
                          ),

                          /// 工具栏下面的分割线
                          Visibility(
                            maintainSize: true,
                            maintainAnimation: true,
                            maintainState: true,
                            visible: recordSoundState.second == 0,
                            child: ValueListenableBuilder<FocusIndex>(
                              valueListenable: focusIndex,
                              builder: (context, index, child) =>
                                  index == FocusIndex.none ||
                                          index == FocusIndex.at ||
                                          index == FocusIndex.robotCmds
                                      ? const SizedBox()
                                      : const Divider(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _bottomExtendBar(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );

    // 群聊、私信 不受禁言和发送权限限制
    if (widget.channel?.type == ChatChannelType.dm ||
        widget.channel?.type == ChatChannelType.group_dm) return child;

    return MuteListenerWidget(
      builder: (isMuted, mutedTime) {
        return ValidPermission(
          channelId: channelId,
          guildId: widget.channel.guildId,
          permissions: [
            if (isCircleDetailPage)
              Permission.CIRCLE_REPLY
            else
              Permission.SEND_MESSAGES,
          ],
          builder: (isAllowed, isOwner) {
            if (isAllowed && !isMuted) return child;
            if (TaskUtil.instance.isNewGuy.value &&
                widget.channel.type != ChatChannelType.dm) {
              return child;
            }
            return Container(
              decoration: BoxDecoration(
                  color: appThemeData.scaffoldBackgroundColor,
                  border: Border(
                      top: BorderSide(
                          color: Theme.of(context).dividerTheme.color,
                          width: Theme.of(context).dividerTheme.thickness))),
              child: Container(
                height: _kInputMinHeight,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(5)),
                margin: EdgeInsets.fromLTRB(
                    16, 6, 16, MediaQuery.of(context).padding.bottom + 8),
                child: Text(
                    isCircleDetailPage
                        ? isMuted
                            ? '禁言中'.tr
                            : '你没有回复权限'.tr
                        : isMuted
                            ? '禁言中，%s后解除'.trArgs([
                                MuteListController.to.getUnMuteTime(mutedTime)
                              ])
                            : '该频道为只读模式'.tr,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(color: _hintTextColor)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIfCustomKeyboardVisible(
      {Widget Function(MessageEntity) visibleBuilder, Widget invisibleChild}) {
    if (isCircleDetailPage) return invisibleChild;

    return GetBuilder<TextChannelController>(
        tag: channelId,
        builder: (c) {
          if (c.customKeyboardMessage != null) {
            return ValueListenableBuilder<FocusIndex>(
                valueListenable: focusIndex,
                builder: (context, focusIndex, _) {
                  return focusIndex == FocusIndex.customKeyboard
                      ? visibleBuilder(c.customKeyboardMessage)
                      : invisibleChild;
                });
          }
          return invisibleChild;
        });
  }

  ///fix:回复时不输入内容直接点发送，回复状态会被取消，应无效果
  bool sendText() {
    if (!_canSend.value) return false;

    /// 去掉末尾换行符
    final text =
        inputModel.inputController.data.replaceAll(RegExp(r"^\n+|\n+$"), "");

    if (isCircleDetailPage) {
      final c = CircleDetailController.to(
          postId: widget.channel.recipientId, videoFirst: true);
      c.sendText(text, reply: inputModel.reply);
    } else {
      final TextEntity textEntity = TextEntity.fromString(text);
      if (widget.channel.type == ChatChannelType.group_dm) {
        final String atDesc = inputModel.inputController.text;
        if (TextEntity.isAtString(text)) {
          textEntity.atDesc = atDesc;
        }
      }

      TextChannelController.to(
              channelId: inputModel.reply?.channelId ?? channelId)
          .sendContent(
        textEntity,
        reply: inputModel.reply,
      );
    }
    inputModel.inputController.clear();
    _canSend.value = false;
    return true;
  }

  void sendVoice(String path, int second) {
    TextChannelController.to(
            channelId: inputModel.reply?.channelId ?? channelId)
        .sendContent(
      VoiceEntity(path: path, second: second, isRead: false),
      reply: inputModel.reply,
    );
  }

  Future<void> sendMedia(List<String> identifier, {bool thumb}) async {
    try {
      _focusNode.unfocus();
      focusIndex.value = FocusIndex.none;

      if (isCircleDetailPage) {
        await CircleDetailController.to(
          postId: widget.channel.recipientId,
          videoFirst: true,
        ).sendImages(identifier, thumb, reply: inputModel.reply);
        inputModel?.textFieldFocusNode?.unfocus();
        return;
      }
      final mediaList = await MultiImagePicker.fetchMediaInfo(
          0, identifier.length,
          selectedAssets: identifier);

      final List<Asset> result = [];
      for (final item in identifier) {
        final media = mediaList.firstWhere(
            (element) => element.identifier == item,
            orElse: () => null);
        if (media != null) {
          result.add(media);
        }
      }

      final List<MessageContentEntity> entities = [];
      for (final asset in result) {
        final fileType = asset.fileType;
        if (fileType != null && fileType.isNotEmpty) {
          if (asset.fileType.contains("video")) {
            final entity = VideoEntity.fromAsset(asset);
            entity.thumb = thumb;
            entities.add(entity);
          } else if (asset.fileType.contains("image")) {
            final entity = ImageEntity.fromAsset(asset);
            entity.thumb = thumb;
            entities.add(entity);
          }
        }
      }
      if (entities.isEmpty) {
        showToast('未能在图库中找到指定的图片，请确认图片是否已经从图库中删除'.tr);
      } else {
        await TextChannelController.to(
                channelId: inputModel.reply?.channelId ?? channelId)
            .sendContents(
          entities,
          relay: inputModel.reply,
        );
      }
    } catch (e) {
      if (e is PlatformException && e.code == "PERMISSION_PERMANENTLY_DENIED") {
        await checkSystemPermissions(
          context: context,
          permissions: [
            if (UniversalPlatform.isIOS) permission_handler.Permission.photos,
            if (UniversalPlatform.isAndroid)
              permission_handler.Permission.storage
          ],
        );
      } else {
        print(e);
      }
    }
  }

  @protected
  Future<Map<String, dynamic>> pickImages(
      String identify, List<String> selectAssets, bool thumb) async {
    try {
      final result = await MultiImagePicker.pickImages(
          defaultAsset: identify,
          thumbType: thumb ? FBMediaThumbType.thumb : FBMediaThumbType.origin,
          selectedAssets: selectAssets,
          cupertinoOptions: CupertinoOptions(
              takePhotoIcon: "chat",
              selectionStrokeColor:
                  "#${Theme.of(context).primaryColor.value.toRadixString(16)}",
              selectionFillColor:
                  "#${Theme.of(context).primaryColor.value.toRadixString(16)}"),
          materialOptions: MaterialOptions(
            allViewTitle: "所有图片".tr,
            selectCircleStrokeColor:
                "#${Theme.of(context).primaryColor.value.toRadixString(16)}",
          ),
          mediaShowType:
              isCircleDetailPage ? FBMediaShowType.image : FBMediaShowType.all,
          mediaSelectType: isCircleDetailPage
              ? FBMediaSelectType.image
              : FBMediaSelectType.all);
      final List<String> identifiers = [];
      for (final item in result['identifiers']) {
        identifiers.add(item.toString());
      }
      unawaited(sendMedia(identifiers, thumb: result['thumb']));
      return null;
    } on Exception catch (e) {
      if (e is PlatformException) {
        if (e.code == "PERMISSION_PERMANENTLY_DENIED") {
          await checkSystemPermissions(
            context: context,
            permissions: [
              if (UniversalPlatform.isIOS) permission_handler.Permission.photos,
              if (UniversalPlatform.isAndroid)
                permission_handler.Permission.storage,
            ],
          );
        } else if (e.code == "CANCELLED") {
          final List<Map<String, String>> selectMedias = [];
          final assets = e.details['assets'];
          final thumb = e.details['thumb'];
          for (var i = 0; i < assets.length; i++) {
            final item = assets[i];
            final identify = item['identify'] as String;
            final fileType = item['fileType'] as String;
            final media = {'identify': identify, 'fileType': fileType};
            selectMedias.add(media);
          }

          return {"assets": selectMedias, "thumb": thumb};
        }
      }
    }
    return null;
  }

  /// * 输入框 + 发送按钮
  @protected
  Widget buildTextFieldRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(child: getTextField()),
          getSendButton(),
        ],
      ),
    );
  }

  Widget _buildTextField(bool isNative, String hintText) {
    const fontSize = 17.0;
    Widget input;
    if (isNative) {
      input = LayoutBuilder(builder: (context, constraints) {
        return RichTextField(
          textContainerInset: const EdgeInsets.fromLTRB(7, 9.3, 0, 9.3),
          controller: inputModel.inputController.rawIosController,
          focusNode: inputModel.textFieldFocusNode,
          text: inputModel.inputController.text,
          textStyle: Theme.of(context)
              .textTheme
              .bodyText2
              .copyWith(fontSize: fontSize, height: 1.25),
          width: constraints.maxWidth,
          height: _kInputMinHeight,
          minHeight: _kInputMinHeight,
          cursorColor: primaryColor,
          placeHolder: hintText.hasValue
              ? hintText.breakWord
              : "                                             ",
          placeHolderStyle:
              TextStyle(color: _hintTextColor, fontSize: fontSize),
        );
      });
    } else {
      input = Scrollbar(
        child: RichInput(
          selectionWidthStyle: BoxWidthStyle.max,
          selectionHeightStyle: BoxHeightStyle.max,
          enableSuggestions: false,
          controller: inputModel.inputController.rawFlutterController,
          focusNode: inputModel.textFieldFocusNode,
          style: Theme.of(context)
              .textTheme
              .bodyText2
              .copyWith(fontSize: fontSize, height: 1.35),
          scrollController: inputModel.scrollController,
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
            fillColor: Theme.of(context).backgroundColor,
            filled: true,
            hintStyle: TextStyle(color: _hintTextColor, height: 1.35),
            hintText: hintText.breakWord,
          ),
          onEditingComplete: sendText,
        ),
      );
    }
    return Container(
      alignment: Alignment.topRight,
      decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          borderRadius: BorderRadius.circular(5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxHeight: _kInputMaxHeight, minHeight: _kInputMinHeight),
              child: input,
            ),
          ),
          if (!isCircleDetailPage)
            Padding(
              padding: EdgeInsets.only(
                  right: 10, top: UniversalPlatform.isIOS ? 5 : 5.5),
              child: _buildInputToolbar(),
            ),
        ],
      ),
    );
  }

  @protected
  Widget getTextField() {
    String hintText;
    if (inputModel.reply == null) {
      String name;
      if (widget.channel.type == ChatChannelType.dm) {
        final String userId =
            widget.channel.recipientId ?? widget.channel.guildId;
        name =
            Db.userInfoBox.get(userId)?.showName(hideGuildNickname: true) ?? "";
        hintText = "发给 %s".trArgs([name]);
      } else if (isCircleDetailPage) {
        String name = '';
        final c = CircleDetailController.to(
          postId: widget.channel.recipientId,
          videoFirst: true,
        );
        if (c != null && (c.headUser?.userId?.hasValue ?? false))
          name = Db.userInfoBox
              .get(c.headUser.userId)
              ?.showName(guildId: widget.channel.guildId);
        hintText = '回复 %s'.trArgs([name ?? '']);
      } else {
        name = widget.channel.name;
        hintText = "发送到 #%s".trArgs([name]);
      }
    } else {
      if (isTopicPage) {
        hintText = "参与话题".tr;
      } else if (widget.channel.type == ChatChannelType.dm) {
        final String userId =
            widget.channel.recipientId ?? widget.channel.guildId;
        final String name =
            Db.userInfoBox.get(userId)?.showName(hideGuildNickname: true) ?? "";
        hintText = "发给 %s".trArgs([name]);
      } else if (isCircleDetailPage) {
        hintText = '说点什么…'.tr;
      } else {
        final String name = widget.channel.name;
        hintText = "发送到 #%s".trArgs([name]);
      }
    }
    return _buildTextField(inputController.useNativeInput, hintText);
  }

  /// * 机器人指令等
  Widget _buildInputToolbar() {
    final String userId = widget.channel.recipientId ?? widget.channel.guildId;
    return GetBuilder<TextChannelController>(
        tag: channelId,
        builder: (c) {
          return Wrap(
            children: [
              /// 没有自定义键盘时不显示按钮
              if (c.customKeyboardMessage != null)
                SizedBox(
                  width: 30,
                  height: 30,
                  child: GestureDetector(
                    onTap: () {
                      if (focusIndex.value == FocusIndex.customKeyboard) {
                        _focusNode.unfocus();
                        focusIndex.value = FocusIndex.none;
                        inputModel.textFieldFocusNode.requestFocus();
                      } else {
                        _focusNode.requestFocus();
                        focusIndex.value = FocusIndex.customKeyboard;
                      }
                    },
                    child: ValueListenableBuilder(
                        valueListenable: focusIndex,
                        builder: (context, focusIndex, child) {
                          return Icon(
                            focusIndex == FocusIndex.customKeyboard
                                ? IconFont.buffSystemKeyboard
                                : IconFont.buffBotCustomKeyboard,
                            color:
                                appThemeData.iconTheme.color.withOpacity(0.75),
                          );
                        }),
                  ),
                ),

              /// 机器人指令按钮，只有首页和私聊显示指令按钮
              if (isDirectChatPage)
                ShowCmdsButton(widget.channel, height: 30,
                    showCallback: (isShow) {
                  if (isShow) {
                    focusIndex.value = FocusIndex.robotCmds;
                  } else {
                    _onFocusChange(false);
                  }
                }),

              /// 机器人私信不显示富文本编辑按钮
              if (!(widget.channel.type == ChatChannelType.dm &&
                  Db.userInfoBox.get(userId)?.isBot == true))
                SizedBox(
                  width: 24,
                  height: 30,
                  child: GestureDetector(
                    onTap: () async {
                      final hasFocus = _focusNode.hasFocus ||
                          focusIndex.value != FocusIndex.none;
                      _focusNode.unfocus();
                      if (hasFocus) await delay(null, 100);
                      // 富文本缓存key值，话题详情页取一楼消息id，聊天公屏取频道id
                      String richTextCacheKey;
                      if (isHomePage || isDirectChatPage) {
                        richTextCacheKey = inputModel.channelId;
                      } else if (isTopicPage) {
                        richTextCacheKey =
                            Get.find<TopicController>().messageId;
                      }
                      if (richTextCacheKey == null) return;
                      final res = await showRichInputPopup(
                        context,
                        reply: inputModel.reply,
                        inputController: inputModel.inputController,
                        cacheKey: richTextCacheKey,
                        replyDetailPage: isTopicPage,
                      );
                      if (res == true &&
                          [app_pages.Routes.HOME, directChatViewRoute]
                              .contains(ModalRoute.of(context).settings.name)) {
                        inputModel.reply = null;
                      }
                    },
                    child: _buildRichTextIcon(),
                  ),
                ),
            ],
          );
        });
  }

  @protected
  Widget getRelayUI() => const SizedBox();

  @protected
  Widget getShortcutBar() => const SizedBox();

  @protected
  Widget getSendButton() {
    return GestureDetector(
      onTap: sendText,
      child: ValueListenableBuilder(
          valueListenable: _canSend,
          builder: (context, canSend, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Icon(
                IconFont.buffTabSend,
                color: canSend
                    ? Theme.of(context).primaryColor
                    : const Color(0xFFC2C5CC),
                size: 28,
              ),
            );
          }),
    );
  }

  void _showExtendUI() {
    _focusNode.requestFocus();
  }

  /// * 工具栏(图片、艾特、表情等)
  @protected
  Widget getToolBarUI() {
    Widget _item(IconData icon, bool selected, VoidCallback tap,
        {IconData highlightIcon, bool supportClose = false}) {
      return FadeButton(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        onTap: () {
          const ScrollToBottomNotification().dispatch(context);
          if (!selected) {
            tap();
          } else if (supportClose) {
            FocusScope.of(context).unfocus();
          }
        },
        child: Icon(
          selected ? (highlightIcon ?? icon) : icon,
          color: selected
              ? Theme.of(context).primaryColor
              : appThemeData.iconTheme.color,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
      child: SizedBox(
          height: TextChatBottomBar.buttonBarHeight,
          child: ValueListenableBuilder(
            valueListenable: focusIndex,
            builder: (context, index, _) {
              return Row(
                  mainAxisAlignment: isCircleDetailPage
                      ? MainAxisAlignment.spaceAround
                      : MainAxisAlignment.spaceBetween,
                  children: [
                    // Emoji item
                    Builder(builder: (context) {
                      return _item(
                          IconFont.buffTabEmoji, index == FocusIndex.emoji, () {
                        focusIndex.value = FocusIndex.emoji;

                        if (OrientationUtil.portrait) {
                          _showExtendUI();
                        } else {
                          SuperTooltip(
                                  popupDirection: TooltipDirection.top,
                                  arrowBaseWidth: 0,
                                  arrowLength: 0,
                                  arrowTipDistance: 0,
                                  borderWidth: 1,
                                  borderColor:
                                      const Color(0xff717D8D).withOpacity(0.1),
                                  shadowColor:
                                      const Color(0xff717D8D).withOpacity(0.1),
                                  outsideBackgroundColor: Colors.transparent,
                                  borderRadius: 4,
                                  offsetY: -20,
                                  content: SizedBox(
                                      width: 350, child: getExtendUI(index)))
                              .show(context);
                        }
                      });
                    }),

                    // @ item
                    if (widget.channel.type != ChatChannelType.dm)
                      Consumer<AtSelectorModel>(
                          builder: (context, model, child) {
                        return _item(IconFont.buffTabAt, model.visible, () {
                          if (MediaQuery.of(context).viewInsets.bottom < 100) {
                            _focusNode.children.first?.unfocus();
                            WidgetsBinding.instance
                                .addPostFrameCallback((timeStamp) {
                              _focusNode.children.first?.requestFocus();
                            });
                          } else {
                            _focusNode.children.first?.requestFocus();
                          }

                          // 隐藏@列表
                          final caretEnd =
                              inputModel.inputController.selection.end;
                          final text = inputModel.inputController.text;
                          if (caretEnd == 0 ||
                              (caretEnd == -1 && !text.endsWith("@")) ||
                              (caretEnd != -1 && text[caretEnd - 1] != "@")) {
                            Future.microtask(() {
                              if (kIsWeb) {
                                inputModel.webInsertText("@");
                              } else {
                                inputModel.inputController.insertText("@");
                              }
                            });
                          }

                          focusIndex.value = FocusIndex.at;
                        });
                      }),

                    // 语音 item
                    if (!isCircleDetailPage)
                      _item(IconFont.buffModuleMic, index == FocusIndex.voice,
                          () async {
                        /// 是否首次语音
                        final isFirstRecord =
                            SpService.to.getBool(SP.isFirstRecord);
                        if (UniversalPlatform.isAndroid &&
                            (isFirstRecord ?? true)) {
                          await SpService.to.setBool(SP.isFirstRecord, false);
                          final bool isConfirm = await showConfirmDialog(
                              title:
                                  '"${Global.packageInfo.appName}" 想访问您的麦克风，如果不被允许，您将无法发送语音消息');
                          if (isConfirm != null && isConfirm == true) {
                            // 权限判断
                            final result = await checkSystemPermissions(
                              context: context,
                              permissions: [
                                permission_handler.Permission.microphone
                              ],
                            );

                            if (result == true) {
                              _showExtendUI();
                              focusIndex.value = FocusIndex.voice;
                            }
                          }
                        } else {
                          // 权限判断
                          final result = await checkSystemPermissions(
                            context: context,
                            permissions: [
                              permission_handler.Permission.microphone
                            ],
                          );

                          if (result == true) {
                            _showExtendUI();
                            focusIndex.value = FocusIndex.voice;
                          }
                        }
                      }),

                    // 图片 item
                    _item(IconFont.buffTupian, index == FocusIndex.image,
                        () async {
                      final result = await checkSystemPermissions(
                        context: context,
                        permissions: [
                          if (UniversalPlatform.isIOS)
                            permission_handler.Permission.photos,
                          if (UniversalPlatform.isAndroid)
                            permission_handler.Permission.storage,
                        ],
                      );
                      if (result == true) {
                        _showExtendUI();
                        focusIndex.value = FocusIndex.image;
                      }
                    }),

                    if (!isCircleDetailPage)
                      _item(
                        IconFont.buffRoundAdd,
                        index == FocusIndex.storage,
                        () {
                          _showExtendUI();
                          focusIndex.value = FocusIndex.storage;
                        },
                        highlightIcon: IconFont.buffCloseExtension,
                        supportClose: true,
                      )
                  ]);
            },
          )),
    );
  }

  @protected
  Widget getExtendUI(FocusIndex index) {
    Widget child;
    switch (index) {
      case FocusIndex.emoji:
        child = EmojiTabs(inputModel: inputModel);
        break;
      case FocusIndex.voice:
        child = RecordVoiceView(
          callback: sendVoice,
          focusIndex: focusIndex,
        );
        break;
      case FocusIndex.image:
        child = MediaPreviewTab(
            (assets, origin) => sendMedia(assets, thumb: !origin), pickImages,
            showType: isCircleDetailPage
                ? FBMediaShowType.image
                : FBMediaShowType.all);
        break;
      case FocusIndex.storage:
        child = InputFunctionsStorage(
          channel: widget.channel,
          inputModel: inputModel,
          needClearReply: this is ImBottomBarState,
          onBottomVisible: (visible, isPageBack) {
            // isPageBack:是否是文件页面返回后的回调
            if (isPageBack) {
              onBottomVisible = false;
              if (visible) {
                // 延迟300ms这个界面才能成功获取焦点
                Future.delayed(const Duration(milliseconds: 300), () {
                  _showExtendUI();
                  _onFocusChange(true);
                });
              } else {
                _onFocusChange(false);
              }
            } else {
              // 设置为true，防止_onFocusChange改变隐藏底部控件
              onBottomVisible = visible;
            }
          },
        );
        break;
      default:
        child = const SizedBox();
        break;
    }

    return Container(
      color: appThemeData.scaffoldBackgroundColor,
      height: index == FocusIndex.none ||
              index == FocusIndex.at ||
              index == FocusIndex.robotCmds
          ? 0
          : _bottomPopUpOpenedHeight,
      child: child,
    );
  }

  @protected
  String get richTextRedDotId => widget.channel.id;

  /// - 焦点
  void _onFocusChange(bool value) {
    if (!value && !onBottomVisible) {
      focusIndex.value = FocusIndex.none;
    }
  }

  Widget _buildRichTextIcon() {
    return ValueListenableBuilder<Box<InputRecord>>(
      valueListenable: Db.textFieldInputRecordBox.listenable(
        keys: [richTextRedDotId],
      ),
      builder: (context, box, widget) {
        final richContent = box.get(richTextRedDotId)?.richContent;
        final dotVal = richContent.hasValue ? 1 : 0;

        return RedDotFill(dotVal,
            offset: const Offset(6, -5),
            radius: 3.5,
            child: Icon(
              IconFont.buffChatTextExpand,
              size: 22,
              color: appThemeData.iconTheme.color.withOpacity(0.7),
            ));
      },
    );
  }

  void _hideRobotCmds() {
    if (Get.isRegistered<DisplayedCmdsController>(tag: channelId)) {
      Get.find<DisplayedCmdsController>(tag: channelId).hideCmds();
    }
  }
}
