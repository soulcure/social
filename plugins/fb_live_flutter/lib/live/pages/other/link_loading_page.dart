import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/link_loading_bloc.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/model/close_audience_room_model.dart';
import 'package:fb_live_flutter/live/model/live/live_simple_model.dart';
import 'package:fb_live_flutter/live/model/room_list_model.dart';
import 'package:fb_live_flutter/live/pages/close_room/close_room_anchor.dart';
import 'package:fb_live_flutter/live/pages/close_room/close_room_audience.dart';
import 'package:fb_live_flutter/live/pages/live_room/decoration/bg_box_decoration.dart';
import 'package:fb_live_flutter/live/pages/live_room/room_middle_page.dart';
import 'package:fb_live_flutter/live/pages/playback/playback_page.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_mode.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/widget_common/loading/ball_circle_pulse_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LinkLoadingPage extends StatefulWidget {
  final String roomId;

  const LinkLoadingPage(this.roomId);

  @override
  _LinkLoadingPageState createState() => _LinkLoadingPageState();
}

class _LinkLoadingPageState extends State<LinkLoadingPage> {
  LinkLoadingBloc linkLoadingBloc = LinkLoadingBloc();

  final LiveValueModel liveValueModel = LiveValueModel();

  @override
  void initState() {
    super.initState();
    linkLoadingBloc.init(this);
  }

  LiveSimpleModel? get model {
    return linkLoadingBloc.model;
  }

  bool get isAnchor {
    return model!.anchorId == fbApi.getUserId();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: linkLoadingBloc,
      builder: (context, _) {
        if (model?.status == null) {
          return UnLoadedPage(model);
        } else if (model?.status == 2) {
          liveValueModel.setRoomInfo(
              roomId: model!.roomId!,
              serverId: model!.serverId!,
              channelId: model!.channelId!,
              roomLogo: model?.roomLogo ?? "",
              status: model!.status!,
              liveType: model!.liveType!,
              roomInfoObject: liveValueModel.roomInfoObject);

          liveValueModel.isAnchor = isAnchor;

          liveValueModel.setObs(model!.liveType == 3);

          final Widget liveRoute = RoomMiddlePage(
            isFromList: false,
            liveValueModel: liveValueModel,
          );
          if (floatWindow.isHaveFloat) {
            if (floatWindow.liveValueModel!.roomInfoObject!.roomId !=
                widget.roomId) {
              return liveRoute;
            }

            return floatWindow.pushToLiveWidget();
          } else {
            return liveRoute;
          }
        } else if (strNoEmpty(model?.replayUrl)) {
          return PlaybackPage(
            RoomListModel(
              okNickName: model!.nickName,
              anchorId: model!.anchorId,
              roomId: model!.roomId,
              roomLogo: model!.roomLogo,
              roomTitle: model!.roomTitle,
              replayUrl: model!.replayUrl,
              serverId: model!.serverId,
              channelId: model!.channelId,
            ),
            isFromList: false,
          );
        } else if (model?.status == 3) {
          final now = DateTime.now();
          final closeDate = DateTime.parse(model!.closeTime!);
          final def = now.difference(closeDate);
          final tipString =
              "直播结束，${def.inMinutes > 10 ? "暂无回放" : "正在生成回放中......请稍后查看"}";
          if (isAnchor) {
            return CloseRoom(
              roomId: model!.roomId,
              tipString: tipString,
              liveValueModel: liveValueModel,
            );
          } else {
            return CloseAudienceRoom(
              roomId: model!.roomId,
              closeAudienceRoomModel: CloseAudienceRoomModel(
                nickName: model!.nickName,
                avatarUrl: model!.avatarUrl,
                roomLogo: model!.roomLogo,
                serverId: model!.serverId,
                userId: model!.anchorId,
              ),
              tipString: tipString,
            );
          }
        }
        return Container(
          height: FrameSize.winHeight(),
          width: FrameSize.winWidth(),
          alignment: Alignment.center,
          child: const Text('出现错误'),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    linkLoadingBloc.close();
  }
}

class UnLoadedPage extends StatelessWidget {
  final LiveSimpleModel? model;

  const UnLoadedPage(this.model);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              height: FrameSize.winHeight(),
              width: FrameSize.winWidth(),
              decoration: const BgBoxDecoration(),
            ),
            Positioned(
              right: 0,
              top: FrameSize.padTopH(),
              child: InkWell(
                onTap: RouteUtil.pop,
                child: Container(
                  margin: EdgeInsets.only(
                      top: 16.px, right: 17.px, left: 17.px, bottom: 16.px),
                  child: Image.asset(
                    'assets/live/main/playback_close.png',
                    width: 20.px,
                    height: 20.px,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: FrameSize.winHeight(),
              width: FrameSize.winWidth(),

              ///  【APP】连接两个不一样的状态
              child: UnconstrainedBox(
                child: IconToastView(
                  "加载中",
                  SizedBox(
                    height: 25.px,
                    width: 25.px,
                    child: BallCirclePulseLoading(
                      radius: 10.px,
                      ballStyle: BallStyle(size: 4.px),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: FrameSize.px(34), vertical: 15.px),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
