import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/model/room_list_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/pages/room_list/user_home_page.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/show_right_dialog.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../utils/func/utils_class.dart';

class AnchorTopView extends StatefulWidget {
  final String? imageUrl;
  final String? anchorName;
  final String? anchorId;
  final String? serverId;
  final int? likesCount;
  final bool isBgColor;
  final bool isScreenRotation;
  final bool isPlayBack; //是否回放
  final LiveInterface? countBloc;
  final VoidCallback? onTap;
  final VoidCallback? onShowDialog;
  final VoidCallback? onCancelDialog;
  final bool isReplace;
  final bool? isAnchor;

  const AnchorTopView(
      {Key? key,
      this.imageUrl,
      this.onTap,
      this.onShowDialog,
      this.onCancelDialog,
      this.anchorName,
      required this.anchorId,
      required this.serverId,
      this.countBloc,
      this.isBgColor = true,
      this.isPlayBack = false,
      this.isAnchor = false,
      this.isReplace = false,
      this.likesCount = 0,
      this.isScreenRotation = false})
      : super(key: key);

  @override
  _AnchorTopViewState createState() => _AnchorTopViewState();
}

class _AnchorTopViewState extends State<AnchorTopView> {
  @override
  Widget build(BuildContext context) {
    return ClickEvent(
      onTap: () async {
        BuildContext? contextValue = context;
        if (!widget.isPlayBack) {
          contextValue = await widget.countBloc!.rotateScreenExec(context);
          if (contextValue == null) {
            return;
          }
          await Future.delayed(const Duration(milliseconds: 80));
          if (FrameSize.isHorizontal()) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
        // 调用用户信息 【不能删除，后期兼容横屏组件需要用到】
        // !FrameSize.isHorizontal()
        //     //竖屏
        //     ? () {

        if (widget.onShowDialog != null) widget.onShowDialog!();
        await showBottomDialog(contextValue,
            widget: SingleChildScrollView(
              child: UserHomePage(
                // isSmartDialog: true,
                isAnchor: widget.isAnchor,
                isReplace: widget.isReplace,
                anchorId: widget.anchorId,
                isDownClose: true,
                item: RoomListModel(
                  okNickName: widget.anchorName,
                  avatarUrl: widget.imageUrl,
                  serverId: widget.serverId,
                ),
              ),
            )).then((value) {
          if (widget.onCancelDialog != null) widget.onCancelDialog!();
        });
        // }()
        //横屏 【不能删除，后期兼容横屏组件需要用到】
        // : () {
        //     if (widget.onShowDialog != null) widget.onShowDialog();
        //     showRightDialog(
        //       contextValue,
        //       widget: Container(
        //         color: Colors.white,
        //         width: FrameSize.winWidth() * (375 / 812),
        //         height: FrameSize.winHeight(),
        //         child: UserHomePage(
        //           anchorId: widget.anchorId,
        //           isHorizontal: true,
        //           isAnchor: widget.isAnchor,
        //           onTap: widget.onTap,
        //           item: RoomListModel(
        //             okNickName: widget.anchorName,
        //             avatarUrl: widget.imageUrl,
        //           ),
        //         ),
        //       ),
        //     ).then((value) {
        //       if (widget.onCancelDialog != null) widget.onCancelDialog();
        //     });
        //   }();
      },
      child: Container(
        width: kIsWeb
            ? FrameSize.px(180)
            : () {
                final minWidth = FrameSize.px(98);
                final maxWidth = FrameSize.px(169);
                final other = 48.px;
                final String text = widget.anchorName ?? " ";
                if (text.isEmpty) {
                  return 0.0;
                }
                final TextPainter textPainter = TextPainter(
                    textDirection: TextDirection.ltr,
                    text: TextSpan(
                      text: text,
                      style: TextStyle(
                          fontSize: FrameSize.px(12),
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1),
                    ),
                    maxLines: 1)
                  ..layout(maxWidth: FrameSize.winWidth() / 2);
                final paintWidth = textPainter.size.width;
                final resultWith = paintWidth + other;
                if (resultWith < minWidth) {
                  return minWidth;
                }
                if (resultWith > maxWidth) {
                  return maxWidth;
                }
                return resultWith;
              }(),
        height: FrameSize.px(36),
        decoration: BoxDecoration(
          color:
              const Color(0x8C000000).withOpacity(widget.isBgColor ? 0.4 : 0),
          borderRadius: BorderRadius.circular(FrameSize.px(20)),
        ),
        child: Row(
          children: [
            SizedBox(width: FrameSize.px(2)),
            anchorImage(),
            SizedBox(width: FrameSize.px(4)),
            Expanded(
              child: Column(
                children: [
                  SizedBox(height: FrameSize.px(4)),
                  anchorNameWidget(),
                  SizedBox(height: FrameSize.px(2)),
                  likesText(),
                  SizedBox(height: FrameSize.px(4)),
                ],
              ),
            ),
            SizedBox(width: FrameSize.px(10)),
          ],
        ),
      ),
    );
  }

  Widget anchorImage() {
    return SizedBox(
      height: FrameSize.px(32),
      width: FrameSize.px(32),
      child: (widget.imageUrl == null || widget.anchorId == null)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(FrameSize.px(16)),
              child: Image(image: fbApi.getFanbookIcon(), fit: BoxFit.cover),
            )
          : fbApi.realtimeAvatar(widget.anchorId!, size: FrameSize.px(32)),
    );
  }

  Widget anchorNameWidget() {
    if (widget.serverId == null || widget.anchorId == null) {
      return nameText(widget.anchorName);
    }
    return FutureBuilder<String>(
      future: fbApi.getShowName(widget.anchorId!, guildId: widget.serverId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return nameText(widget.anchorName);
        } else if (snapshot.hasData && snapshot.data != null)
          return nameText(snapshot.data);
        else
          return nameText(' ');
      },
    );
  }

  Widget nameText(String? name) {
    return Container(
      alignment: Alignment.centerLeft,
      height: FrameSize.px(15),
      child: Text(
        name ?? " ",
        style: TextStyle(
            fontSize: FrameSize.px(12),
            color: Colors.white,
            fontWeight: FontWeight.w600,
            height: 1),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String get endString {
    if (widget.isPlayBack) {
      return '人观看';
    }
    return "个点赞";
  }

  Widget likesText() {
    return SizedBox(
      width: double.infinity,
      height: FrameSize.px(11),
      child: Text(
        widget.likesCount == null
            ? "0$endString"
            : "${UtilsClass.calcNum(widget.likesCount)}$endString",
        textAlign: TextAlign.left,
        style: TextStyle(
            fontSize: FrameSize.px(8),
            color: const Color(0xFFDDDDDD),
            height: 1),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
