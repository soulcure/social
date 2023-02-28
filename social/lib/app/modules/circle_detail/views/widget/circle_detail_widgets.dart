import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:im/common/extension/list_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/themes/const.dart';

/// * 圈子详情-艾特用户 View
// ignore: must_be_immutable
class AtUserListView extends StatelessWidget {
  final List<String> atUserIdList;
  final EdgeInsetsGeometry padding;
  final String guildId;
  final bool plainTextStyle;
  final bool tapToShowUserInfo;
  final TextStyle textStyle;
  String atUserIdStr;
  final bool isCircleDetail;

  AtUserListView(
    this.atUserIdList, {
    Key key,
    this.padding,
    this.plainTextStyle = false,
    this.tapToShowUserInfo = true,
    this.guildId,
    this.textStyle,
    this.isCircleDetail = false,
  }) : super(key: key) {
    if (atUserIdList.hasValue) {
      atUserIdStr = atUserIdList.map((e) => '\${@!$e}').join(" ");
      if (isCircleDetail) atUserIdStr = '文中提及 '.tr + atUserIdStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (atUserIdStr.noValue) return sizedBox;
    final child = ParsedText(
      maxLines: 10,
      overflow: TextOverflow.ellipsis,
      style: textStyle,
      text: atUserIdStr,
      regexOptions: const RegexOptions(caseSensitive: false),
      parse: [
        ParsedTextExtension.matchAtText(
          context,
          textStyle: textStyle,
          guildId: guildId,
          tapToShowUserInfo: tapToShowUserInfo,
          plainTextStyle: plainTextStyle,
        ),
      ],
    );

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );
  }
}
