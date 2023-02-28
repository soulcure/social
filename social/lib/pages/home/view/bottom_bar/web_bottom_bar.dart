// ignore: avoid_web_libraries_in_flutter
//import 'dart:html' as html;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:im/app/modules/task/introduction_ceremony/views/task_introduction_tips.dart';
import 'package:im/app/modules/task/task_util.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages;
import 'package:im/common/permission/permission.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/db/db.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/input_prompt/at_selector_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/bottom_bar/emoji.dart';
import 'package:im/pages/home/view/bottom_bar/text_chat_bottom_bar.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/rich_input_popup.dart';
import 'package:im/pages/topic/controllers/topic_controller.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/web_light_theme.dart';
import 'package:im/web/mixin/paste_mixin_web.dart'
    if (dart.library.io) 'package:im/web/mixin/paste_mixin.dart';
import 'package:im/web/utils/image_picker/image_picker.dart'
    as web_image_picker;
import 'package:im/web/utils/show_rich_editor_tooltip.dart';
import 'package:im/web/widgets/send_image/send_image_dialog.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';
import 'package:rich_input/rich_input.dart';

import '../../../../routes.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;

class WebBottomBar extends StatefulWidget {
  final ChatChannel channel;
  final bool isFromTopicPage;

  const WebBottomBar(this.channel, {Key key, this.isFromTopicPage = false})
      : super(key: key);

  @override
  _WebBottomBarState createState() => _WebBottomBarState();
}

class _WebBottomBarState extends State<WebBottomBar> with WebOnPasteMixin {
  InputModel _inputModel;

  /// 记录每次变化后的输入行数，用于发送文字
  int _currentInputTextLines = 1;
  String _preValue = '';
  String _preValueData = '';

  //
  bool _canOpenFile = true;

  @override
  void initState() {
    _inputModel = context.read<InputModel>();

    /// 监听换行
    _preValue = _inputModel.inputController.text;
    _preValueData = _inputModel.inputController.data;
    _currentInputTextLines = _inputModel.inputController.text.split(',').length;
    _inputModel.inputController.addListener(() {
      final newLine = _inputModel.inputController.text.split('\n').length;
      if (newLine == _currentInputTextLines + 1 &&
          _preValue.length + 1 == _inputModel.inputController.text.length) {
        sendText(data: _preValueData);
        _preValue = '';
        _preValueData = '';
        _currentInputTextLines = 1;
        return;
      }
      _preValue = _inputModel.inputController.text;
      _preValueData = _inputModel.inputController.data;
      _currentInputTextLines = newLine;
    });
    _setInputTextRecord();
    addWebPasteListener((asset) {
      if (asset != null) sendMedia(asset);
    });
    super.initState();
  }

  @override
  void dispose() {
    removeWebPasteListener();
    super.dispose();
  }

  void sendText({String data}) {
    if (_inputModel.inputController.text.trim().isEmpty) {
      _inputModel.inputController.clear();
      return;
    }

    /// 处理换行符
    /// 去掉末尾换行符
    final text = (data ?? _inputModel.inputController.data)
        .replaceAll(RegExp(r"\r?\n+$"), "");

    TextChannelController.to(
            channelId: _inputModel?.reply?.channelId ?? _inputModel.channelId)
        .sendContent(
      TextEntity.fromString(text),
      reply: _inputModel.reply,
    );
    _inputModel.inputController.clear();

    const ScrollToBottomNotification().dispatch(context);

    if (!widget.isFromTopicPage) _inputModel.reply = null;

    /// web端的得特殊处理
    _inputModel.inputController.rawFlutterController.value =
        const TextEditingValue(selection: TextSelection.collapsed(offset: 0));
    _inputModel.textFieldFocusNode.requestFocus();
  }

  Widget getRelayUI() {
    final theme = Theme.of(context);
    final color = theme.disabledColor;
    final textStyle = TextStyle(color: color, fontSize: 12);
    final reply = _inputModel.reply;
    return Container(
      height: 32,
      margin: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: <Widget>[
          sizeWidth4,
          FadeButton(
            onTap: () => _inputModel.reply = null,
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.close, color: color, size: 16),
          ),
          SizedBox(
              height: 16,
              child: VerticalDivider(color: color.withOpacity(0.5))),
          const SizedBox(width: 12),
          Text(
            '回复'.tr,
            style: textStyle,
          ),
          Flexible(
              child: RealtimeNickname(
            userId: reply.userId,
            style: textStyle,
          )),
          Expanded(
            child: FutureBuilder(
                future: reply.toNotificationString(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  return Text(
                    ": ${snapshot.data}".replaceAll("\n", " "),
                    style: textStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  );
                }),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Future<void> sendMedia(Asset asset, {bool thumb}) async {
    try {
      /// 延迟 50ms 时，发 5+ 张图时，先改成 200ms
      /// 等发多张图改成在一个消息内之后，可以去掉延迟
      const ScrollToBottomNotification(Duration(milliseconds: 200))
          .dispatch(context);

      MessageContentEntity entity;
      final fileType = asset.fileType;
      if (fileType != null && fileType.isNotEmpty) {
        if (asset.fileType.contains("video")) {
          final _entity = VideoEntity.fromAsset(asset);
          _entity.thumb = thumb;
          entity = _entity;
        } else if (asset.fileType.contains("image")) {
          final _entity = ImageEntity.fromAsset(asset);
          _entity.thumb = thumb;
          entity = _entity;
        }
      }

      if (entity != null) {
        unawaited(TextChannelController.to(
                channelId:
                    _inputModel?.reply?.channelId ?? _inputModel.channelId)
            .sendContent(
          entity,
          reply: _inputModel.reply,
        ));
        if (!widget.isFromTopicPage) _inputModel.reply = null;
      }
    } catch (e) {
      print(e);
    }
  }

  Widget _toolBar() {
    Widget _item(IconData data, VoidCallback callback) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 9, 0, 5),
        child: FadeButton(
          onTap: callback,
          child: Icon(
            data,
            color: Theme.of(context).textTheme.bodyText1.color,
          ),
        ),
      );
    }

    return Row(
      children: [
//        ShowCmdsButton(widget.channel, height: 20, width: 20,),
        sizeWidth4,
        Builder(builder: (context) {
          return _item(IconFont.buffTabEmoji, () {
            SuperTooltip _tip;
            _tip = SuperTooltip(
              popupDirection: TooltipDirection.top,
              offsetY: -28,
              arrowBaseWidth: 0,
              arrowLength: 0,
              arrowTipDistance: 0,
              borderWidth: 1,
              borderColor: const Color(0xff717D8D).withOpacity(0.1),
              shadowColor: const Color(0xff717D8D).withOpacity(0.1),
              outsideBackgroundColor: Colors.transparent,
              borderRadius: 4,
              content: Material(
                child: Container(
                    width: 388,
                    height: 280,
                    decoration: webBorderDecoration,
                    child: EmojiTabs(
                      inputModel: _inputModel,
                      callback: () => _tip.close(),
                      parentContext: context,
                    )),
              ),
            );
            _tip.show(context);
          });
        }),
        Consumer<AtSelectorModel>(builder: (context, model, child) {
          return Visibility(
            visible: widget.channel.type != ChatChannelType.dm,
            child: _item(IconFont.buffTabAt, () async {
              _inputModel.textFieldFocusNode.requestFocus();
              // 隐藏@列表
              final caretEnd = _inputModel.inputController.selection.end;
              final text = _inputModel.inputController.text;
              if (caretEnd == 0 ||
                  (caretEnd == -1 && !text.endsWith("@")) ||
                  (caretEnd != -1 && text[caretEnd - 1] != "@")) {
                await Future.microtask(() {
                  _inputModel.webInsertText("@");
                });
              }
            }),
          );
        }),
        _item(IconFont.buffTupian, () async {
          if (!_canOpenFile) return;
          _canOpenFile = false;
          unawaited(Future.delayed(const Duration(seconds: 1)).then((value) {
            _canOpenFile = true;
          }));
          final file = await web_image_picker.ImagePicker.pickFile();
          final result = await showImageDialog(context, file);
          if (result != null) {
            unawaited(sendMedia(result));
          }
        }),

        // 横屏模式话题详情页暂时未添加富文本
        if (!widget.isFromTopicPage &&
            !(widget.channel.type == ChatChannelType.dm &&
                Db.userInfoBox.get(widget.channel.guildId)?.isBot == true))
          _item(IconFont.buffChatTextExpand, () async {
            Function closeTooltip;
            void onSelectedChannelChange() {
              if (GlobalState.selectedChannel.value?.id != widget.channel?.id) {
                closeTooltip?.call(null);
              }
            }

            GlobalState.selectedChannel.addListener(onSelectedChannelChange);
            FocusScope.of(Get.context).requestFocus(FocusNode());
            await showWebRichEditorTooltip<bool>(context, builder: (c, done) {
              closeTooltip = done;
              // 富文本缓存key值，话题详情页取一楼消息id，聊天公屏取频道id
              String richTextCacheKey;
              final currentRoute = Get.currentRoute;
              if (currentRoute == app_pages.Routes.HOME ||
                  currentRoute == directChatViewRoute) {
                richTextCacheKey = _inputModel.channelId;
              } else if (currentRoute == get_pages.Routes.TOPIC_PAGE) {
                richTextCacheKey = Get.find<TopicController>().messageId;
              }
              return RichInputPop(
                reply: _inputModel.reply,
                inputController: _inputModel.inputController,
                replyDetailPage: widget.isFromTopicPage,
                cacheKey: richTextCacheKey,
                onClose: (success) {
                  done.call(success);
                  if (success) {
                    _inputModel.reply = null;
                  }
                },
              );
            });
            GlobalState.selectedChannel.removeListener(onSelectedChannelChange);
          })
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = Selector<InputModel, MessageEntity>(
        selector: (_, m) => m.reply,
        builder: (context, replay, _) {
          return ObxValue<RxBool>((rxIsShow) {
            return Column(
              children: [
                if (rxIsShow.value && widget.channel.type != ChatChannelType.dm)
                  Padding(
                    padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 6,
                        bottom: 6 + MediaQuery.of(context).padding.bottom),
                    child: ObxValue<RxString>((title) {
                      return TaskIntroductionTips(
                        content: (title?.value != null &&
                                title?.value?.isNotEmpty == true)
                            ? title.value
                            : "完成新成员验证，开始畅聊".tr,
                      );
                    }, TaskUtil.instance.taskEntityTitle),
                  )
                else ...[
                  if (_inputModel.reply != null && !widget.isFromTopicPage)
                    getRelayUI(),
                  Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 25),
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                        decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(4)),
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) {
                            if ((RawKeyboard.instance.keysPressed.contains(
                                        LogicalKeyboardKey.metaLeft) ||
                                    RawKeyboard.instance.keysPressed
                                        .contains(LogicalKeyboardKey.altLeft) ||
                                    RawKeyboard.instance.keysPressed.contains(
                                        LogicalKeyboardKey.controlLeft) ||
                                    RawKeyboard.instance.keysPressed.contains(
                                        LogicalKeyboardKey.metaRight) ||
                                    RawKeyboard.instance.keysPressed.contains(
                                        LogicalKeyboardKey.altRight) ||
                                    RawKeyboard.instance.keysPressed.contains(
                                        LogicalKeyboardKey.controlRight)) &&
                                (RawKeyboard.instance.keysPressed
                                        .contains(LogicalKeyboardKey.enter) ||
                                    RawKeyboard.instance.keysPressed.contains(
                                        LogicalKeyboardKey.numpadEnter))) {
                              _currentInputTextLines++;
                              _inputModel.inputController.insertText('\n');
                            } else if (RawKeyboard.instance.keysPressed
                                    .contains(LogicalKeyboardKey.enter) ||
                                RawKeyboard.instance.keysPressed
                                    .contains(LogicalKeyboardKey.numpadEnter)) {
                              if (_inputModel.inputController.text.length >=
                                  5000) {
                                sendText();
                              }
                            }
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 142),
                            child: Selector<InputModel, MessageEntity>(
                                selector: (_, m) => m.reply,
                                builder: (context, replay, _) {
                                  String hintText;
                                  if (_inputModel.reply == null) {
                                    String name;
                                    if (widget.channel.type ==
                                        ChatChannelType.dm) {
                                      name = Db.userInfoBox
                                              .get(widget.channel.guildId)
                                              ?.nickname ??
                                          "";
                                      hintText = "发给 %s".trArgs([name]);
                                    } else {
                                      name = widget.channel.name;
                                      hintText = "发送到 #%s".trArgs([name]);
                                    }
                                  } else {
                                    hintText = "参与话题".tr;
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 150),
                                    child: RichInput(
                                      selectionWidthStyle: BoxWidthStyle.max,
                                      selectionHeightStyle: BoxHeightStyle.max,
                                      enableSuggestions: false,
                                      controller: _inputModel
                                          .inputController.rawFlutterController,
                                      focusNode: _inputModel.textFieldFocusNode,
                                      style:
                                          Theme.of(context).textTheme.bodyText2,
                                      scrollController:
                                          _inputModel.scrollController,
                                      keyboardType: TextInputType.multiline,
                                      maxLines: null,
                                      maxLength: 5000,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 7),
                                        isDense: true,
                                        counterText: "",
                                        border: const OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                            gapPadding: 0),
                                        fillColor: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        filled: true,
                                        hintStyle: TextStyle(
                                            color:
                                                Theme.of(context).disabledColor,
                                            height: 1.35),
                                        hintText: hintText,
                                      ),
                                    ),
                                  );
                                }),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 40,
                        bottom: 4,
                        child: _toolBar(),
                      )
                    ],
                  ),
                  sizeHeight16,
                ]
              ],
            );
          }, TaskUtil.instance.isNewGuy);
        });
    if (widget.channel?.type == ChatChannelType.dm) return child;

    return ValidPermission(
      channelId: widget.channel?.id,
      permissions: [
        Permission.SEND_MESSAGES,
      ],
      builder: (isAllowed, isOwner) {
        if (isAllowed) return child;
        return Container(
          padding: EdgeInsets.fromLTRB(
              16, 4, 16, MediaQuery.of(context).padding.bottom + 4),
          decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: Theme.of(context).dividerTheme.color,
                      width: Theme.of(context).dividerTheme.thickness))),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(20)),
            child: Text('该频道为只读模式'.tr,
                style: Theme.of(context).textTheme.bodyText1),
          ),
        );
      },
    );
  }

  /// 从输入记录中恢复上次的输入内容
  void _setInputTextRecord() {
    if (GlobalState.selectedChannel.value == null) return;
    final history =
        Db.textFieldInputRecordBox.get(GlobalState.selectedChannel.value?.id);
    if (history == null) {
      _inputModel.setValue("");
    } else {
      final m = TextChannelController.to(channelId: _inputModel.channelId);
      m.hasInitialized.then((value) {
        MessageEntity reply;
        if (history.replyId != null) {
          reply = m.messageList.firstWhere(
              (element) => element.messageId == history.replyId,
              orElse: () => null);
        }
        _inputModel.setValue(history.content, reply: reply);
      });
    }
  }
}
