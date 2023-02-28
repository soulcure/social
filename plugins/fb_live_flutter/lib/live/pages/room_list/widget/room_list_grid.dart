import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/utils/func/date.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/dialog_util.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:fb_live_flutter/live/widget_common/label/sw_label.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../model/room_list_model.dart';
import '../../../utils/func/utils_class.dart';
import '../../../utils/ui/frame_size.dart';
import '../../../widget_common/dialog/sw_select_bottom_sheet.dart';
import '../../../widget_common/image/sw_image.dart';

/// RoomListModel为数据模型，int为操作类型
typedef RoomListItemAction = Function(RoomListModel model, int type);

///直播列表-网格
///直播列表-卡片
///直播列表-标签（直播、回放、私密、设置）
///
///
///直播列表-网格
class RoomListGrid extends StatelessWidget {
  final bool isSliver; //是否是Sliver网格
  final List<RoomListModel> list;
  final Widget Function(RoomListModel value) grid; //网格卡片组件方法
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const RoomListGrid(this.list, this.grid,
      {this.isSliver = false, this.shrinkWrap = false, this.physics});

  @override
  Widget build(BuildContext context) {
    final double space = kIsWeb ? 24.px : 4.px;
    final rate = kIsWeb ? 344.px / 190.px : 0.677;
    const count = kIsWeb ? 3 : 2;
    return !isSliver
        ? GridView.builder(
            padding: EdgeInsets.all(space),
            itemCount: list.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: count, //列数
              mainAxisSpacing: space, //主轴间距  上下
              crossAxisSpacing: space, //左右间距
              childAspectRatio: rate,
            ),
            itemBuilder: (context, index) {
              return grid(list[index]);
            },
            shrinkWrap: shrinkWrap,
            physics: physics,
          )
        : SliverGrid.extent(
            maxCrossAxisExtent: kIsWeb
                ? ((FrameSize.winWidth() - 96.px) / count).px
                : FrameSize.px(165),
            childAspectRatio: rate,
            mainAxisSpacing: space,
            crossAxisSpacing: space,
            children: list.map<Widget>(grid).toList(),
          );
  }
}

///直播列表-卡片
class RoomListCard extends StatefulWidget {
  final RoomListModel? item;
  final bool isUserHome;
  final RoomListItemAction onAction;

  const RoomListCard({
    this.item,
    this.isUserHome = false,
    required this.onAction,
  });

  @override
  _RoomListCardState createState() => _RoomListCardState();
}

class _RoomListCardState extends State<RoomListCard> {
  @override
  Widget build(BuildContext context) {
    final double _cardWidth =
        ((FrameSize.winWidth() - FrameSize.px(12)) / 2) - 0.5;
    final double _cardWebWidth = (FrameSize.winWidth() - 96.px) / 3;
    final double _width = kIsWeb ? _cardWebWidth : _cardWidth;
    final double _rate = 268.px / 181.5.px;
    final double _webRate = 344.px / 190.px;

    final bool isCreating =
        widget.item?.isCreating != null && widget.item!.isCreating!;

    return Stack(
      children: [
        //卡片背景图
        Container(
          width: _width,
          height: _width * (kIsWeb ? _webRate : _rate),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            image: DecorationImage(
              fit: BoxFit.cover,
              image: (widget.item?.roomLogo == null
                  ? const AssetImage("assets/live/CreateRoom/placeholder.png")
                  : NetworkImage(
                      widget.item!.roomLogo!)) as ImageProvider<Object>,
            ),
          ),
          child: () {
            //直播列表-直播卡片
            if (widget.item!.openType == 2 && !isCreating)
              return liveCard(false);
            //直播列表-个人主页卡片
            else if (widget.item!.openType == 4 || isCreating)
              return liveCard(true);
            //直播列表-回放专辑卡片
            else if (widget.item!.openType == 3)
              return albumPlaybackCard();
            else
              return Container();
          }(),
        ),

        Container(
          height: FrameSize.px(42),
          decoration: kIsWeb
              ? const BoxDecoration()
              : BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                  ),
                ),
        ),

        ///直播列表卡片-顶部标签：直播卡片、个人主页卡片显示顶部标签；回放专辑卡片不显示顶部标签
        if (widget.item!.openType == 2 ||
            widget.item!.openType == 4 ||
            (widget.item!.openType == 4 && kIsWeb))
          Positioned(
            top: 0,
            child: Padding(
              padding: EdgeInsets.only(left: FrameSize.px(8)),
              child: RoomListLabel(
                isUserHome: widget.isUserHome,
                item: widget.item,
                onAction: widget.onAction,
              ),
            ),
          )
      ],
    );
  }

  ///直播列表的直播卡片、个人主页卡片（我发起的列表卡片）
  ///[isUserHome]false:直播列表的直播卡片；true:个人主页卡片（我发起的列表卡片）

  Widget liveCard(bool isUserHome) {
    return Container(
      padding: EdgeInsets.only(
        left: FrameSize.px(8),
        right: FrameSize.px(8),
        bottom: FrameSize.px(12),
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(4),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black38,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: widget.item!.openType == 3
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.item!.openType == 3) const Spacer(),
          Text(
            widget.item?.roomTitle ?? '',
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Colors.white,
                fontSize: FrameSize.px(15),
                fontWeight: FontWeight.w500),
          ),
          SizedBox(
            height: FrameSize.px(6),
          ),
          if (isUserHome)
            Text(
              () {
                final mil = DateTime.parse(widget.item?.liveTime ?? '0')
                        .millisecondsSinceEpoch ~/
                    1000;
                return MyDate.recentTimeNew(mil);
              }(),
              style: TextStyle(
                fontSize: FrameSize.px(13),
                color: Colors.white.withOpacity(0.65),
              ),
            )
          else
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image(
                    width: FrameSize.px(20),
                    height: FrameSize.px(20),
                    fit: BoxFit.cover,
                    image: (widget.item!.avatarUrl == null
                            ? const AssetImage(
                                "assets/live/CreateRoom/placeholder.png")
                            : NetworkImage(widget.item!.avatarUrl!))
                        as ImageProvider<Object>,
                  ),
                ),
                SizedBox(width: FrameSize.px(4)),
                Expanded(
                  child: Text(
                    widget.item?.okNickName ?? '',
                    style: TextStyle(
                        color: Colors.white,
                        height: 1,
                        fontSize: FrameSize.px(13)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: FrameSize.px(17)),
              ],
            ),
        ],
      ),
    );
  }

  ///回放专辑卡片
  Widget albumPlaybackCard() {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              //阴影部分
              Container(
                height: FrameSize.px(68.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0),
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
              Container(
                width: FrameSize.winWidth(),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(4)),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: FrameSize.px(15),
                  vertical: FrameSize.px(15),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.item?.okNickName ?? '',
                      style: TextStyle(
                        fontSize: FrameSize.px(15),
                        color: const Color(0xff363940),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: FrameSize.px(6)),
                    Text(
                      '专辑·${UtilsClass.calcNum(widget.item?.replayCount ?? 0).toString()}条回放',
                      style: TextStyle(
                        fontSize: FrameSize.px(13),
                        color: const Color(0xff8f959e),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: FrameSize.px(60),
            child: Container(
              decoration: BoxDecoration(
                border:
                    Border.all(color: Colors.white, width: FrameSize.px(1.5)),

                /// 【2021 11.22】修复专辑列表卡片头像不为全圆
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: FrameSize.px(33) / 2,
                backgroundImage: NetworkImage(
                  widget.item?.avatarUrl ??
                      'assets/live/CreateRoom/placeholder.png',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

///直播列表-标签（直播、回放、私密、设置、涉嫌违规、申诉中、申诉）
class RoomListLabel extends StatefulWidget {
  final RoomListModel? item;
  final bool isUserHome;
  final RoomListItemAction onAction;

  const RoomListLabel(
      {this.item, this.isUserHome = false, required this.onAction});

  @override
  _RoomListLabelState createState() => _RoomListLabelState();
}

class _RoomListLabelState extends State<RoomListLabel> {
  TextEditingController controller = TextEditingController();
  Color? pickColor; //私密、设置权限按钮随着卡片背景图颜色更改为黑色或白色
  GlobalKey setKey = GlobalKey();
  GlobalKey privateKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final bool isAnchor = widget.item!.anchorId == fbApi.getUserId(); //用户是否为主播

    final bool isCreating =
        widget.item?.isCreating != null && widget.item!.isCreating!;

    return Container(
      alignment: Alignment.centerLeft,
      width: kIsWeb
          ? (FrameSize.winWidth() - 96.px) / 3
          : ((FrameSize.winWidth() - FrameSize.px(22)) / 2) - 0.5,
      padding: EdgeInsets.only(right: FrameSize.px(isAnchor ? 8 : 0)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //私密标签（移动端）
          if (widget.item!.isPrivate == 1 && !kIsWeb)
            privateLabel(context, true),
          //涉嫌违规标签
          /// 【2022 1.12】
          /// 申诉失败后也是群里那个状态，并不是违规这个
          if (widget.item!.status == 3 || widget.item!.status == 5)
            allegedLabel()
          //申诉中标签
          else if (widget.item!.status == 4)
            complaintLabel()
          //违规标签
          else if (widget.item!.status == 5)
            violationsLabel()
          //直播、回放标签
          else if (widget.item!.openType == 2 ||
              widget.isUserHome ||
              widget.item!.openType == 4)
            liveLabel(isCreating),
          //私密标签（Web端）
          if (widget.item!.isPrivate == 1 && kIsWeb) webPrivateLabel(context),
          if (isAnchor && widget.item!.openType == 4) const Spacer(),
          //设置标签
          if (isAnchor && widget.item!.openType == 4)
            privateLabel(context, false),
        ],
      ),
    );
  }

  ///直播、回放标签
  Widget liveLabel(bool isCreating, [String? label, String? text]) {
    return Container(
      margin: EdgeInsets.only(top: 8.px),
      height: 20.px,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: const Color(0xff000000).withOpacity(0.56),
      ),
      alignment: Alignment.center,
      child: Row(
        children: [
          if (isCreating)
            Container(
              height: 20.px,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: const Color(0xff000000).withOpacity(0.56),
              ),
              child: Text(
                "回放生成中",
                style:
                    TextStyle(color: Colors.white, fontSize: FrameSize.px(12)),
              ),
            )
          else
            Container(
              height: 20.px,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Color(strNoEmpty(label)
                    ? 0xffF24848
                    : widget.item!.openType == 2
                        ? 0xffFF6040
                        : 0xFF198CFE),
              ),
              child: Text(
                label ?? (widget.item!.openType == 2 ? '直播中' : '回放'),
                style:
                    TextStyle(color: Colors.white, fontSize: FrameSize.px(12)),
              ),
            ),
          if (isCreating)
            Container()
          else
            Container(
              height: 20.px,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                text ??
                    '${UtilsClass.calcNum(() {
                      if (widget.item!.openType == 2) {
                        return widget.item?.audience ?? 0;
                      } else {
                        return widget.item?.watchNum ?? 0;
                      }
                    }())}人观看',
                style: TextStyle(
                  fontSize: FrameSize.px(12),
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  ///涉嫌违规标签
  Widget allegedLabel() {
    return liveLabel(false, "回放", "内容违规");
  }

  ///申诉中标签
  Widget complaintLabel() {
    return const SwLabel(
      '申诉中...',
    );
  }

  ///违规标签
  Widget violationsLabel() {
    return const SwLabel('违规');
  }

  ///私密标签(Web端)
  Widget webPrivateLabel(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 5.px, left: 4.px),
      padding: EdgeInsets.symmetric(vertical: 2.5.px, horizontal: 4.px),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3.px),
        color: Colors.black.withOpacity(0.56),
      ),
      child: Row(
        children: [
          SwImage(
            'assets/live/main/channel_lock.png',
            width: 12.px,
            height: 12.px,
            margin: EdgeInsets.only(right: 5.px, top: 2.px),
            color: Colors.white,
          ),
          Text(
            '仅自己可见',
            style: TextStyle(
              fontSize: 12.px,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  ///设置按钮标签、私密标签
  Widget privateLabel(BuildContext context, bool isPrivateLabel) {
    double size = 0;
    if (kIsWeb) {
      size = 32.px;
    } else if (isPrivateLabel) {
      size = 16.px;
    } else {
      size = 20.px;
    }
    return ClickEvent(
      onTap: () async {
        if (isPrivateLabel) {
          //私密标签点击事件
        } else {
          //设置标签点击事件跳出底部弹出框
          //
          //弹出[申诉]
          if (widget.item!.status == 3)
            showSwBottomSheet(
              context,
              ['申诉', '删除', '取消'],
              onTap: (index) => complainAction(context, index, controller),
            );
          else if (widget.item!.status == 5)
            showSwBottomSheet(
              context,
              ['删除', '取消'],
              onTap: (index) => complainAction(context, index + 1, controller),
            );
          else
            //弹出[隐私权限]
            showSwBottomSheet(
              context,
              ['设为${widget.item!.isPrivate == 1 ? '公开' : '仅自己可见'}', '删除', '取消'],
              onTap: (index) => privateAction(context, index),
            );
        }
      },
      child: Container(
        alignment: Alignment.center,
        margin: kIsWeb
            ? EdgeInsets.only(right: 8.px, top: 2.5.px)
            : EdgeInsets.zero,
        padding: kIsWeb
            ? EdgeInsets.zero
            : isPrivateLabel
                ? EdgeInsets.only(
                    left: 5.px,

                    /// 【APP】锁标稍微有一点往上了
                    top: 10.px,
                    right: 7.5.px,
                    bottom: 4.px,
                  )
                : EdgeInsets.only(
                    left: 15.px, bottom: 20.px, top: 8.px, right: 10.px),
        decoration: kIsWeb
            ? BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: StatefulBuilder(
          key: !isPrivateLabel ? setKey : privateKey,
          builder: (context, setState) {
            return SwImage(
              !isPrivateLabel
                  ? 'assets/live/main/ic_more.png'
                  : 'assets/live/main/channel_lock.png',
              color: pickColor ?? Colors.white,
              width: size,
              height: size,
            );
          },
        ),
      ),
    );
  }

  ///设置按钮点击事件
  ///申诉
  Future complainAction(
      BuildContext context, int index, TextEditingController controller) async {
    switch (index) {
      case 0:
        final appealed = await Api.playbackIsAppeal(widget.item!.roomId);
        appealed['code'] == 200
            ? await playbackAppeal(controller.text, true)
            : await DialogUtil.submitComplaint(context, widget.item);
        break;
      case 1:
        await DialogUtil.commonBottomMenu(context, onConfirm: () {
          actionHandle(1);
        });
        break;
      case 2:
        break;
    }
  }

  /*
  * 回放处理事件-提交到服务端
  * index 0=普通操作；1=删除
  * */
  Future actionHandle(int index) async {
    int _actionIndex;
    if (index == 1) {
      //删除
      _actionIndex = 3;
    } else if (widget.item!.isPrivate == 1) {
      // 全部可见
      _actionIndex = 1;
    } else {
      // 自己可见
      _actionIndex = 2;
    }
    final _result =
        await Api.playbackSetVisible(_actionIndex, widget.item!.roomId);
    if (_result['code'] == 200) {
      if (index == 1) {
        mySuccessToast('删除成功');
        widget.onAction(widget.item!, index);
        return;
      }
      if (widget.item!.isPrivate == 1) {
        // 全部可见操作后
        widget.item!.isPrivate = 2;
      } else {
        // 自己可见操作后
        widget.item!.isPrivate = 1;
      }
      mySuccessToast('设置成功');
      widget.onAction(widget.item!, index);
    } else {
      myFailToast(_result['msg'] ?? '设置失败');
    }
  }

  /*
  *回放申诉提交
  * */
  Future playbackAppeal(String reason, bool isAgain) async {
    if (!strNoEmpty(reason) && !isAgain) {
      myFailToast('请输入申诉原因');
      return;
    }
    Map? _result;
    if (!isAgain) {
      _result = await Api.playbackAppeal(widget.item!.roomId, reason);
    } else {
      _result = await Api.playbackIsAppeal(widget.item!.roomId);
    }
    if (_result!['code'] == 200) {
      await DialogUtil.complaintReceive(context, isAgain);
    } else {
      myToast(_result['msg']);
    }
  }

  ///隐私权限点击事件
  void privateAction(BuildContext context, int index) {
    switch (index) {
      case 0:
        actionHandle(index);
        break;
      case 1:
        DialogUtil.commonBottomMenu(context, onConfirm: () {
          actionHandle(1);
        });
        break;
      case 2:
        break;
    }
  }
}
