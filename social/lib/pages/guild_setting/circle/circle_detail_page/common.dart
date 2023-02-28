import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/api/entity/circle_detail_list_bean.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/circle/component/circle_user_avatar.dart';
import 'package:im/pages/guild_setting/circle/component/circle_user_nickname.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/icon_linear_fill.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/utils.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../global.dart';

///回复数
Widget replyNumbers(String totalNum) {
  const color = Color(0xff8F959E);
  return Row(
    children: [
      WebsafeSvg.asset('assets/icon-font/buff/topic_reply.svg',
          width: 14, height: 14, color: color),
      sizeWidth4,
      Text(
        '%s条回复'.trArgs([totalNum.toString()]),
        style: const TextStyle(color: color, fontSize: 14),
      )
    ],
  );
}

///头像
Widget buildAvatar(BuildContext context, UserBean user, CommentBean bean,
    {bool showLikeButton = true, Widget likeButton = sizedBox}) {
  final theme = Theme.of(context);
  final color1 = theme.textTheme.bodyText2.color;
  final color2 = theme.textTheme.bodyText1.color;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (user != null)
        CircleUserAvatar(
          user.userId,
          32,
          avatarUrl: user.avatar,
          tapToShowUserInfo: true,
          cacheManager: CircleCachedManager.instance,
        ),
      sizeWidth12,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleUserNickName(
                user.userId,
                TextStyle(
                    color: color1, fontSize: 13, fontWeight: FontWeight.bold),
                preferentialRemark: true,
                nickName: user.nickname),
            sizeHeight2,
            Text(
              getTime(bean.createdAt),
              style: TextStyle(color: color2, fontSize: 13),
            ),
          ],
        ),
      ),
      if (showLikeButton) likeButton,
    ],
  );
}

///时间转换
String getTime(int time) {
  final date = DateTime.fromMillisecondsSinceEpoch(time);
  return formatDate2Str(date);
}

///点赞按钮
// Widget likeButton(Color color, {double size = 24, bool liked = true}) =>
//     WebsafeSvg.asset(
//         liked ? SvgIcons.svgCircleLikeSelect : SvgIcons.svgCircleLikeUnselect,
//         color: color,
//         width: size);

///上拉加载更多，无数据时的UI
Widget noMoreWidget({bool showDivider = true}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (showDivider) const Divider(height: 1),
      sizeHeight16,
      Center(
          child: Text(
        '没有更多了 '.tr,
        style: const TextStyle(color: Color(0xff8F959E), fontSize: 14),
      )),
      sizeHeight16,
    ],
  );
}

///展示不同文本的上拉加载widget
Widget loadMoreWidget(String text,
    {TextStyle style =
        const TextStyle(color: Color(0xff8F959E), fontSize: 14)}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      sizeHeight16,
      Center(
          child: Text(
        text,
        style: style,
      )),
      sizeHeight16,
    ],
  );
}

Widget footBuilder(BuildContext context, LoadStatus mode,
    {RequestType requestType = RequestType.normal,
    VoidCallback onErrorCall,
    bool showDivider = true,
    bool showIdleWidget = true,
    Widget errorWidget}) {
  Widget body = sizedBox;
  if (mode == LoadStatus.idle) {
    body = showIdleWidget ? noMoreWidget(showDivider: showDivider) : sizedBox;
  } else if (mode == LoadStatus.failed) {
    final errorText =
        requestType == RequestType.netError ? '网络异常，请检查后重试'.tr : '数据异常，请重试'.tr;
    body = errorWidget ?? loadingErrorWidget(onErrorCall, errorText);
  } else if (mode == LoadStatus.canLoading) {
    body = loadMoreWidget('上拉加载更多'.tr);
  } else if (mode == LoadStatus.loading) {
    body = Center(
      child: Container(
        margin: const EdgeInsets.only(top: 15),
        width: 30,
        height: 30,
        child: const CircularProgressIndicator(),
      ),
    );
  } else {
    body = showIdleWidget ? noMoreWidget(showDivider: showDivider) : sizedBox;
  }
  return Container(
    padding: const EdgeInsets.only(bottom: 48),
    child: body,
  );
}

Widget footBuilderNew(BuildContext context, LoadStatus mode,
    {RequestType requestType = RequestType.normal,
    VoidCallback onErrorCall,
    bool showDivider = true,
    bool showIdleWidget = false,
    Widget errorWidget}) {
  Widget body = sizedBox;
  if (mode == LoadStatus.idle) {
    body = showIdleWidget ? noMoreWidget(showDivider: showDivider) : sizedBox;
  } else if (mode == LoadStatus.failed) {
    final errorText =
        requestType == RequestType.netError ? '网络异常，请检查后重试'.tr : '数据异常，请重试'.tr;
    body = errorWidget ?? loadingErrorWidget(onErrorCall, errorText);
  } else if (mode == LoadStatus.noMore) {
    body = noMoreWidget(showDivider: showDivider);
  } else {
    body = Center(
      child: Container(
        margin: const EdgeInsets.all(15),
        width: 16,
        height: 16,
        child: const CircularProgressIndicator(strokeWidth: 1.3),
      ),
    );
  }
  return Container(
    padding: const EdgeInsets.only(bottom: 30),
    child: body,
  );
}

Widget headerBuilderNew(BuildContext context, RefreshStatus mode,
    {RequestType requestType = RequestType.normal,
    VoidCallback onErrorCall,
    bool showDivider = true,
    bool showIdleWidget = true,
    Widget errorWidget}) {
  Widget body = sizedBox;
  if (mode == RefreshStatus.failed) {
    final errorText =
        requestType == RequestType.netError ? '网络异常，请检查后重试'.tr : '数据异常，请重试'.tr;
    body = errorWidget ?? loadingErrorWidget(onErrorCall, errorText);
  } else {
    body = Center(
      child: Container(
        margin: const EdgeInsets.all(15),
        width: 16,
        height: 16,
        child: const CircularProgressIndicator(strokeWidth: 1.3),
      ),
    );
  }
  return Container(
    padding: const EdgeInsets.only(bottom: 30),
    child: body,
  );
}

Widget loadingErrorWidget(VoidCallback onErrorCall, String errorText) {
  return GestureDetector(
    onTap: () => onErrorCall?.call(),
    child: loadMoreWidget(errorText,
        style: TextStyle(color: appThemeData.iconTheme.color, fontSize: 14)),
  );
}

///删除弹窗出来时，显示在头部的文字
Widget popHintText(String userName, String text) {
  const style = TextStyle(fontSize: 14, color: Color(0xff6D6F73));
  return Container(
    padding: const EdgeInsets.only(left: 16, right: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$userName:',
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
        Flexible(
            child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ))
      ],
    ),
  );
}

///弹出删除
Future onSettingPressed(BuildContext context, String commentId, String postId,
    {OnDelCallback onDelete,
    bool isReplyDetailPage = false,
    String level = '1',
    Widget hintText}) async {
  final theme = Theme.of(context);
  final deleteStyle =
      theme.textTheme.bodyText1.copyWith(color: DefaultTheme.dangerColor);
  final List<Widget> actions = [
    if (hintText != null) hintText,
    Text(
      "删除回复".tr,
      style: deleteStyle,
    ),
  ];
  final i = await showCustomActionSheet(actions,
          firstDividerHeight: hintText == null ? 1 : 8) ??
      -1;
  final index = hintText != null ? i - 1 : i;
  switch (index) {
    case 0:
      final actions = [
        Text(
          "确认删除此回复".tr,
          style: deleteStyle,
        ),
      ];
      final i = await showCustomActionSheet(actions);
      if (i == 0) {
        try {
          await CircleApi.deleteReply(commentId, postId, level, toast: false);
          showToast('删除成功'.tr);
          onDelete?.call();
        } catch (e) {
          if (e is Exception)
            onRequestError(e, context, isDetailPage: isReplyDetailPage);
        }
      }
      break;
    default:
      break;
  }
}

///加载框
Widget buildLoadingWidget(BuildContext context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      // ignore: prefer_const_literals_to_create_immutables
      children: [
        // Image.asset('assets/gif/circle_loading.gif', width: 48,height: 48,),
        if (!kIsWeb)
          IconLinearFill(
            boxBackgroundColor: Colors.white,
            icon: const Icon(IconFont.buffCircleOfFriends,
                color: Color(0xff8F959E)),
            // linearColor: const Color(0xff00B853),
            linearColor: Theme.of(context).primaryColor,
            boxHeight: 48,
            boxWidth: 48,
          ),
        sizeHeight24,
        Text(
          '正在加载内容...'.tr,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6D6F73)),
        )
      ],
    ),
  );
}

///页面不存在的布局
Widget buildEmptyLayout(BuildContext context) {
  final CustomColor customColor = CustomColor(context);
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
              color: customColor.backgroundColor7, shape: BoxShape.circle),
          child: const Icon(IconFont.buffCircleOfFriends,
              size: 40, color: Color(0xff919499)),
        ),
        const SizedBox(
          height: 22,
        ),
        Text(
          '抱歉，您访问的页面不存在'.tr,
          style: TextStyle(color: customColor.disableColor),
        ),
      ],
    ),
  );
}

///动态不存在时的处理
// ignore: type_annotate_public_apis
void onRequestError(e, BuildContext context,
    {bool deletePost = false, bool isDetailPage = true}) {
  if (e is! Exception) return;
  if (e is RequestArgumentError) {
    final code = e.code;
    if (code == postNotFound ||
        code == postNotFound2 ||
        code == commentNotFound) {
      showToast(postNotFoundToast);
    } else {
      final errorMes =
          errorCode2Message["$code"] ?? "错误码 %s".trArgs([code?.toString()]);
      showToast(errorMes);
    }
  }
  // String toast = '';
  // bool needPop = false;
  // bool needDelete = false;
  // if (e is RequestArgumentError) {
  //   if (deletePost && (e.code == postNotFound || e.code == postNotFound2 || e.code == commentNotFound)) {
  //     // toast = '动态不存在';
  //     needPop = true;
  //     toast = postNotFoundToast;
  //     needDelete = e.code == postNotFound2;
  //   } else if (!deletePost && e.code == commentNotFound) {
  //     // toast = '评论不存在';
  //     toast = postNotFoundToast;
  //     needPop = false;
  //   } else if (!deletePost &&
  //       (e.code == postNotFound || e.code == postNotFound2)) {
  //     // toast = '动态不存在';
  //     toast = postNotFoundToast;
  //     needPop = true;
  //   }
  // }
  // if (needPop) needRefreshWhenPop = true;
  // if (toast.isNotEmpty && !needDelete) showToast(toast);
  // if (needPop && deletePost && needDelete)
  //   Future.delayed(const Duration(seconds: 1), () {
  //     needRefreshWhenPop = true;
  //     Navigator.of(context).pop(true);
  //     if (!isDetailPage) Navigator.of(context).pop(true);
  //   });
}

///是否有管理圈子的权限
bool hasCircleManagePermission({String guildId}) {
  final GuildPermission gp = PermissionModel.getPermission(
      guildId ?? ChatTargetsModel.instance?.selectedChatTarget?.id);
  if (gp != null) {
    return PermissionUtils.oneOf(gp, [Permission.MANAGE_CIRCLES]);
  }
  return false;
}

/// * 是否有圈子某个topic的某个权限
bool hasCirclePermission(
    {String guildId, String topicId, Permission permission}) {
  final GuildPermission gp = PermissionModel.getPermission(guildId);
  if (gp != null)
    return PermissionUtils.oneOf(gp, [permission], channelId: topicId);
  return true;
}

bool isMyself(String userId) {
  return userId == Global.user.id;
}

Color tapBgColor = const Color(0xff919499).withOpacity(0.2);

enum RequestType { normal, netError, dataError }

typedef OnDelCallback = void Function();
