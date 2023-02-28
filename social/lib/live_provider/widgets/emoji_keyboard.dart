import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/live_provider/live_api_provider.dart';
import 'package:im/pages/home/model/universal_rich_input_controller.dart';
import 'package:im/pages/home/view/bottom_bar/emoji.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/utils.dart';
import 'package:rich_input/rich_input.dart';

class EmojiKeyboard extends StatefulWidget {
  /// 发送输入文本的回调
  final OnSendText onSendText;

  /// 最大字数
  final int maxLength;

  const EmojiKeyboard({
    Key key,
    this.onSendText,
    this.maxLength = 70,
  }) : super(key: key);

  @override
  _EmojiKeyboardState createState() => _EmojiKeyboardState();
}

/// 键盘输入状态
enum KeyboardStatus {
  text, // 输入普通文本
  emoji, // 输入自定义emoji
}

class _EmojiKeyboardState extends State<EmojiKeyboard>
    with WidgetsBindingObserver {
  UniversalRichInputController _controller;
  FocusNode _focusNode;

  /// 是否有输入
  bool hasInput = false;

  /// 键盘状态：emoji或text
  KeyboardStatus _keyboardStatus = KeyboardStatus.text;

  /// 输入法高度
  double _keyboardHeight = 300;

  /// 底部安全距离
  double _safeBottomHeight;

  /// 输入框组件高度
  final double _inputBoxHeight = 50;

  @override
  void initState() {
    super.initState();
    _controller = UniversalRichInputController(forceFlutter: true);
    _controller.addListener(_updateInputStatus);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addObserver(this);
    _safeBottomHeight = getBottomViewInset();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      if (_focusNode.hasFocus) {
        if (bottomInset > 50) {
          /// 键盘弹出，获取键盘高度
          _keyboardHeight = bottomInset;
          _onShowKeyboard();
        } else {
          /// 键盘收起
          _onHideKeyboard();
        }
      }
    });
  }

  void _onShowKeyboard() {
    FBLiveApiProvider.instance.emojiKeyboardChangeListeners?.forEach(
      (l) => l.onShow(_inputBoxHeight + _keyboardHeight),
    );
  }

  void _onHideKeyboard() {
    FBLiveApiProvider.instance.emojiKeyboardChangeListeners
        ?.forEach((l) => l.onShow(_inputBoxHeight));
  }

  void _onDismiss() {
    FBLiveApiProvider.instance.emojiKeyboardChangeListeners
        ?.forEach((l) => l.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        // 禁止左右，解决输入框整体左右两边未被拉伸横屏时的整宽
        left: false,
        right: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

            /// 输入栏
            _inputBar(),

            /// emoji键盘
            _emojiKeyboard(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.removeListener(_updateInputStatus);
    WidgetsBinding.instance.removeObserver(this);
    _onDismiss();
  }

  /// 更新键盘状态
  void _toggleKeyboardStatus() {
    if (_keyboardStatus == KeyboardStatus.text) {
      /// 从text切换成emoji
      _updateKeyboardState(KeyboardStatus.emoji);
    } else {
      /// 从emoji切换成text
      _updateKeyboardState(KeyboardStatus.text);
    }
  }

  void _updateKeyboardState(KeyboardStatus status) {
    if (_keyboardStatus == status) {
      return;
    }
    if (status == KeyboardStatus.emoji) {
      // 切换到emoji状态
      _keyboardStatus = KeyboardStatus.emoji;
      // 取消输入框焦点
      _focusNode.unfocus();
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      if (bottomInset == 0) {
        // 键盘处于收起状态，刷新组件，弹出emoji键盘
        setState(() {});
        _onShowKeyboard();
      }
      // 键盘处于展开状态，等键盘完全收起时刷新组件，弹出emoji键盘
      return;
    }
    if (status == KeyboardStatus.text) {
      setState(() {
        _keyboardStatus = KeyboardStatus.text;
      });
      // 等emoji键盘完全收起后再让输入框获取焦点，弹出键盘
      _focusNode.requestFocus();
    }
  }

  /// 输入框与表键盘按钮，发送按钮的组合
  Widget _inputBar() {
    return Container(
      color: Colors.white,
      height: _inputBoxHeight,
      padding: const EdgeInsets.fromLTRB(10, 7, 18, 7),
      // 此处使用SafeArea，解决横屏时输入框左右被遮住的问题,但上下不需要
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 36,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20)),
                child: RichInput(
                  textAlignVertical: TextAlignVertical.center,
                  focusNode: _focusNode,
                  controller: _controller.rawFlutterController,
                  autofocus: true,
                  maxLength: widget.maxLength,
                  onTap: () => _updateKeyboardState(KeyboardStatus.text),
                  style: const TextStyle(fontSize: 16, height: 1.35),
                  //设置键盘按钮为换行
                  textInputAction: TextInputAction.send,
                  onEditingComplete: () {
                    //点击发送调用
                    _sendText();
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
                    hintText: '聊一聊'.tr,
                    isDense: true,
                    border: const OutlineInputBorder(
                      // gapPadding: 0,
                      borderSide: BorderSide(
                        width: 0,
                        style: BorderStyle.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            sizeWidth20,
            _emojiBtn(context),
            sizeWidth20,
            _sendTextBtn(context)
          ],
        ),
      ),
    );
  }

  void _updateInputStatus() {
    final input = _controller.text;
    if (input == null || input.isEmpty) {
      /// 没有输入
      if (hasInput) {
        /// 更新当前状态为：无输入
        setState(() {
          hasInput = false;
        });
      }
    } else {
      /// 有输入
      if (!hasInput) {
        /// 更新当前状态为：有输入
        setState(() {
          hasInput = true;
        });
      }
    }
  }

  Widget _emojiBtn(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 调用表情包键盘
        _toggleKeyboardStatus();
      },
      child: Icon(
        IconFont.buffTabEmoji,
        size: 24,
        color: _keyboardStatus == KeyboardStatus.emoji
            ? primaryColor
            : const Color(0xFF8F959E),
      ),
    );
  }

  Widget _sendTextBtn(BuildContext context) {
    return GestureDetector(
      onTap: _sendText,
      // child: Image.asset(asset, width: 24, height: 24),
      child: Icon(
        IconFont.buffTabSend,
        size: 24,
        color: hasInput ? primaryColor : const Color(0xFF8F959E),
      ),
    );
  }

  void _sendText() {
    /// 是否有输入
    final hasInput = _controller.text != null && _controller.text.isNotEmpty;
    if (hasInput) {
      if (widget.onSendText != null) {
        widget.onSendText(_controller.text);
      }
      Navigator.pop(context);
    }
  }

  /// 自定义emoji键盘
  Widget _emojiKeyboard() {
    if (_keyboardStatus != KeyboardStatus.emoji) {
      return sizedBox;
    }
    return SizedBox(
      height: _keyboardHeight,
      child: Column(
        children: [
          Expanded(
            child: EmojiTabs(inputController: _controller),
          ),
          if (_safeBottomHeight > 0)
            Container(
              color: Theme.of(context).backgroundColor,
              height: getBottomViewInset(),
            ),
        ],
      ),
    );
  }
}

class WebEmojiKeyboard extends StatelessWidget {
  /// 输入框的controller
  final UniversalRichInputController controller;
  final double offset;

  const WebEmojiKeyboard({
    Key key,
    @required this.controller,
    this.offset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.pop(context);
          },
          child: Column(
            children: [
              Expanded(child: Container(color: Colors.transparent)),
              Padding(
                padding: EdgeInsets.only(right: offset ?? 0),
                child: Container(
                  width: 360,
                  height: 325,
                  padding: const EdgeInsets.only(bottom: 60),
                  child: EmojiTabs(
                    inputController: controller,
                    insertTextStyle: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
