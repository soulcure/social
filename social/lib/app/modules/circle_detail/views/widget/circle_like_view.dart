import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/models/circle_post_like_detail_data_model.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/list_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:oktoast/oktoast.dart';

/// 详情页点赞列表-初始化最多加载个数
int likeInitSize = 5 * 8;

///圈子详情的点赞头像和列表
// ignore: must_be_immutable
class CircleLikeView extends StatelessWidget {
  //单个头像宽度
  double avatarWidth = 32;
  double itemWidth = 43;

  //1行最多8个
  final int rowLength = 8;

  //分页加载个数
  final int nextLength = 10 * 8;

  double gridWidth;
  String postId;

  CircleLikeView(this.postId);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CircleDetailController>(
        tag: postId,
        id: CircleDetailController.idLikeView,
        builder: (c) {
          return Column(
            children: [
              _ownLikeView(c),
              _gridView(c),
              _nextGirdView(c),
              sizeHeight24,
            ],
          );
        });
  }

  /// * 自己的点赞状态
  Widget _ownLikeView(CircleDetailController c) {
    final iLiked = c?.data?.postSubInfoDataModel?.iLiked == '1';
    final likeTotal =
        int.tryParse(c?.data?.postSubInfoDataModel?.likeTotal ?? '0');
    final text = iLiked
        ? (likeTotal == 1
            ? '已点赞'.tr
            : '你和其他%s人已点赞'.trArgs(['${likeTotal - 1}']))
        : '真诚点赞，手留余香'.tr;
    return Container(
        alignment: Alignment.center,
        child: Column(children: [
          const Divider(
            thickness: 0.5,
            indent: 16,
            endIndent: 16,
          ),
          sizeHeight32,
          ValidPermission(
            channelId: c.topicId,
            permissions: [Permission.CIRCLE_ADD_REACTION],
            builder: (hasPermission, isOwner) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _changeLike(hasPermission || isOwner, c);
                },
                child: Icon(
                  iLiked
                      ? IconFont.buffCircleLikeBigSelect
                      : IconFont.buffCircleLikeBigUnselect,
                  size: 60,
                  color: iLiked
                      ? const Color(0xffF2494A)
                      : appThemeData.dividerColor.withOpacity(1),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 0.5,
                  color: appThemeData.dividerColor,
                ),
                sizeWidth10,
                Text(
                  text,
                  style: TextStyle(
                      fontSize: 13,
                      color: appThemeData.dividerColor.withOpacity(1)),
                ),
                sizeWidth10,
                Container(
                  width: 48,
                  height: 0.5,
                  color: appThemeData.dividerColor,
                ),
              ],
            ),
          ),
        ]));
  }

  /// * 点赞gridView
  Widget _gridView(CircleDetailController c) {
    final likeList = c?.data?.postSubInfoDataModel?.likeList;
    if (likeList.noValue) return sizedBox;

    int length = likeList.length;
    if (length >= c.likeShowSize && c.likeShowSize > 0) {
      length = c.likeShowSize;
    }

    itemWidth = (Get.width - 20) / rowLength;
    itemWidth = min(itemWidth, 43);
    avatarWidth = itemWidth - 11;
    if (length < rowLength) {
      gridWidth = itemWidth * length;
    } else {
      gridWidth = itemWidth * rowLength;
    }

    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
      alignment: Alignment.center,
      // color: appThemeData.backgroundColor,
      child: SizedBox(
        width: gridWidth,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: length < rowLength ? length : rowLength, //列数
            // crossAxisSpacing: 11, //水平widget的距离
            // mainAxisSpacing: 8,
          ),
          itemCount: length,
          itemBuilder: (context, index) =>
              _gridItem(context, likeList[index], c.guildId),
        ),
      ),
    );
  }

  Widget _gridItem(BuildContext context, CirclePostLikeDetailDataModel model,
      String guildId) {
    return Center(
      child: RealtimeAvatar(
        userId: model?.userId,
        size: avatarWidth,
        tapToShowUserInfo: true,
        guildId: guildId,
        showBorder: true,
        enterType: EnterType.fromCircle,
      ),
    );
  }

  /// * 点赞头像的下一页
  Widget _nextGirdView(CircleDetailController c) {
    final likeList = c?.data?.postSubInfoDataModel?.likeList;
    final likeTotal = c?.data?.postSubInfoDataModel?.totalLikeNum ?? 0;
    if (likeList.noValue) return sizedBox;
    final likeShowSize = c.likeShowSize;
    bool isExpand = true;
    if (likeShowSize >= likeInitSize) {
      if (likeShowSize >= likeTotal) {
        isExpand = false;
      }
    } else {
      return sizedBox;
    }

    //如果在收缩状态时，要显示
    if (c.likeStatus == LikeStatus.Fold) isExpand = true;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        c?.updateLikeList(nextLength, isExpand);
      },
      child: Container(
        padding: const EdgeInsets.only(top: 5),
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isExpand ? '展开'.tr : '收起'.tr,
              style: TextStyle(
                  fontSize: 13,
                  color: appThemeData.dividerColor.withOpacity(1)),
            ),
            // sizeWidth10,
            // if (c.updateLiking) const CircleLoadingIndicator() else sizeWidth20,
          ],
        ),
      ),
    );
  }

  /// * 点赞或取消点赞
  void _changeLike(bool hasPermission, CircleDetailController c) {
    if (!hasPermission) {
      showToast('你没有此动态的点赞权限'.tr);
      return;
    }
    c?.changeLike();
  }
}

/// * 点赞按钮状态
enum LikeStatus {
  Expand,
  Fold,
}
