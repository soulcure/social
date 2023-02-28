import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';

enum ShowNameRule {
  remark, // 在无备注的情况下，显示平台昵称
  remarkAndGuild, // 在无备注的情况下，显示 服务器昵称 > 平台昵称
}

class RealtimeNickname extends StatefulWidget {
  final String prefix;
  final String suffix;
  final String userId;
  final String guildId;
  final String initName;

  /// 昵称显示规则
  final ShowNameRule showNameRule;

  /// 可否点击
  final bool tapToShowUserInfo;

  /// 是否空显示
  final bool needShowEmpty;

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

  RealtimeNickname({
    Key key,
    @required this.userId,
    this.guildId,
    this.prefix,
    this.suffix,
    this.padding = EdgeInsets.zero,
    this.showNameRule,
    this.showGuildRoleColor = false,
    this.tapToShowUserInfo = false,
    this.needShowEmpty = false,
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
  _RealtimeNicknameState createState() => _RealtimeNicknameState();
}

class _RealtimeNicknameState extends State<RealtimeNickname> {
  String userId;
  ValueListenable userBoxListener;
  ValueListenable remarkBoxListener;
  ValueListenable guildPermissionBoxListener;
  ValueListenable guildRoleBox;

  String get specifiedGuildId =>
      widget.guildId ?? ChatTargetsModel.instance.selectedChatTarget?.id ?? '';

  @override
  void initState() {
    userId = widget.userId;

    /// 如果有必要，触发网络请求
    UserInfo.get(userId);

    if (Db.userInfoBox != null) {
      userBoxListener = Db.userInfoBox.listenable(keys: [userId])
        ..addListener(refresh);

      remarkBoxListener = Db.remarkBox.listenable(keys: [userId])
        ..addListener(refresh);

      guildPermissionBoxListener = Db.guildPermissionBox
          .listenable(keys: [specifiedGuildId])
        ..addListener(refresh);
      if (widget.showGuildRoleColor &&
          specifiedGuildId.hasValue &&
          !GlobalState.isDmChannel) {
        guildRoleBox = Db.guildRoleBox
            .listenable(keys: ['$userId-$specifiedGuildId'])
          ..addListener(refresh);
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!(Db.userInfoBox?.containsKey(userId) ?? false)) {
      return const SizedBox();
    }

    Widget child = Text(
      showName ?? '',
      textScaleFactor: widget.textScaleFactor,
      style: (widget.style ?? Theme.of(context).textTheme.bodyText2)
          .copyWith(color: roleColor),
      maxLines: widget.maxLines,
      textAlign: widget.textAlign,
      overflow: widget.overflow,
      strutStyle: widget.strutStyle,
    );
    if (widget.tapToShowUserInfo) {
      String guildId;
      switch (GlobalState.selectedChannel.value?.type) {
        case ChatChannelType.dm:
          guildId = null;
          break;
        case ChatChannelType.group_dm:
          // 群聊的举报接口需要传入 0，服务台 id 就是 0
          guildId = GlobalState.selectedChannel.value.guildId;
          break;
        default:
          guildId = specifiedGuildId;
          break;
      }

      child = GestureDetector(
        onTap: () {
          return showUserInfoPopUp(
            context,
            userId: widget.userId,
            guildId: guildId,
            channelId: GlobalState.selectedChannel.value?.id,
            showRemoveFromGuild: true,
            enterType:
                GlobalState.selectedChannel.value?.type == ChatChannelType.dm
                    ? EnterType.fromDefault
                    : EnterType.fromServer,
          );
        },
        child: child,
      );
    }

    return needShowEmpty
        ? const SizedBox()
        : Padding(padding: widget.padding, child: child);
  }

  Color get roleColor {
    if (!widget.showGuildRoleColor ||
        !specifiedGuildId.hasValue ||
        GlobalState.isDmChannel)
      return (widget.style ?? Theme.of(context).textTheme.bodyText2).color;
    final roleBean = Db.guildRoleBox.get('$userId-$specifiedGuildId');
    final userInfo = Db.userInfoBox.get(userId);
    return PermissionUtils.getRoleColor(
            roleBean?.roleIds ?? userInfo.roles ?? []) ??
        widget.style?.color ??
        const Color(0xFF646a73);
  }

  bool get needShowEmpty {
    final userInfo = Db.userInfoBox.get(userId);
    // final guildId =
    //     widget.guildId ?? ChatTargetsModel.instance?.selectedChatTarget?.id;
    final guildNickname = userInfo?.guildNickname(specifiedGuildId) ?? '';
    final noGuildNickname = guildNickname.isEmpty;
    final remarkName = Db.remarkBox?.get(userInfo?.userId ?? '')?.name;
    final hasRemarkName = remarkName != null && remarkName.isNotEmpty;
    return (!hasRemarkName && noGuildNickname) && widget.needShowEmpty;
  }

  bool get isDm {
    final bool isDmGuild = widget.guildId == null ||
        widget.guildId.isEmpty ||
        widget.guildId == '0';
    return isDmGuild && GlobalState.isDmChannel;
  }

  ShowNameRule get showNameRule => widget.showNameRule;

  String get showName {
    final userInfo = Db.userInfoBox.get(userId);
    final prefixText = widget.prefix ?? "";
    String nextText;

    final remarkName = Db.remarkBox?.get(userInfo?.userId ?? '')?.name;
    //有备注优先显示备注
    if (remarkName.hasValue) {
      nextText = remarkName;
    } else {
      if (showNameRule == ShowNameRule.remark || isDm) {
        //私信和群聊显示平台昵称
        nextText = userInfo?.nickname;
      } else {
        //有服务台昵称优先服务台昵称，无服务台昵称显示平台昵称
        nextText = userInfo?.showName(guildId: widget.guildId);
      }
    }

    String showName = prefixText + (nextText ?? "") + (widget.suffix ?? "");
    showName = showName ?? "";

    if (widget.maxLength != null && showName.length > widget.maxLength) {
      showName = showName.characters.take(widget.maxLength).toString()..trim();
      showName += "...";
    }
    if (widget.breakWord) {
      showName = showName.breakWord;
    }
    if (showName.isEmpty) {
      showName = widget.initName;
    }
    return showName;
  }

  @override
  void dispose() {
    userBoxListener?.removeListener(refresh);
    remarkBoxListener?.removeListener(refresh);
    guildRoleBox?.removeListener(refresh);
    guildPermissionBoxListener?.removeListener(refresh);
    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }
}
