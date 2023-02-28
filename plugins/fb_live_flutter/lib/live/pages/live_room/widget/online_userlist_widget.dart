import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/online_user_list_bloc.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/other/fb_api_model.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/show_right_dialog.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../bloc_model/online_user_count_bloc_model.dart';
import '../../../event_bus_model/sheet_gifts_bottom_model.dart';
import '../../../utils/func/utils_class.dart';
import '../../../utils/manager/event_bus_manager.dart';
import '../../../utils/ui/listview_custom_view.dart';
import 'gifts_choose_widget.dart';

class OnlineUserList extends StatefulWidget {
  final String? roomId;
  final bool? isAnchor;
  final String? onLineCount;
  final bool isScreenRotation;
  final RoomInfon? roomInfoObject;

  const OnlineUserList({
    Key? key,
    this.roomId,
    this.isAnchor,
    required this.roomInfoObject,
    this.onLineCount,
    this.isScreenRotation = false,
  }) : super(key: key);

  @override
  _OnlineUserListState createState() => _OnlineUserListState();
}

class _OnlineUserListState extends State<OnlineUserList> {
  final OnlineUserListBloc _bloc = OnlineUserListBloc();

  @override
  void initState() {
    super.initState();
    _bloc.init(this);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: _bloc,
      builder: (_, __) {
        return kIsWeb
            ? BlocListener<OnlineUserCountBlocModel, int>(
                listener: (context, onLineNum) {
                  _bloc.onRefreshData();
                  _bloc.getBalance();
                },
                child: Container(
                  color: const Color(0xff363940),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      titleView(),
                      Expanded(
                        child: _bloc.userList == null || _bloc.userList!.isEmpty
                            ? Container(
                                height: FrameSize.px(194),
                                alignment: Alignment.center,
                                child: const Text(
                                  "直播久一点就会有更多的观众了",
                                  style: TextStyle(color: Colors.grey),
                                ))
                            : _userListView(),
                      ),
                      if (widget.isAnchor!) Container() else _mineView()
                    ],
                  ),
                ),
              )
            : Container(
                width: MediaQuery.of(context).size.width * (375 / 812),
                height: FrameSize.px(485) + FrameSize.padTopH(),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(12.px)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      titleView(),
                      Expanded(
                        child: _bloc.userList!.isEmpty
                            ? Container(
                                height: FrameSize.px(194),
                                alignment: Alignment.center,
                                child:
                                    defaultTargetPlatform == TargetPlatform.iOS
                                        ? const CupertinoActivityIndicator()
                                        : const CircularProgressIndicator(
                                            strokeWidth: 2),
                              )
                            : _userListView(),
                      ),
                      if (widget.isAnchor!) Container() else _mineView()
                    ],
                  ),
                ),
              );
      },
    );
  }

  Widget titleView() {
    return kIsWeb
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                height: FrameSize.px(50),
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  kIsWeb ? '在线人数 (${_bloc.onlineUserCount ?? 0})' : '在线列表',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: FrameSize.px(14),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _bloc.onRefreshData();
                  _bloc.getMyInfo();
                },
                child: Container(
                  padding: EdgeInsets.only(
                      right: FrameSize.px(16), top: FrameSize.px(17)),
                  height: FrameSize.px(50),
                  child: Text(
                    "刷新",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: FrameSize.px(14),
                      color: const Color(0xff6179F2),
                    ),
                  ),
                ),
              ),
            ],
          )
        : Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(top: 10.px),
            height: FrameSize.px(44),
            child: Text(
              "在线观众",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: FrameSize.px(17),
                color: const Color(0xff1F2125),
              ),
            ),
          );
  }

  Widget rankWidget(String rankStr, bool? isHaveCoin) {
    return Container(
      width: 56.px,
      alignment: Alignment.center,
      child: () {
        return Text(
          () {
            if (rankStr == "0" || int.parse(rankStr) > 200 || !isHaveCoin!) {
              return "-";
            } else {
              return rankStr;
            }
          }(),
          style: TextStyle(
            color: kIsWeb
                ? Colors.white
                : () {
                    /// [2021 12.14] 新需求
                    ///
                    /// 2. 观众榜单一、榜单二、榜单三按照颜色红橙黄区分；其余的排名均为灰色
                    if (rankStr == "1") {
                      return const Color(0xffFE2935);
                    } else if (rankStr == "2") {
                      return const Color(0xffFE6421);
                    } else if (rankStr == "3") {
                      return const Color(0xffF2AF00);
                    }
                    return const Color(0xff8F959E);
                  }(),
            fontSize: FrameSize.px(14),
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        );
      }(),
    );
  }

  Widget _userListView() {
    return SmartRefresher(
        enablePullUp: !_bloc.pageEnd,
        enablePullDown: false,
        header: const WaterDropHeader(),
        footer: CustomFooterView(
          noDataStr: _bloc.userList!.length >= 200 ? "最多仅显示200名观众" : null,
        ),
        controller: _bloc.refreshController,
        // onRefresh: _bloc.onRefreshData,
        onLoading: _bloc.onLoadingData,
        child: ListView.builder(

            /// 处理列表数据长度，最多显示200个
            itemCount: () {
          /// 数据长度
          final int dataCount = (_bloc.userList?.length ?? 0) + 1;

          /// 判断201=200条数据+1个观众信息标题栏
          if (dataCount > 201) {
            return 201;
          } else {
            return dataCount;
          }
        }(), itemBuilder: (context, index) {
          if (index == 0) {
            if (kIsWeb) {
              return Container();
            }
            return _listTitleView();
          }
          final okIndex = index - 1;

          /// 【2021 12.15】解决直播相关bugly问题总结【4】
          final bool isGuest = _bloc.userList![okIndex]['isGuest'] ?? false;
          return Container(
            height: FrameSize.px(58),
            padding: EdgeInsets.fromLTRB(FrameSize.px(0), FrameSize.px(16),
                FrameSize.px(16), FrameSize.px(10)),
            child: Row(children: [
              /// 【Web】Web在线人数列表排名问题
              /// 【2021 12.06】10、在线人数头像和名称不对齐
              () {
                final String rankStr = (okIndex + 1).toString();

                return rankWidget(
                    rankStr, _bloc.userList![okIndex]["coin"] > 0);
              }(),
              ClickEvent(
                  onTap: () async {
                    // 调用用户信息
                    if (!isGuest) {
                      await FbApiModel.showUserInfoPopUp(
                          context,
                          _bloc.userList![okIndex]['userId'],
                          widget.roomInfoObject!.serverId);
                    }
                  },
                  child: fbApi.realtimeAvatar(
                      _bloc.userList![okIndex]['userId'],
                      size: FrameSize.px(32),
                      isGuest: isGuest)),
              SizedBox(width: FrameSize.px(16)),
              Container(
                constraints: BoxConstraints(
                  maxWidth:
                      kIsWeb ? 100 : FrameSize.screenW() - FrameSize.px(180),
                ),
                child: realtimeUserName(
                  _bloc.userList![okIndex]['userId'],
                  style: TextStyle(
                      color: kIsWeb ? Colors.white : Colors.black,
                      fontSize: FrameSize.px(15),
                      fontWeight: FontWeight.w600),
                  isGuest: isGuest,
                  showName: _bloc.userList![okIndex]['nickName'],
                  guildId: widget.roomInfoObject?.serverId ??
                      fbApi.getCurrentChannel()!.guildId,
                ),
              ),
              const Expanded(child: SizedBox(width: double.infinity)),
              Text(
                () {
                  final String coinValue = UtilsClass.calcNumAndThousands(
                      _bloc.userList![okIndex]["coin"] ?? 0);
                  return coinValue;
                }(),
                style: TextStyle(
                  color: kIsWeb ? Colors.white : const Color(0xff8F959E),
                  fontSize: FrameSize.px(14),
                  fontWeight: FontWeight.w600,
                ),
              )
            ]),
          );
        }));
  }

  Widget realtimeUserName(
    String? userId, {
    String? guildId,
    TextStyle? style,
    int maxLines = 1,
    bool? isGuest = false,
    String? showName,
  }) {
    if (isGuest ?? true) {
      return Text(
        showName ?? '游客',
        style: style,
        maxLines: maxLines,
      );
    }
    return Text(
      /// [2021 12.14]新需求
      ///
      /// 3. 观众用户名最多显示11位，多余的...显示
      () {
        if (showName!.length > 11) {
          return "${showName.substring(0, 10)}...";
        }
        return showName;
      }(),
      style: style,
      maxLines: maxLines,
    );
  }

  Widget _listTitleView() {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: FrameSize.px(16)),
      height: FrameSize.px(41),
      color: kIsWeb ? const Color(0xff363940) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: FrameSize.px(60),
            child: Text(
              "观众信息",
              style: TextStyle(
                  fontSize: FrameSize.px(14), color: const Color(0xFF959595)),
            ),
          ),
          SizedBox(
            width: FrameSize.px(30),
            child: Text(
              "乐豆",
              style: TextStyle(
                  fontSize: FrameSize.px(14), color: const Color(0xFF959595)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mineView() {
    final String? mineUserId =
        _bloc.onMyLineRankModel?.userId ?? fbApi.getUserId();
    final int userRanking = _bloc.onMyLineRankModel?.rank ?? 0;
    final bool isGuest = _bloc.onMyLineRankModel?.isGuest ?? false;
    final int coin = _bloc.onMyLineRankModel?.coin ?? 0;
    final String nickName = _bloc.onMyLineRankModel?.nickName ?? "";

    Widget? mineView;
    if (kIsWeb) {
      mineView = Column(
        children: [
          Container(
              padding: EdgeInsets.only(
                  left: FrameSize.px(20), right: FrameSize.px(17)),
              alignment: Alignment.center,
              height: FrameSize.px(76),
              child: Row(children: [
                Text(
                  "${_bloc.onMyLineRankModel?.rank ?? ""}",
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: FrameSize.px(15)),
                ClickEvent(
                  onTap: () async {
                    // 调用用户信息
                    if (!(_bloc.onMyLineRankModel?.isGuest ?? true)) {
                      await FbApiModel.showUserInfoPopUp(
                          context, mineUserId, widget.roomInfoObject!.serverId);
                    }
                  },
                  child: fbApi.realtimeAvatar(mineUserId!,
                      size: FrameSize.px(32), isGuest: isGuest),
                ),
                SizedBox(width: FrameSize.px(10)),
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: 100,
                  ),
                  child: realtimeUserName(
                    mineUserId,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: FrameSize.px(15),
                        fontWeight: FontWeight.w600),
                    isGuest: isGuest,
                    showName: nickName,
                    guildId: widget.roomInfoObject?.serverId ??
                        fbApi.getCurrentChannel()!.guildId,
                  ),
                ),
                const Expanded(child: SizedBox(width: double.infinity)),
                Text(UtilsClass.calcNum(coin).toString(),
                    style: TextStyle(
                        color: Colors.white, fontSize: FrameSize.px(15))),
                SizedBox(
                  width: FrameSize.px(10),
                ),
              ])),
          Container(
              padding: EdgeInsets.only(
                left: FrameSize.px(20),
                right: FrameSize.px(17),
                bottom: 3,
              ),
              child: Row(children: [
                Expanded(
                  child: Wrap(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(
                          bottom: 6,
                        ),
                        child: Text(
                          "余额：",
                          style: TextStyle(
                            color: Color.fromRGBO(139, 139, 139, 1),
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                        ),
                        child: Image.asset(
                          "assets/live/LiveRoom/money.png",
                          width: FrameSize.px(16),
                          height: FrameSize.px(16),
                        ),
                      ),
                      Text(_bloc.balanceValue ?? "0",
                          style: TextStyle(
                            fontSize: FrameSize.px(14),
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => chargeShow(context),
                  child: Container(
                    alignment: Alignment.center,
                    width: FrameSize.px(87),
                    height: FrameSize.px(35),
                    decoration: BoxDecoration(
                        color: const Color(0xFF6179F3),
                        borderRadius:
                            BorderRadius.circular(FrameSize.px(22.5))),
                    child: Text(
                      "送礼",
                      style: TextStyle(
                          color: Colors.white, fontSize: FrameSize.px(14)),
                    ),
                  ),
                )
              ])),
          const SizedBox(height: 10)
        ],
      );
    } else {
      mineView = Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              // 6. 在线人数对话框横线问题@王增阳
              color: const Color(0xFFF4F3FA).withOpacity(0.3),
              offset: const Offset(1, -10),
              blurRadius: 5,
              spreadRadius: 0.5,
            ),
          ],
        ),
        padding: EdgeInsets.only(
            right: FrameSize.px(10),
            top: FrameSize.px(10),
            bottom: FrameSize.px(10)),
        alignment: Alignment.center,
        child: Row(
          children: [
            () {
              final String rankStr = "$userRanking";
              return rankWidget(rankStr, coin > 0);
            }(),
            ClickEvent(
              onTap: () async {
                // 调用用户信息
                if (!isGuest) {
                  await FbApiModel.showUserInfoPopUp(
                      context, mineUserId, widget.roomInfoObject?.serverId);
                }
              },
              child: fbApi.realtimeAvatar(mineUserId!,
                  size: FrameSize.px(32), isGuest: isGuest),
            ),
            SizedBox(width: FrameSize.px(16)),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // 不存在游客，但还是做下处理吧
                  isGuest
                      ? "游客"
                      : () {
                          if (nickName.length > 11) {
                            return "${nickName.substring(0, 10)}...";
                          }
                          return nickName;
                        }(),
                  style: TextStyle(
                      fontSize: FrameSize.px(15), fontWeight: FontWeight.w600),
                  maxLines: 1,
                ),
                Text(
                  () {
                    final String coinValue =
                        UtilsClass.calcNumAndThousands(coin);
                    return coinValue;
                  }(),
                  style: TextStyle(
                      color: const Color(0xff8F959E),
                      fontSize: 12.px,
                      fontWeight: FontWeight.w600),
                ),
              ],
            )),
            GestureDetector(
              onTap: () => chargeShow(context),
              child: Container(
                alignment: Alignment.center,
                width: FrameSize.px(76),
                height: FrameSize.px(32),
                decoration: BoxDecoration(
                    color: const Color(0xFF6179F3),
                    borderRadius: BorderRadius.circular(FrameSize.px(16))),
                child: Text(
                  "送礼",
                  style: TextStyle(
                      color: Colors.white, fontSize: FrameSize.px(14)),
                ),
              ),
            )
          ],
        ),
      );
    }
    return StatefulBuilder(
      key: _bloc.mineKey,
      builder: (_, __) {
        return mineView ?? Container();
      },
    );
  }

  // 送礼弹窗弹起

  void chargeShow(BuildContext context) {
    if (!kIsWeb) {
      RouteUtil.pop();
      EventBusManager.eventBus.fire(SheetGiftsBottomModel(height: 100));
      showQ1Dialog(
        context,
        alignmentTemp:
            // 【不能删除，后期兼容横屏组件需要用到】
            // widget.isScreenRotation
            //     ? Alignment.centerRight
            //     :
            Alignment.bottomCenter,
        widget: SizedBox(
          width:
              // 【不能删除，后期兼容横屏组件需要用到】
              // widget.isScreenRotation
              //     ? FrameSize.winWidth() * (375 / 812)
              //     :
              // 【APP】红米note4X，横屏点击在线人数，显示异常
              FrameSize.minValue(),
          child: ChooseGifts(
            roomId: widget.roomId,
            // 【不能删除，后期兼容横屏组件需要用到】
            // isScreenRotation: widget.isScreenRotation,
            roomInfoObject: widget.roomInfoObject,
          ),
        ),
      );
    } else {
      myFailToast('web版待处理');
    }
  }
}
