import 'package:flutter/cupertino.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/document_online/info/controllers/doc_link_preview_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/tc_doc_utils.dart';

class DocLinkParser extends StatelessWidget {
  final String sendId;
  final String text;
  final ChatChannel channel;

  const DocLinkParser(this.sendId, this.text, this.channel, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
        color: const Color(0xFF8F959E),
        fontSize: OrientationUtil.portrait ? 14 : 12);
    return FutureBuilder(
      future: getText(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            snapshot.data,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          );
        }
        return const SizedBox();
      },
    );
  }

  Future<String> getText() async {
    if (TcDocUtils.docUrlRegFull.hasMatch(text)) {
      //转换腾讯文档链接为文档名称
      final match = TcDocUtils.docUrlRegFull.firstMatch(text)?.group(0);
      if (match != null) {
        final String url = match.toString();
        final hostMatch = TcDocUtils.docUrlReg.firstMatch(url)?.group(0);
        if (hostMatch != null) {
          try {
            String fileId = url.substring(hostMatch.length);
            fileId = Uri.decodeComponent(fileId);

            final String replacement =
                await DocLinkPreviewController.to(fileId).getTitle();

            final int start = text.indexOf(match);
            final int end = start + match.length;
            //转换文档名称后的结果
            final desc = text.replaceRange(start, end, replacement);
            return getSendNickName(channel, sendId, desc);
          } catch (e) {
            print(e);
          }
        }
      }
    }

    //无需转换腾讯文档链接为文档名称
    return getSendNickName(channel, sendId, text);
  }

  Future<String> getSendNickName(
      ChatChannel channel, String userId, String desc) async {
    //是群聊
    if (channel?.type == ChatChannelType.group_dm && userId.hasValue) {
      final userInfo = await UserInfo.get(userId);
      //不是机器人发送的消息
      if (userInfo?.isBot == false) {
        final String name = userInfo?.showName(hideGuildNickname: true);
        //显示发送者昵称
        return '$name: $desc'.breakWord;
      }
    }

    //不显示发送者昵称
    return desc.breakWord;
  }
}
