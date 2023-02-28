import 'package:fb_live_flutter/live/bloc_model/like_click_bloc_model.dart';
import 'package:fb_live_flutter/live/bloc_model/screen_clear_bloc_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/anchor_top_widgt.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnchorLeftTopWidget extends Positioned {
  final bool isScreenRotation;
  final LiveInterface? bloc;
  final BuildContext context;

  AnchorLeftTopWidget({
    required this.context,
    required this.isScreenRotation,
    required this.bloc,
  }) : super(
          top: !isScreenRotation
              ? FrameSize.padTopHDynamic(context) + FrameSize.px(8)
              : FrameSize.px(8),

          /// 【APP】横竖屏元素BUG:2.主播头像和IM消息没对齐
          /// 12改为14
          left: FrameSize.px(14),
          child: BlocBuilder<ScreenClearBlocModel, bool>(
            builder: (context, clearState) {
              return Offstage(
                offstage: clearState,
                child: BlocBuilder<LikeClickPreviewBlocModel, int?>(
                  builder: (context, likeNum) {
                    final RoomInfon? roomInfoObject = bloc!.getRoomInfoObject;
                    return AnchorTopView(
                      //直播间左上角View
                      countBloc: bloc,
                      isAnchor: bloc.isAnchor,
                      onTap: () {},
                      imageUrl: roomInfoObject?.avatarUrl,
                      anchorName: roomInfoObject?.nickName,
                      anchorId: roomInfoObject?.anchorId,
                      serverId: roomInfoObject?.serverId,
                      likesCount: likeNum,
                      isScreenRotation: isScreenRotation,
                    );
                  },
                ),
              );
            },
          ),
        );
}
