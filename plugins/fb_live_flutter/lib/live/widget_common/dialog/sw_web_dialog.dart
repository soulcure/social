import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/theme/my_theme.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/widget_common/text_field/sw_web_text_field.dart';

import '../../utils/ui/frame_size.dart';
import '../../utils/ui/nil.dart';
import '../button/sw_web_button.dart';
import '../image/sw_image.dart';
import 'sw_scroll_dialog.dart';

bool _canShow = true;

///example
///```dart
///标题，内容，一个按钮[违规申诉弹窗备份]
///confirmSwWebDialog(context,title: '申诉提示', content: '你的申诉已收到，我们将尽快完成处理，请耐心等候');
///
/// 图标+标题，内容，两个按钮[删除回放对话框]
///confirmSwWebDialog(
///             context,
///            title: '删除回放',
///             content: '确定将删除该条回放吗？一旦删除不可撤回。',
///             okBtnBgColor: 'red',
///             okBtnTextColor: 'white',
///             cancelText: '取消',
///             isLogo: true,
///             isMoreButton: true,
///           );
///
/// 标题+关闭按钮，副标题，一行输入框，一行文字[分享对话框]
/// confirmSwWebDialog(
///             context,
///             title: '邀请好友观看直播回放',
///             isNoButton: true,
///             isCloseIcon: true,
///             child: ShareLink(),
///           );
///
///标题+关闭按钮，多行输入框，两个按钮[提交申诉说明]
///confirmSwWebDialog(
///             context,
///             title: '提交申诉说明',
///             isCloseIcon: true,
///             child: SwWebTextField(
///               controller: controller,
///               isMaxLine: true,
///               hintText: '填写你的申诉说明',
///               isFocusBorderColor: true,
///               isMaxLength: true,
///               maxLength: 300,
///               maxLengthUiPadding: EdgeInsets.only(
///                 right: 12.px,
///                 bottom: 8.px,
///               ),
///             ),
///             isMoreButton: true,
///             cancelText: '取消',
///             okText: '发送',
///           );
///
///```
void confirmSwWebDialog(
  BuildContext context, {
  String? title,
  String? content,
  String? okText,
  String? cancelText,
  bool barrierDismissible = false,
  VoidCallback? onOkPressed,
  VoidCallback? onCancelPressed,
  String? okBtnBgColor,
  String? okBtnTextColor,
  String? cancelBtnBgColor,
  String? cancelBtnTextColor,
  bool isLogo = false,
  bool isMoreButton = false,
  bool isCloseIcon = false,
  bool isNoButton = false,
  Widget? child,
  double? contentPaddingTop,
  double? contentPaddingBottom,
  bool isTextField = false,
}) {
  if (!_canShow) {
    return;
  }
  showDialog(
      context: context,
      builder: (context) {
        return SwWebDialog(
          title,
          content: content,
          okText: okText,
          cancelText: cancelText,
          barrierDismissible: barrierDismissible,
          onOkPressed: onOkPressed,
          onCancelPressed: onCancelPressed,
          okBtnBgColor: okBtnBgColor,
          okBtnTextColor: okBtnTextColor,
          cancelBtnBgColor: cancelBtnBgColor,
          cancelBtnTextColor: cancelBtnTextColor,
          isLogo: isLogo,
          isMoreButton: isMoreButton,
          isCloseIcon: isCloseIcon,
          isNoButton: isNoButton,
          contentPaddingTop: contentPaddingTop,
          contentPaddingBottom: contentPaddingBottom,
          isTextField: isTextField,
          child: child,
        );
      }).then<void>((value) {
    _canShow = false;
    Future.delayed(const Duration(milliseconds: 200)).then((value) {
      _canShow = true;
    });
  });
}

class SwWebDialog extends StatefulWidget {
  final String? title;
  final String? content;
  final String? okText;
  final String? cancelText;
  final bool? barrierDismissible;
  final VoidCallback? onOkPressed;
  final VoidCallback? onCancelPressed;
  final String? okBtnBgColor;
  final String? okBtnTextColor;
  final String? cancelBtnBgColor;
  final String? cancelBtnTextColor;
  final bool? isLogo;
  final bool? isMoreButton;
  final bool? isCloseIcon;
  final bool? isNoButton;
  final Widget? child;
  final double? contentPaddingTop;
  final double? contentPaddingBottom;
  final bool? isTextField;

  const SwWebDialog(
    this.title, {
    this.barrierDismissible,
    this.content,
    this.okText,
    this.cancelText,
    this.onOkPressed,
    this.onCancelPressed,
    this.okBtnBgColor,
    this.okBtnTextColor,
    this.cancelBtnBgColor,
    this.cancelBtnTextColor,
    this.isLogo,
    this.isMoreButton,
    this.isCloseIcon,
    this.isNoButton,
    this.child,
    this.contentPaddingTop,
    this.contentPaddingBottom,
    this.isTextField,
  });

  @override
  _SwWebDialogState createState() => _SwWebDialogState();
}

class _SwWebDialogState extends State<SwWebDialog> {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ScrollDialog(
      barrierDismissible: widget.barrierDismissible ?? false,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: FrameSize.px(440),
          padding: EdgeInsets.only(
            top: FrameSize.px(24),
            bottom: FrameSize.px(16),
            left: FrameSize.px(24),
            right: FrameSize.px(24),
          ),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //logo、标题、关闭按钮
              Row(
                mainAxisAlignment: !widget.isCloseIcon!
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.isLogo!)
                    SwImage(
                      'assets/live/main/stop.png',
                      width: 20.px,
                      height: 20.px,
                      margin: EdgeInsets.only(right: 10.px),
                    )
                  else
                    const Nil(),
                  Text(
                    widget.title ?? '提示',
                    style: TextStyle(
                      fontSize: FrameSize.px(16),
                      color: const Color(0xff1f2125),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.isCloseIcon!)
                    SwImage('assets/live/main/close.png',
                        width: 24.px, height: 24.px, onTap: () async {
                      RouteUtil.pop();
                    })
                  else
                    const Nil(),
                ],
              ),
              //内容
              if (strNoEmpty(widget.content))
                Container(
                  padding: EdgeInsets.only(
                    top: widget.child == null
                        ? 45.px
                        : widget.contentPaddingTop ?? 20.px,
                    bottom: !widget.isNoButton!
                        ? 37.px
                        : widget.contentPaddingBottom ?? 0.px,
                  ),
                  child: Text(
                    widget.content!,
                    style: TextStyle(
                      fontSize: FrameSize.px(14),
                      color: const Color(0xff17181a),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else if (widget.isTextField!)
                Padding(
                  padding: EdgeInsets.only(
                      top: widget.contentPaddingTop ?? 16.px,
                      bottom: widget.contentPaddingBottom ?? 16.px),
                  child: SwWebTextField(
                    controller: controller,
                    onChanged: (text) {
                      setState(() {});
                    },
                    isMaxLine: true,
                    hintText: '填写你的申诉说明',
                    isFocusBorderColor: true,
                    isMaxLength: true,
                    maxLength: 300,
                    maxLengthUiPadding:
                        EdgeInsets.only(right: 12.px, bottom: 8.px),
                  ),
                )
              else
                Padding(
                    padding: EdgeInsets.only(
                        top: widget.contentPaddingTop ?? 16.px,
                        bottom: widget.contentPaddingBottom ?? 16.px),
                    child: widget.child),
              //当没有按钮时；有一个按钮时；有两个按钮时
              if (!widget.isNoButton!)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.isMoreButton!)
                      SwWebButton(
                        isSpace: true,
                        isBorder: true,
                        bgColor: widget.cancelBtnBgColor as Color? ??
                            MyTheme.whiteColor,
                        textColor: widget.cancelBtnTextColor as Color? ??
                            MyTheme.blackColor,
                        text: widget.cancelText ?? '查看详情',
                        onPressed: widget.onCancelPressed,
                      ),
                    SwWebButton(
                      text: widget.okText ?? '确定',
                      textColor:
                          widget.okBtnTextColor as Color? ?? MyTheme.whiteColor,
                      bgColor: widget.okBtnBgColor as Color? ??
                          (!strNoEmpty(controller.text)
                              ? MyTheme.blueOpacityColor
                              : MyTheme.blueColor),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
