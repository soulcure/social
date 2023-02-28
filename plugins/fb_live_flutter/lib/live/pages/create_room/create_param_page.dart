import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/pages/create_room/widget/create_param_title.dart';
import 'package:fb_live_flutter/live/pages/create_room/widget/theme_tile.dart';
import 'package:fb_live_flutter/live/pages/live_room/room_middle_page.dart';
import 'package:fb_live_flutter/live/pages/live_room/widget/protocol_widget.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/appbar/navigation_bar.dart';
import 'package:fb_live_flutter/live/widget_common/button/small_button.dart';
import 'package:fb_live_flutter/live/widget_common/dialog/sw_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CreateParamPage extends StatefulWidget {
  final String? roomId;
  final String? imageUrl;
  final FBChatChannel liveChannel;
  final LiveValueModel? liveValueModel;

  const CreateParamPage(
    this.roomId,
    this.imageUrl,
    this.liveChannel,
    this.liveValueModel,
  );

  @override
  _CreateParamPageState createState() => _CreateParamPageState();
}

class _CreateParamPageState extends State<CreateParamPage> {
  List<List<String>> data = [];

  LiveValueModel liveValueModel = LiveValueModel();

  @override
  void initState() {
    super.initState();
    if (widget.liveValueModel != null) {
      liveValueModel = widget.liveValueModel!;
    }
  }

  @override
  Widget build(BuildContext context) {
    data = [
      ['URL', liveValueModel.obsModel?.url ?? '为空'],
      ['流名称 (Key)', liveValueModel.obsModel?.secret ?? '为空'],
    ];
    return Scaffold(
      appBar: const NavigationBar(
        isLeftChevron: true,
        title: '直播参数设置',
        mainColor: Color(0xff1F2125),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10.px)),
          ),
          child: Column(
            children: [
              CreateParamBody(data),
              Space(height: 75.px),
              SmallButton(
                height: 40.px,
                width: 184.px,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.all(Radius.circular(20.px)),
                onPressed: () async {
                  await jumpToPage();
                },
                color: Theme.of(context).primaryColor,
                child: const Text(
                  '开始直播',
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
              ),
              Space(height: 19.px),
              ProtocolWidget(),
              Space(height: 73.px),
            ],
          ),
        ),
      ),
    );
  }

  Future jumpToPage() async {
    await confirmSwDialog(
      context,
      title: '提示',
      headTextStyle: const TextStyle(
        fontSize: 18,
        color: Color(0xff1F2125),
      ),
      headTopPadding: 30,
      headBottomPadding: 20,
      textBottomPadding: 29.5,
      text: '请确定外部直播软件已经开始推流，否则观众看到是黑屏',
      contentStyle: const TextStyle(
        fontSize: 16,
        color: Color(0xff8F959E),
      ),
      cancelTextStyle: const TextStyle(fontSize: 16, color: Color(0xff8F959E)),
      onPressed: () async {
        liveValueModel.setRoomInfo(
            roomId: widget.roomId!,
            serverId: fbApi.getCurrentChannel()!.guildId,
            channelId: fbApi.getCurrentChannel()!.id,
            roomLogo: widget.imageUrl ?? "",
            status: 2,
            liveType: 3,
            roomInfoObject: liveValueModel.roomInfoObject);

        liveValueModel.isAnchor = true;

        /// [x] 【2021 11。25】@王增阳 OBS点开始每次会回到创建直播间页面
        await Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => RoomMiddlePage(
                liveValueModel: liveValueModel,
              ),
              settings: const RouteSettings(name: "/liveRoom"),
            ), (route) {
          /// 【2021 11.30】解决obs开播结束页面右上角x无法点击
          return route.settings.name == "roomListRoute" ||
              route.settings.name == "/" ||
              route.settings.name == 'home' ||
              route.settings.name == '/home' ||
              route.settings.name == '/unity-view-page';
        });
      },
    );
  }
}

class CreateParamBody extends StatelessWidget {
  final List<List<String>> data;

  const CreateParamBody(this.data);

  Widget itemBuild(List<String> e) {
    return Padding(
      padding: EdgeInsets.only(left: 36.px, right: 26.px, bottom: 20.px),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            e[0],
            style: TextStyle(
              color: const Color(0xff6D6F73),
              fontSize: 12.px,
              fontWeight: FontWeight.w500,
            ),
          ),
          Space(height: 12.px),
          ThemeTile(e[1]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Space(height: 20.px),
        const CreateParamTitle("步骤一：", "复制参数配置到外部直播工具中"),
        ...data.map<Widget>(itemBuild).toList(),
        Space(height: 16.px),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.px),
          child: HorizontalLine(
            color: const Color(0xff919499).withOpacity(0.2),
          ),
        ),
        Space(height: 18.px),
        CreateParamTitle(
          "步骤二：",
          "配置适合的输出参数",
          detUrl: configProvider.obsExplainUrl,
        ),
        Container(
          padding: EdgeInsets.all(16.px),
          margin: EdgeInsets.only(left: 36.px, right: 26.px),
          decoration: BoxDecoration(
            color: const Color(0xffF2F3F5),
            borderRadius: BorderRadius.all(
              Radius.circular(6.px),
            ),
          ),
          child: Column(
            children: [
              ["输出模式：", "高级"],
              ["比特率：", "1500 Kbps（推荐值）"],
              ["关键帧间隔：", "2（推荐值）"],
              ["配置：", "baseline"],
            ].map((e) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: e[0].toString().contains("配置") ? 0.px : 12.px),
                child: Row(
                  children: [
                    Text(
                      e[0],
                      style: TextStyle(
                          color: const Color(0xff6D6F73), fontSize: 14.px),
                    ),
                    Text(
                      e[1],
                      style: TextStyle(
                          color: const Color(0xff6D6F73),
                          fontSize: 14.px,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
