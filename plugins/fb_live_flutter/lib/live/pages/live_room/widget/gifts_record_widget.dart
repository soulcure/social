/*
直播页面礼物记录列表
 */

import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../net/api.dart';
import '../../../utils/func/utils_class.dart';
import '../../../utils/ui/frame_size.dart';
import '../../../utils/ui/listview_custom_view.dart';

class GiftsRecord extends StatefulWidget {
  final String? roomId; //房间ID
  final RoomInfon roomInfoObject;

  const GiftsRecord({Key? key, this.roomId, required this.roomInfoObject})
      : super(key: key);

  @override
  _GiftsRecordState createState() => _GiftsRecordState();
}

class _GiftsRecordState extends State<GiftsRecord> {
  late List _giftsRecordList; //礼物记录列表
  String? result; //礼物总乐豆
  late int pageNum; //S礼物记录页数
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    _giftsRecordList = [];
    pageNum = 1;
    _reloadLoading();
  }

  //获取礼物记录列表
  Future _getGiftsRecordGiftsList(int? pageNum) async {
    final Map giftsRecordData =
        await Api.getGiftsRecordList(widget.roomId, 30, pageNum);
    if (giftsRecordData["code"] == 200) {
      List dataList = giftsRecordData["data"]["result"];
      dataList = await getShowName(dataList, widget.roomInfoObject);
      if (dataList.isNotEmpty) {
        dataList.forEach((element) {
          _giftsRecordList.add(element);
        });

        setState(() {});
        _refreshController.loadComplete();
      } else {
        _refreshController.loadNoData();
      }
    }
  }

  /*
  * 获取真实昵称
  * */
  Future<List> getShowName(List userList, RoomInfon roomInfoObject) async {
    final List<String> userIds = [];
    for (int i = 0; i < userList.length; i++) {
      userIds.add(userList[i]["memberId"]);
    }

    final Map<String?, String> names =
        await fbApi.getShowNames(userIds, guildId: roomInfoObject.serverId);

    for (int i = 0; i < userList.length; i++) {
      if (strNoEmpty(names[userList[i]['memberId']])) {
        userList[i]['nickName'] = names[userList[i]['memberId']];
      }
    }
    return userList;
  }

//获取礼物总数量
  Future _getGiftsCount() async {
    final Map giftsCountData = await Api.getGiftscount(widget.roomId!);
    if (giftsCountData["code"] == 200) {
      setState(() {
        result = giftsCountData["data"];
      });
    }
  }

  //刷新
  void _reloadLoading() {
    pageNum = 1;
    _giftsRecordList = [];
    _getGiftsCount();
    _getGiftsRecordGiftsList(pageNum);
    _refreshController.loadComplete();
  }

  //上拉加载更多
  Future _onLoading() async {
    pageNum++;
    await _getGiftsRecordGiftsList(pageNum);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white,
        constraints: kIsWeb
            ? const BoxConstraints()
            : BoxConstraints.tightFor(height: FrameSize.px(457)),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              _titleView(),
              if (_giftsRecordList.isNotEmpty)
                Expanded(child: _userListView())
              else
                toastView(),
            ],
          ),
        ));
  }

  Widget _titleView() {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.only(
          left: FrameSize.px(15),
          top: FrameSize.px(17),
          right: FrameSize.px(15),
          bottom: FrameSize.px(13)),
      height: FrameSize.px(50),
      color: const Color(0xFFF6F6F6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
              text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: <InlineSpan>[
                TextSpan(
                    text: "本场礼物记录 ",
                    style: TextStyle(
                      color: const Color(0xFFA0A0A0),
                      fontSize: FrameSize.px(14),
                    )),
                TextSpan(
                    text: result == null
                        ? "0"
                        : UtilsClass.calcNum(int.parse(result!)),
                    style: TextStyle(
                        color: const Color(0xFF000000),
                        fontSize: FrameSize.px(14),
                        fontWeight: FontWeight.bold)),
                TextSpan(
                    text: " 乐豆",
                    style: TextStyle(
                        color: const Color(0xFFA0A0A0),
                        fontSize: FrameSize.px(14),
                        fontWeight: FontWeight.w500)),
              ])),
          GestureDetector(
            onTap: _reloadLoading,
            child: Container(
              alignment: Alignment.center,
              child: const Text(
                "刷新",
                style: TextStyle(color: Color(0xFF1A7AFF)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _userListView() {
    return SmartRefresher(
        enablePullDown: false,
        enablePullUp: true,
        header: const WaterDropHeader(),
        footer: const CustomFooterView(),
        controller: _refreshController,
        onLoading: _onLoading,
        child: ListView.builder(
            itemCount: _giftsRecordList.length,
            itemBuilder: (context, index) {
              return Container(
                padding: EdgeInsets.fromLTRB(FrameSize.px(16), FrameSize.px(16),
                    FrameSize.px(16), FrameSize.px(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image(
                        image:
                            NetworkImage(_giftsRecordList[index]["avatarUrl"]),
                        width: FrameSize.px(32),
                        height: FrameSize.px(32),
                        fit: BoxFit.cover,
                      )),
                  SizedBox(width: FrameSize.px(10)),
                  Expanded(
                    child: SizedBox(
                      width: FrameSize.px(170),
                      child: RichText(
                          text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: <InlineSpan>[
                            TextSpan(
                                text: _giftsRecordList[index]["nickName"],
                                style: TextStyle(
                                    color: const Color(0xFF262628),
                                    fontSize: FrameSize.px(15),
                                    fontWeight: FontWeight.w600)),
                            const TextSpan(
                                text: " 送了 ",
                                style: TextStyle(color: Color(0xFF7B7B7B))),
                            TextSpan(
                                text: _giftsRecordList[index]["giftName"]
                                    .toString(),
                                style: TextStyle(
                                    color: const Color(0xFF262628),
                                    fontSize: FrameSize.px(15),
                                    fontWeight: FontWeight.w500)),
                            TextSpan(
                                text:
                                    "x${_giftsRecordList[index]["giftCount"].toString()}\n${UtilsClass.calcNum(_giftsRecordList[index]["giftCount"] * _giftsRecordList[index]["giftPrice"])}乐豆",
                                style: TextStyle(
                                    color: const Color(0xFF262628),
                                    fontSize: FrameSize.px(15),
                                    fontWeight: FontWeight.w500)),
                          ])),
                    ),
                  ),
                  Text(
                      (_giftsRecordList[index]["createdAt"].toString())
                          .substring(11),
                      style: TextStyle(fontSize: FrameSize.px(15)))
                ]),
              );
            }));
  }

  Widget toastView() {
    return Column(
      children: [
        SizedBox(
          height: FrameSize.px(70),
        ),
        Image(
          image: const AssetImage("assets/live/LiveRoom/data_null.png"),
          width: FrameSize.px(72),
          height: FrameSize.px(64),
        ),
        SizedBox(
          height: FrameSize.px(13),
        ),
        Text("粉丝大军正在赶来",
            style: TextStyle(
                color: const Color(0xFFDCDCDC), fontSize: FrameSize.px(14))),
        SizedBox(
          height: FrameSize.px(30),
        ),
        Text(
          "耐心点\n精心准备好\n一会礼物刷到你起飞",
          style: TextStyle(
            color: const Color(0xFFDCDCDC),
            fontSize: FrameSize.px(14),
            height: kIsWeb ? 1.2 : 1,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
