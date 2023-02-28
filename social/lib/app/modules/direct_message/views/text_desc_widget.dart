import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/list_extension.dart';
import 'package:im/db/bean/dm_last_message_desc.dart';
import 'package:im/db/bean/last_reaction_item.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/emo_util.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/message_util.dart';
import 'package:im/utils/orientation_util.dart';

import '../../../../icon_font.dart';
import 'doc_link_parser.dart';

class TextDescWidget extends StatelessWidget {
  final DmLastMessageDesc dmLastMessageDesc;
  final ChatChannel channel;
  final bool isMuted;

  const TextDescWidget(this.dmLastMessageDesc, this.channel, this.isMuted,
      {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ((dmLastMessageDesc != null)
          ? descWidget(context, dmLastMessageDesc.lastReaction,
              dmLastMessageDesc.descText(channel))
          : [const Expanded(child: SizedBox())])
        ..add(_buildAtDot(channel))
        ..addAll(_buildIsMuted(channel.id)),
    );
  }

  ///圈子消息频道的副标题：适配艾特和#频道的格式
  Widget getCircleNewsWidget(BuildContext context) {
    final style = appThemeData.textTheme.headline2.copyWith(fontSize: 14);
    return Expanded(
      child: ParsedText(
        style: style,
        text: dmLastMessageDesc?.desc ?? "圈子".tr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        parse: [
          ParsedTextExtension.matchAtText(
            context,
            textStyle: style,
            useDefaultColor: false,
            guildId: channel.recipientGuildId,
            tapToShowUserInfo: false,
            plainTextStyle: true,
            prefix: '',
          ),
          ParsedTextExtension.matchChannelLink(
            context,
            textStyle: style,
            tapToJumpChannel: false,
            hasBgColor: false,
            refererChannelSource: RefererChannelSource.CircleLink,
          ),
        ],
      ),
    );
  }

  ///私信和群聊显示最后一条消息的描述，带@userId 转换
  Widget getDmNewsWidget() {
    final List<String> idList =
        MessageUtil.getUserIdListInText(dmLastMessageDesc?.desc);
    if (idList.hasValue) {
      idList.forEach(UserInfo.get);
      final String desc =
          MessageUtil.getDescStringForDm(dmLastMessageDesc?.desc, atPre: '@');
      return getDescTextWidget(dmLastMessageDesc?.senderId, desc);
    } else {
      return getDescTextWidget(
          dmLastMessageDesc?.senderId, dmLastMessageDesc?.desc);
    }
  }

  Widget getDescTextWidget(String senderId, String text) {
    return Expanded(
      child: DocLinkParser(senderId, text, channel),
    );
  }

  List<Widget> descWidget(
      BuildContext context, List<LastReactionItem> list, String text) {
    final List<Widget> children = [];
    if (channel?.type == ChatChannelType.circlePostNews) {
      children.add(getCircleNewsWidget(context));
      return children;
    }

    if (list != null && list.isNotEmpty) {
      for (int i = list.length - 1; i >= 0; i--) {
        final e = list[i];
        final String value = e.emojiName;
        final int count = e.count;

        final w = emojiWidget(value, count);
        final item = Container(
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: appThemeData.dividerColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
          child: Row(
            //crossAxisAlignment: CrossAxisAlignment.end,
            children: [...w],
          ),
        );

        if (list.length - 1 - i <= 2) {
          children.add(item);
        } else {
          if (list.length > 3) {
            children.add(const Text('...',
                style: TextStyle(color: Color(0xFF8F959E), fontSize: 12)));
            break;
          }
        }
      }

      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: SizedBox(
          width: 1,
          height: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: appThemeData.dividerColor.withOpacity(0.2)),
          ),
        ),
      ));
    }

    children.add(getDmNewsWidget());

    return children;
  }

  Widget _buildAtDot(ChatChannel channel) {
    if (channel.type == ChatChannelType.dm) {
      return const SizedBox();
    }
    return Center(
        child: ChannelUtil.instance.listenAtNum(channel.id, () {
      final numAtMe = ChannelUtil.instance.getAtMessageBean(channel.id).num;
      if (numAtMe > 0)
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: OvalDot(numAtMe,
              beforeText: '@',
              color: primaryColor,
              alignment: Alignment.center),
        );
      else
        return const SizedBox();
    }));
  }

  List<Widget> _buildIsMuted(String id) {
    final List<Widget> list = [];
    if (isMuted) {
      list.add(sizeWidth8);
      list.add(const Opacity(
        opacity: 0.65,
        child: Icon(
          IconFont.buffChannelForbidNotice,
          color: Color(0xFF8F959E),
          size: 15,
        ),
      ));
    }

    return list;
  }

  List<Widget> emojiWidget(String content, int count) {
    final List<Widget> children = [];
    if (EmoUtil.instance.allEmoMap[content] != null) {
      children.add(EmoUtil.instance.getEmoIcon(content, size: 12));
    } else {
      children.add(Text(
        '$content ',
        style: TextStyle(
            color: const Color(0xFF8F959E),
            fontSize: OrientationUtil.portrait ? 14 : 12),
      ));
    }

    if (count != null && count > 1) {
      children.add(SizedBox(
        width: 10,
        height: 10,
        child: Text(
          '$count ',
          style: const TextStyle(color: Color(0xFF8F959E), fontSize: 10),
          textAlign: TextAlign.end,
        ),
      ));
    }

    return children;
  }
}
