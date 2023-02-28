import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/show_right_dialog.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../model/online_user_count.dart';
import '../../../utils/func/utils_class.dart';
import 'online_userlist_widget.dart';
import 'top_thrid_widegt.dart';

typedef CloseClickBlock = void Function();

class TopRightView extends StatefulWidget {
  final bool? isAnchor; //主播 or  观众
  final OnlineUserCount? onlineUserCountModel; //前三数组
  final List? userOnlineList; //在线用户详情
  final String? roomId;
  final CloseClickBlock? closeClickBlock;
  final bool isScreenRotation; //是否屏幕翻转：默认竖屏false，翻转为横屏true
  final bool isPlayBack; // 是否回放
  final bool isExternal;

  final LiveInterface countBloc;
  final RoomInfon? roomInfoObject;

  const TopRightView(
      {Key? key,
      this.isAnchor = false,
      this.isPlayBack = false,
      this.isExternal = false,
      this.onlineUserCountModel,
      this.roomId,
      required this.roomInfoObject,
      this.userOnlineList,
      required this.countBloc,
      this.closeClickBlock,
      this.isScreenRotation = false})
      : super(key: key);

  @override
  _TopRightViewState createState() => _TopRightViewState();
}

class _TopRightViewState extends State<TopRightView> {
  bool enable = true; //是否翻转摄像头  默认前置

  @override
  Widget build(BuildContext context) {
    if (widget.isPlayBack) {
      return _closeBtn();
    }
    // 如果是主播不显示 X 关闭按钮    // 如果是不是主播显示 X 关闭按钮
    return widget.isAnchor!
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              _rightWidgets(),
              SizedBox(width: FrameSize.px(9)),
              if (kIsWeb)
                Container()
              else
                TopThirdView(
                  dataList: widget.onlineUserCountModel?.users ?? [],
                  roomInfoObject: widget.roomInfoObject,
                  countBloc: widget.countBloc,
                )
            ],
          )
        : Row(
            textDirection: TextDirection.rtl,
            children: [
              _closeBtn(),
              SizedBox(width: FrameSize.px(4)),
              if (kIsWeb) Container() else _onlineCountView(),
              SizedBox(width: FrameSize.px(4)),
              if (kIsWeb)
                Container()
              else
                TopThirdView(
                  dataList: widget.onlineUserCountModel?.users ?? [],
                  roomInfoObject: widget.roomInfoObject,
                  countBloc: widget.countBloc,
                )
            ],
          );
  }

  Widget _closeBtn() {
    return GestureDetector(
      onTap: () {
        if (widget.closeClickBlock != null) {
          widget.closeClickBlock!();
        }
      },
      child: Container(
        alignment: Alignment.center,
        width: FrameSize.px(30),
        height: FrameSize.px(30),
        decoration: BoxDecoration(
          color: const Color(0x8C000000).withOpacity(0.3),
          borderRadius: BorderRadius.circular(FrameSize.px(22.5)),
        ),
        child: Image(
            width: FrameSize.px(20),
            height: FrameSize.px(20),
            image: const AssetImage("assets/live/LiveRoom/close_btn.png")),
      ),
    );
  }

  Widget _rightWidgets() {
    return Column(
      children: [
        if (kIsWeb) Container() else _onlineCountView(),
        SizedBox(height: FrameSize.px(20)),
      ],
    );
  }

  Widget _onlineCountView() {
    /// 【2021 12.30】
    /// 9.在线人数显示数量3位和4位显示优化
    final String _showNumText = widget.onlineUserCountModel?.total == null
        ? "0"
        : UtilsClass.calcNum(widget.onlineUserCountModel?.total);
    return ClickEvent(
      onTap: () async {
        if (!kIsWeb) {
          if (widget.onlineUserCountModel?.total == null ||
              widget.onlineUserCountModel?.total == 0) {
            myToast("暂时无在线用户");
          } else {
            await widget.countBloc.rotationHandle(false);

            /// 防止出现横屏点击后竖屏显示出错
            if (FrameSize.isHorizontal()) {
              await Future.delayed(const Duration(milliseconds: 100));
            }
            await showQ1Dialog(fbApi.globalNavigatorKey.currentContext,
                alignmentTemp: Alignment.bottomCenter,
                widget: SizedBox(
                  width: FrameSize.minValue(),
                  height: FrameSize.px(485),
                  child: OnlineUserList(
                    onLineCount: widget.onlineUserCountModel?.total.toString(),
                    roomId: widget.roomId,
                    isAnchor: widget.isAnchor,
                    roomInfoObject: widget.roomInfoObject,
                  ),
                ));
          }
        }
      },
      child: Container(
        alignment: Alignment.center,
        height: FrameSize.px(30),
        constraints: BoxConstraints(
          minWidth: FrameSize.px(_showNumText.length > 3 ? 40 : 30),
        ),

        /// [2021 12.28]
        /// 3. 在线人数数字，UI调整
        decoration: BoxDecoration(
          color: const Color(0x8C000000).withOpacity(0.4),
          borderRadius: BorderRadius.circular(FrameSize.px(22.5)),
        ),
        child: Text(_showNumText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Colors.white,
                fontSize: FrameSize.px(11),
                fontWeight: FontWeight.w300)),
      ),
    );
  }
}
