import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/icon_font.dart';

/// * 圈子详情列表模式下的全部回复
class CircleDetailCommentTotalReply extends StatelessWidget {
  final String totalReplyNum;
  final VoidCallback onTap;
  final bool pinned;

  const CircleDetailCommentTotalReply(
      this.totalReplyNum, this.pinned, this.onTap,
      {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          decoration: BoxDecoration(
            color: appThemeData.backgroundColor,
            boxShadow: pinned
                ? [
                    BoxShadow(
                      color: appThemeData.dividerColor.withOpacity(0.1),
                      offset: const Offset(0, 8),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          height: 40,
          alignment: Alignment.centerLeft,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  '全部回复 %s'.trArgs([totalReplyNum]),
                  style:
                      appThemeData.textTheme.bodyText1.copyWith(fontSize: 14),
                ),
              ),
              Visibility(
                visible: pinned,
                child: Icon(
                  IconFont.buffCircleDetailDown,
                  size: 24,
                  color: appThemeData.dividerColor.withOpacity(0.5),
                ),
              ),
              Positioned(
                  left: 0,
                  right: 0,
                  top: 1,
                  child: Divider(
                    indent: pinned ? 0 : 16,
                    endIndent: pinned ? 0 : 16,
                  )),
            ],
          )));
}
