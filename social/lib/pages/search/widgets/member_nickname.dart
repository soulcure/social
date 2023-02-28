import 'package:flutter/material.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/widgets/highlight_text.dart';

/// 展示成员备注名和服务器昵称，可以高亮展示关键字
class HighlightMemberNickName extends StatelessWidget {
  final UserInfo user;

  final String guildId;

  /// 未高亮文本样式
  final TextStyle contentStyle;

  /// 高亮文本样式
  final TextStyle highlightStyle;

  /// 要高亮显示的关键字
  final String keyword;

  /// 用户名后的标签图标
  final Widget badge;

  const HighlightMemberNickName(
    this.user, {
    Key key,
    this.contentStyle = const TextStyle(color: Color(0xFF1F2329), fontSize: 16),
    this.highlightStyle =
        const TextStyle(color: Color(0xFF1B4EBF), fontSize: 16),
    this.keyword = "",
    this.badge,
    this.guildId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 备注名或原始昵称
    final nickName = user.nickname;
    // 用户备注名
    final markName = user.markName;
    // 用户服务器的昵称
    final guildNickName = user.guildNickname(guildId);
    // 是否展示服务器昵称
    final showGuildNickName = guildNickName.isNotEmpty && markName.isNotEmpty;
    // 展示的用户名，优先级：备注名 > 服务器昵称 > 原昵称
    final userName = markName.isNotEmpty
        ? markName
        : guildNickName.isNotEmpty
            ? guildNickName
            : nickName;
    return LayoutBuilder(
      builder: (context, constraint) {
        final userNameMaxWidth =
            showGuildNickName ? constraint.maxWidth / 2 : constraint.maxWidth;
        return Row(
          children: [
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: userNameMaxWidth),
                child: HighlightText(
                  userName,
                  keyword: keyword,
                  style: contentStyle,
                  highlightStyle: highlightStyle,
                ),
              ),
            ),
            if (user.isBot) ...[
              const SizedBox(
                width: 6,
              ),
              TextChatUICreator.botMark
            ],
            if (badge != null) badge,
            if (showGuildNickName) ...[
              Expanded(
                child: Row(
                  children: [
                    Text(" (", style: contentStyle),
                    HighlightText(
                      guildNickName,
                      keyword: keyword,
                      style: contentStyle,
                      highlightStyle: highlightStyle,
                    ),
                    Text(")", style: contentStyle),
                  ],
                ),
              ),
            ]
          ],
        );
      },
    );
  }
}
