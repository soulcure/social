import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:im/widgets/custom_inputbox.dart';

class SearchInputBox extends StatelessWidget {
  final TextEditingController inputController;
  final SearchInputModel searchInputModel;
  final double borderRadius;
  final String hintText;
  final double fontSize;
  final Widget prefixIcon;
  final double iconSize;
  final int maxLength;
  final bool autoFocus;
  final double height; // 原生iOS 需要
  final FocusNode focusNode;

  final bool useFlutter;

  const SearchInputBox({
    Key key,
    this.inputController,
    this.searchInputModel,
    this.borderRadius = 20,
    this.prefixIcon,
    this.hintText = "搜索",
    this.fontSize = 16,
    this.iconSize = 18,
    this.maxLength = 30,
    this.autoFocus = true,
    this.height,
    this.focusNode,
    this.useFlutter = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomInputBox(
      controller: inputController ?? TextEditingController(),
      onChange: _onInput,
      borderRadius: borderRadius,
      autofocus: autoFocus,
      maxLength: 30,
      hintText: hintText.tr,
      hintStyle: TextStyle(
        fontSize: fontSize,
        color: appThemeData.iconTheme.color.withOpacity(0.4),
      ),
      needCounter: false,
      prefixIcon: prefixIcon ??
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              IconFont.buffCommonSearch,
              size: iconSize,
              color: appThemeData.iconTheme.color.withOpacity(0.4),
            ),
          ),
      style: Theme.of(context).textTheme.bodyText2.copyWith(fontSize: fontSize),
      fillColor: const Color(0xFFF5F5F8),
      contentPadding: EdgeInsets.zero,
      nativeContentPadding: const EdgeInsets.only(left: 12, right: 8),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      height: height,
      focusNode: focusNode,
      useFlutter: useFlutter ?? false,
    );
  }

  /// 搜索框输入变化的回调
  void _onInput(String input) {
    searchInputModel?.onInput(input);
  }
}
