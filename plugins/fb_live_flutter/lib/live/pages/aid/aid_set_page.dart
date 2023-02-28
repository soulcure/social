import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/theme/my_theme.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/appbar/navigation_bar.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/my_scaffold.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AidSetPage extends StatefulWidget {
  final List<FBUserInfo>? aids;

  const AidSetPage(this.aids);

  @override
  _AidSetPageState createState() => _AidSetPageState();
}

class _AidSetPageState extends State<AidSetPage> {
  List<FBUserInfo> data = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero).then((value) {
      data = widget.aids ?? [];
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        RouteUtil.pop(data);
        return false;
      },
      child: MyScaffold(
        appBar: const NavigationBar(
          title: '小助手设置',
          isLeftChevron: true,
          mainColor: Color(0xff1F2125),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Space(height: 16.px),
            Material(
              color: Colors.white,
              child: ClickEvent(
                onTap: () async {
                  await fbApi
                      .pushAddAssistantsPage(
                          fbApi.getCurrentChannel()!.guildId, data)
                      .then((value) {
                    if (value != null) {
                      data = value as List<FBUserInfo>;
                      setState(() {});
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(16.px),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/live/main/goods_aid_add.png',
                        width: 20.px,
                        height: 20.px,
                      ),
                      Space(width: 12.px),
                      Text(
                        '添加小助手',
                        style: TextStyle(
                            color: const Color(0xff1F2125), fontSize: 16.px),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Space(height: 20.px),
            Container(
              padding: EdgeInsets.only(top: 6.px, left: 16.px, bottom: 6.px),
              child: Text(
                '已添加',
                style:
                    TextStyle(color: const Color(0xff646A73), fontSize: 14.px),
              ),
            ),
            Expanded(
              child: listNoEmpty(data)
                  ? ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final FBUserInfo item = data[index];
                        return Container(
                          /// 【小助手】小助手点击“X”弹出提示信息，点击取消也把成员删除了
                          /// @王增阳(王增阳)   这个列表样式有问题，左边距白色为通栏
                          /// [2021 11.17]
                          color: Colors.white,
                          child: Container(
                            decoration: BoxDecoration(
                              border: MyTheme.mainBottomBorder(),
                            ),
                            margin: EdgeInsets.only(left: 16.px),
                            child: Row(
                              children: [
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 12.px),
                                  child: CircleAvatar(
                                    /// [ ] 头像名称大小间距跟设计稿不一致
                                    /// 【2021 11.20】
                                    radius: 16.px,
                                    backgroundImage:
                                        swImageProvider(item.avatar),
                                  ),
                                ),
                                Space(width: 12.px),
                                Expanded(
                                  child: Text(
                                    item.name ?? '',
                                    style: TextStyle(
                                        color: const Color(0xff1F2125),
                                        fontSize: 16.px),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Material(
                                  color: Colors.white,
                                  child: ClickEvent(
                                    onTap: () async {
                                      await fbApi
                                          .showActionSheet(
                                        context,
                                        [
                                          Text(
                                            "确定",
                                            style: TextStyle(
                                              color: const Color(0xFF198CFE),
                                              fontSize: 16.px,
                                            ),
                                          ),
                                        ],

                                        /// 【小助手】小助手移除提示信息与需求不一致
                                        /// 【2021 11.17】设计师问题
                                        title: "确定将“${item.name}”从小助手中移除吗？",
                                      )
                                          .then((value) {
                                        ///【小助手】小助手点击“X”弹出提示信息，点击取消也把成员删除了
                                        /// 2021 11.18
                                        if (value == null || value == -1) {
                                          return;
                                        }
                                        data.remove(item);
                                        setState(() {});

                                        /// 【APP】删除成功toast需要改一下
                                        mySuccessToast('移除成功');
                                      });
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12.px, horizontal: 16.px),
                                      child: Image.asset(
                                          'assets/live/main/goods_aid_close.png',
                                          width: 20.px,
                                          height: 20.px),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )

                  /// [ ] @王增阳 小助手管理页面如小助手被删除了则直接不显示列表
                  : Container(),
            )
          ],
        ),
      ),
    );
  }
}
