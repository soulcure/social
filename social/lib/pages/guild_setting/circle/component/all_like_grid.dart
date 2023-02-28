import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/common.dart';
import 'package:im/pages/guild_setting/circle/component/circle_user_nickname.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/icon_linear_fill.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class AllLikeGrid extends StatefulWidget {
  final String postId;
  final String totalCount;
  final String guildId;

  const AllLikeGrid(
    this.postId,
    this.totalCount, {
    this.guildId,
  });

  @override
  _AllLikeGridState createState() => _AllLikeGridState();
}

class _AllLikeGridState extends State<AllLikeGrid> {
  RequestType requestType = RequestType.normal;
  final RefreshController _refreshController = RefreshController();
  CirclePostLikeListDataModel _postLikeListDataModel;

  @override
  void initState() {
    _postLikeListDataModel = CirclePostLikeListDataModel(postId: widget.postId);
    super.initState();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _postLikeListDataModel.initFinish
        ? _buildContentView()
        : _buildLoadingView();
  }

  Future reloadData() async {
    requestType = RequestType.normal;
    await _postLikeListDataModel.initFromNet();
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildLoadingView() {
    final _theme = Theme.of(context);
    return FutureBuilder(
        future: reloadData().timeout(const Duration(seconds: 15)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError) {
            return GestureDetector(
              onTap: () {
                setState(() {});
              },
              child: Container(
                color: _theme.scaffoldBackgroundColor,
                height: 383,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error,
                        color: Colors.red,
                      ),
                      sizeHeight16,
                      Text(
                        snapshot.error is Exception
                            ? (isNetWorkError(snapshot.error)
                                ? '网络异常，请检查网络后重试'.tr
                                : '数据异常，请重试'.tr)
                            : '数据异常，请重试'.tr,
                        style: _theme.textTheme.bodyText1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Container(
              color: _theme.scaffoldBackgroundColor,
              height: 383,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconLinearFill(
                      boxBackgroundColor: _theme.scaffoldBackgroundColor,
                      icon: const Icon(IconFont.buffCircleOfFriends,
                          color: Color(0xff8F959E)),
                      linearColor: _theme.primaryColor,
                    ),
                    sizeHeight16,
                    Text(
                      '正在加载内容...'.tr,
                      style: _theme.textTheme.bodyText1,
                    )
                  ],
                ),
              ),
            );
          }
        });
  }

  Widget _buildContentView() {
    return SizedBox(
      height: 427,
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            height: 44,
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
            child: Text(
              "%s人赞了".trArgs([widget.totalCount.toString()]),
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  .copyWith(fontSize: 14, height: 1),
            ),
          ),
          const Divider(),
          Container(
            height: 383,
            color: Theme.of(context).backgroundColor,
            padding: const EdgeInsets.only(bottom: 32),
            child: SmartRefresher(
              controller: _refreshController,
              enablePullUp: true,
              enablePullDown: false,
              footer: CustomFooter(
                height: 58,
                builder: (context, mode) {
                  return footBuilder(context, mode, requestType: requestType);
                },
              ),
              onLoading: () {
                requestType = RequestType.normal;
                _postLikeListDataModel
                    .needMorePost()
                    .then((value) => setState(() {}))
                    .whenComplete(_refreshController.loadComplete)
                    .catchError((error) {
                  if (Http.isNetworkError(error))
                    requestType = RequestType.netError;
                  else
                    requestType = RequestType.dataError;
                  _refreshController.loadFailed();
                });
              },
              child: SizedBox(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 32,
                    crossAxisSpacing: 18.5,
                    mainAxisSpacing: 19,
                    childAspectRatio: 32 / 55,
                  ),
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 38 / 2),
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final dataModel = _postLikeListDataModel
                        .postListDetailDataModelAtIndex(index);
                    return Column(
                      children: [
                        RealtimeAvatar(
                          userId: dataModel.userId,
                          size: 32,
                          tapToShowUserInfo: true,
                          enterType: EnterType.fromCircle,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          child: CircleUserNickName(
                            dataModel.userId,
                            Theme.of(context)
                                .textTheme
                                .bodyText1
                                .copyWith(fontSize: 12, height: 1.25),
                            nickName: dataModel.nickName,
                            preferentialRemark: true,
                            guildId: widget.guildId,
                          ),
                        ),
                      ],
                    );
                  },
                  itemCount: _postLikeListDataModel.postLikeListCount,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ignore: avoid_annotating_with_dynamic
  bool isNetWorkError(dynamic e) {
    return Http.isNetworkError(e) || e is TimeoutException;
  }
}
