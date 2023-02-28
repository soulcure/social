import 'package:fb_live_flutter/live/bloc/create_room_bloc.dart';
import 'package:fb_live_flutter/live/pages/create_room/widget/select_channel_dialog.dart';
import 'package:fb_live_flutter/live/pages/create_room/widget_web/create_field_widget.dart';
import 'package:fb_live_flutter/live/pages/detection/detection_page.dart'
    if (dart.library.html) "package:im/live/pages/detection/detection_page_web.dart";
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/theme/my_theme.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/button/theme_button.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/my_scaffold.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:fb_live_flutter/live/widget_common/sw_list_tile.dart';
import 'package:fb_live_flutter/live/widget_common/web/web_title.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'widget_web/create_title_widget.dart';

class CreateRoomWeb extends StatefulWidget {
  final String nickName;

  const CreateRoomWeb({Key? key, required this.nickName}) : super(key: key);

  @override
  _CreateRoomWebState createState() => _CreateRoomWebState();
}

class _CreateRoomWebState extends State<CreateRoomWeb> {
  final CreateRoomBloc _createRoomBloc = CreateRoomBloc();

  static final double _coverHeight = 80.px;

  final TextEditingController _titleC = TextEditingController(text: "web");
  final TextEditingController _channelC =
      TextEditingController(text: '我是自动选择的频道');

  bool isExternal = true;
  bool isPrivacy = false;

  /*
  * 隐私设置和外部推流设置选项
  * */
  List<List> items = [
    ['直播间隐私配置', '分享后，允许游客在Fanbook外观看', CreateRoomItemType.privacy],
  ];

  @override
  void initState() {
    super.initState();
    _createRoomBloc.initBloc(creteRoomWeb: this);
  }

  Widget switchBuild(List e) {
    return SwListTileOld(
      inBorder: Border(
        bottom: BorderSide(
          color: e[0] == '直播间隐私配置'
              ? Colors.grey.withOpacity(0.5)
              : Colors.transparent,
          width: 0.5,
        ),
      ),
      inPadding: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(0),
      title: Text(
        e[0],
        style: TextStyle(
            color: const Color(0xff1F2125), fontSize: FrameSize.px(16)),
      ),
      subtitle: Text(
        e[1],
        style: TextStyle(
            color: const Color(0xff8F959E), fontSize: FrameSize.px(14)),
      ),
      trailing: StatefulBuilder(
        builder: (context, refreshState) {
          final bool isOut = e[0].toString().contains('外部');
          return CupertinoSwitch(
            value: isOut ? isExternal : isPrivacy,
            onChanged: (value) {
              if (isOut) {
                isExternal = value;
              } else {
                isPrivacy = value;
              }

              /// 最简单的局部刷新
              refreshState(() {});
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      body: ListView(
        padding: EdgeInsets.all(20.px),
        children: [
          const WebTitle("创建直播间"),
          Space(height: 16.px),
          const CreateTitleWidget('直播封面'),
          Row(
            children: [
              SwImage(
                "https://hbimg.huabanimg.com/7e1c3ced0365ac921c4c224f4b37f928ca6fc2df2cdb68-zJwvfw_fw1200",
                width: 142.px,
                height: _coverHeight,
              ),
              Space(height: 16.px),
              SizedBox(
                height: _coverHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "服务器封面图\n建议尺寸为1560x1056px ",
                      style: TextStyle(
                          color: const Color(0xff8F959E), fontSize: 12.px),
                    ),
                    ThemeButtonWeb(
                      text: '上传图片',
                      onPressed: () {},
                    )
                  ],
                ),
              )
            ],
          ),
          const CreateTitleWidget('直播间标题'),
          CreateFieldWidget(
            hintText: '输入频道名称',
            controller: _titleC,
            maxLength: 30,
          ),
          const CreateTitleWidget('开播频道'),
          CreateFieldWidget(
            hintText: '直播频道名称',
            controller: _channelC,
            enable: false,
            onTap: () {
              FocusManager.instance.primaryFocus!.unfocus();
              selectChannelDialog(context).then((value) {
                _channelC.text = value;
              });
            },
            isArrow: true,
          ),
          Space(height: 32.px),
          const HorizontalLine(color: Color(0xffDEE0E3), height: 1),
          Space(height: 30.px),
          Column(children: items.map(switchBuild).toList()),
          Space(height: 60.px),
          ButtonBar(
            children: [
              const ThemeButtonWeb(
                text: '取消',
                onPressed: RouteUtil.pop,
              ),
              ThemeButtonWeb(
                text: '下一步',
                btColor: MyTheme.themeColor,
                onPressed: () {
                  if (!strNoEmpty(_titleC.text)) {
                    myFailToast("请输入直播间标题");
                    return;
                  }
                  RouteUtil.push(context,
                      DetectionPage(roomTitle: _titleC.text), 'DetectionPage',
                      isReplace: true);
                },
              )
            ],
          )
        ],
      ),
    );
  }
}
