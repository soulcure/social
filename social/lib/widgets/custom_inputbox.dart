import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im/core/config.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/text_field/native_input.dart';

typedef OnChange = void Function(String);

///
/// 自定义输入框
///
class CustomInputBox extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final TextStyle style;
  final TextStyle hintStyle;
  final Color fillColor;
  final OnChange onChange;
  final int maxLength;
  final bool readOnly;
  final FocusNode focusNode;
  final double borderRadius;
  final int maxLines;
  final bool autofocus;
  final VoidCallback onEditingComplete;
  final bool needCounter;
  final EdgeInsets contentPadding;
  final EdgeInsets nativeContentPadding;
  final Widget prefixIcon;
  final BoxConstraints prefixIconConstraints;
  final double height;
  final TextAlign textAlign;
  final TextInputType keyboardType;
  final bool showSuffixIcon;

  /// 添加这个属性的原因：
  /// 直播添加小助手页面中的搜索框会对前一个页面即创建直播间页面(此页面使用了高斯模糊效果）在绘制
  /// 上会有影响，路由过程中会有很明显的阴影效果，目前不太清楚具体原因，此处让添加小助手页面的搜索
  /// 框单独使用flutter输入框
  /// ---- 其它地方此属性不要使用！ ----
  final bool useFlutter;

  const CustomInputBox({
    @required this.controller,
    this.hintText,
    this.hintStyle,
    this.style,
    this.fillColor,
    this.maxLength,
    this.readOnly = false,
    this.focusNode,
    this.borderRadius = 4,
    this.autofocus = false,
    this.maxLines = 1,
    this.onChange,
    this.onEditingComplete,
    this.needCounter = true,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
    this.nativeContentPadding,
    this.prefixIcon,
    this.prefixIconConstraints,
    this.height,
    this.useFlutter = false,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.showSuffixIcon = true,
  }) : assert(controller != null);

  @override
  _CustomInputBoxState createState() => _CustomInputBoxState();
}

class _CustomInputBoxState extends State<CustomInputBox> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      contentPadding: widget.contentPadding,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        gapPadding: 0,
      ),
      fillColor: widget.fillColor,
      filled: true,
      hintText: widget.hintText,
      hintStyle: widget.hintStyle,
      prefixIcon: widget.prefixIcon,
      prefixIconConstraints: widget.prefixIconConstraints,
      suffixIconConstraints: const BoxConstraints(maxWidth: 50),
      suffixIcon: (widget.showSuffixIcon && _isShowClear && !widget.readOnly)
          ? Center(
              child: IconButton(
                padding: OrientationUtil.portrait
                    ? const EdgeInsets.all(8)
                    : const EdgeInsets.all(2),
                icon: Icon(
                  IconFont.buffClose,
                  size: OrientationUtil.portrait ? 16 : 18,
                  color: const Color(0x7F8F959E),
                ),
                onPressed: () {
                  widget.controller.clear();
                  _onTextChange('');
                },
              ),
            )
          : const SizedBox(),
    );

    if (Config.useNativeInput && !(widget.useFlutter ?? false)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          NativeInput(
            readOnly: widget.readOnly,
            focusNode: widget.focusNode,
            onChanged: _onTextChange,
            autofocus: widget.autofocus,
            controller: widget.controller,
            decoration: decoration.copyWith(
              contentPadding: widget.nativeContentPadding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            ),
            maxLength: widget.maxLength,
            onEditingComplete: widget.onEditingComplete,
            maxLengthEnforcement: widget.maxLength != null
                ? MaxLengthEnforcement.none
                : MaxLengthEnforcement.enforced,
            borderRadius: widget.borderRadius,
            height: widget.height,
          ),
          if (widget.needCounter && widget.maxLength != null) ...[
            sizeHeight6,
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                  padding: EdgeInsets.zero,
                  child: RichText(
                    text: TextSpan(
                        text: '${widget.controller.text.characters.length}',
                        style: Theme.of(context).textTheme.bodyText1.copyWith(
                            fontSize: 12,
                            color: widget.controller.text.characters.length >
                                    widget.maxLength
                                ? DefaultTheme.dangerColor
                                : Theme.of(context).textTheme.bodyText1.color),
                        children: [
                          TextSpan(
                            text: '/${widget.maxLength}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1
                                .copyWith(fontSize: 12),
                          )
                        ]),
                  )),
            )
          ]
        ],
      );
    }

    return TextField(
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      focusNode: widget.focusNode,
      onChanged: _onTextChange,
      autofocus: widget.autofocus,
      controller: widget.controller,
      textAlign: widget.textAlign,
      keyboardType: widget.keyboardType,
      buildCounter: (
        context, {
        currentLength,
        maxLength,
        isFocused,
      }) {
        if (!widget.needCounter) return null;
        if (maxLength == null) return const SizedBox();
        return Container(
            padding: EdgeInsets.zero,
            child: RichText(
              text: TextSpan(
                  text: '$currentLength',
                  style: Theme.of(context).textTheme.bodyText1.copyWith(
                      fontSize: 12,
                      color: currentLength > maxLength
                          ? DefaultTheme.dangerColor
                          : Theme.of(context).textTheme.bodyText1.color),
                  children: [
                    TextSpan(
                      text: '/$maxLength',
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 12),
                    )
                  ]),
            ));
      },
      maxLength: widget.maxLength,
      maxLengthEnforcement: widget.maxLength != null
          ? MaxLengthEnforcement.none
          : MaxLengthEnforcement.enforced,
      decoration: decoration,
      onEditingComplete: widget.onEditingComplete,
      style: widget.style,
    );
  }

  void _onTextChange(String val) {
    setState(() {});
    if (widget.onChange != null) widget.onChange(val);
  }

  bool get _isShowClear => widget.controller.text.trim().isNotEmpty;
}
