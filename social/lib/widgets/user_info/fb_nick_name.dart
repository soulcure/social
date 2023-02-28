import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

bool isShowNick(String guildId, String userId) {
  final remarkName = Db.remarkBox?.get(userId)?.name;

  final userInfo = Db.userInfoBox.get(userId);
  final guildNickname = userInfo?.guildNickname(guildId) ?? '';

  if (remarkName.hasValue || guildNickname.hasValue) {
    //有备注或服务器昵称 显示此昵称widget
    return true;
  }
  return false;
}

class FBNickname extends StatelessWidget {
  final String prefix;
  final String suffix;
  final String userId;
  final String guildId;
  final String initName;

  /// 可否点击
  final bool tapToShowUserInfo;

  /// 是否显示角色颜色
  final bool showGuildRoleColor;

  final int maxLength;
  final bool breakWord;

  /// Text Widget attribute
  final TextOverflow overflow;
  final TextStyle style;
  final double textScaleFactor;
  final TextAlign textAlign;
  final StrutStyle strutStyle;
  final int maxLines;
  final EdgeInsets padding;

  FBNickname({
    Key key,
    @required this.userId,
    this.guildId,
    this.prefix,
    this.suffix,
    this.padding = EdgeInsets.zero,
    this.showGuildRoleColor = false,
    this.tapToShowUserInfo = false,
    this.maxLength,
    this.breakWord = false,
    this.initName = '',

    /// Text Widget attribute
    this.overflow = TextOverflow.ellipsis,
    this.textScaleFactor,
    this.style,
    this.textAlign,
    this.strutStyle,
    this.maxLines = 1,
  })  : assert(userId != null, "user id could not be null"),
        super(key: key ?? (userId == null ? null : ValueKey(userId)));

  @override
  Widget build(BuildContext context) {
    if (!(Db.userInfoBox?.containsKey(userId) ?? false)) {
      return const SizedBox();
    }

    final Widget child = Text(
      showName ?? '',
      textScaleFactor: textScaleFactor,
      style: (style ?? Theme.of(context).textTheme.bodyText2)
          .copyWith(color: const Color(0xFF646a73)),
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow,
      strutStyle: strutStyle,
    );

    return Padding(padding: padding, child: child);
  }

  bool get isDm {
    final bool isDmGuild = guildId == null || guildId.isEmpty || guildId == '0';
    return isDmGuild && GlobalState.isDmChannel;
  }

  String get showName {
    final remarkName = Db.remarkBox?.get(userId)?.name;

    final userInfo = Db.userInfoBox.get(userId);
    final guildNickname = userInfo?.guildNickname(guildId) ?? '';

    final prefixText = prefix ?? "";

    bool hideGuildNickname = true;

    if (!isDm && remarkName.hasValue && guildNickname.hasValue) {
      //服务台，有备注和服务器昵称，显示服务器昵称
      hideGuildNickname = false;
    }

    final String nextText = userInfo?.showName(
        guildId: guildId,
        hideRemarkName: true,
        hideGuildNickname: hideGuildNickname);

    final String showName = prefixText + (nextText ?? "") + (suffix ?? "");
    return showName;
  }
}
