import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'show_circle_reply_popup.dart';

class InputPlaceholder extends StatelessWidget {
  final BuildContext pageContext;
  final String guildId;
  final String channelId;
  final String hintText;
  final String innerHintText;
  final String commentId;
  final Alignment alignment;

  /// - 是否有回复权限
  final bool hasPermission;

  /// - 是否被禁言中
  final bool isMuted;
  final OnReplySend onReplySend;

  const InputPlaceholder({
    @required this.pageContext,
    this.guildId,
    this.channelId,
    this.hintText = '说点什么...',
    this.innerHintText = '',
    this.commentId,
    this.hasPermission = true,
    this.isMuted = false,
    this.onReplySend,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      // final theme = Theme.of(context);
      // final color1 = theme.scaffoldBackgroundColor;
      return GestureDetector(
        onTap: () {
          if (isMuted || !hasPermission) {
            return;
          }
          showCircleReplyPopup(
            pageContext,
            guildId: guildId,
            channelId: channelId,
            hintText: innerHintText.tr,
            onReplySend: (doc) => onReplySend?.call(doc),
            commentId: commentId,
          );
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 0, 0),
          height: 40,
          child: Container(
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                color: Color(0xFFF5F5F8)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              alignment: (isMuted || !hasPermission)
                  ? Alignment.center
                  : alignment ?? Alignment.center,
              child: Text(
                isMuted
                    ? '禁言中'.tr
                    : hasPermission
                        ? hintText.tr
                        : '你没有回复权限'.tr,
                style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xff8F959E).withOpacity(0.8),
                    height: 1.25),
              ),
            ),
          ),
        ),
      );
    });
  }
}
