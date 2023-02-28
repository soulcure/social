import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/const.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/modules/circle_search/controllers/circle_search_controller.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/web/widgets/button/web_icon_button.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/certification_icon.dart';

class CircleHeaderWidget extends StatefulWidget {
  const CircleHeaderWidget({Key key}) : super(key: key);

  @override
  _CircleHeaderWidgetState createState() => _CircleHeaderWidgetState();
}

class _CircleHeaderWidgetState extends State<CircleHeaderWidget> {
  CircleController get controller => GetInstance().find();

  bool _isGuildOwner =
      (ChatTargetsModel.instance.selectedChatTarget as GuildTarget).ownerId ==
          Global.user.id;

  @override
  void initState() {
    final GuildPermission gp = PermissionModel.getPermission(
        ChatTargetsModel.instance?.selectedChatTarget?.id);
    if (gp != null) {
      _isGuildOwner = PermissionUtils.oneOf(gp, [Permission.MANAGE_CIRCLES]);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final profile = certificationProfile;
    return GetBuilder<CircleController>(builder: (c) {
      final postCount = int.tryParse(c.circleInfoDataModel?.postsCount ?? '0');
      final memberCount =
          int.tryParse(c.circleInfoDataModel?.memberCount ?? '0');
      return Column(
        children: [
          Container(
            color: Theme.of(context).backgroundColor,
            child: Stack(
              alignment: Alignment.topLeft,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24, left: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(300))),
                            margin: const EdgeInsets.only(right: 16),
                            child: Avatar(
                                url: c.circleInfoDataModel?.circleIcon ?? '',
                                radius: 35),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (profile != null)
                                      CertificationIcon(
                                        margin: const EdgeInsets.only(right: 8),
                                        size: 19.5,
                                        profile: profile,
                                      ),
                                    Text(
                                      c.circleInfoDataModel?.circleName ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Get.textTheme.bodyText2.color),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                _buildInfoRow(
                                    TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Get.textTheme.bodyText2.color),
                                    profile,
                                    postCount,
                                    memberCount),
                                const SizedBox(height: 6),
                                _buildDescription(c.circleInfoDataModel),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RedDot(
                        c.nuReadNewsCount,
                        offset: const Offset(18, 2),
                        borderVisiable: true,
                        child: _buildActionIconButton(
                          IconFont.webCircleNotice,
                          Colors.grey,
                          '消息'.tr,
                          () async {
                            await Routes.pushCircleNewsPage(
                                context, c.circleInfoDataModel.channelId);
                            final result =
                                await CircleApi.circleUnreadNewsCount(
                                    c.circleInfoDataModel.channelId);
                            c.nuReadNewsCount =
                                int.tryParse(result['total'].toString());

                            TextChannelUtil.instance.stream
                                .add(WebCircleClearUnreadEvent());
                            setState(() {});
                          },
                        ),
                      ),
                      _buildActionIconButton(
                          IconFont.buffCommonSearch, Colors.grey, '搜索'.tr, () {
                        Routes.pushCircleSearchPage(
                                context,
                                c.circleInfoDataModel.guildId,
                                c.circleInfoDataModel.channelId)
                            .then((value) {
                          Get.delete<CircleSearchController>(
                              tag: c.circleInfoDataModel.guildId);
                        });
                      }),
                      Visibility(
                        visible: _isGuildOwner,
                        child: _buildActionIconButton(
                          IconFont.webCircleSetUp,
                          Colors.grey,
                          '设置'.tr,
                          () => Routes.pushCircleManagementPage(
                              context, c.circleInfoDataModel),
                        ),
                      ),
                      sizeWidth4,
                    ],
                  ),
                )
              ],
            ),
          ),
          // _buildPinnedDynamics(),
        ],
      );
    });
  }

  Widget _buildActionIconButton(IconData icon, Color color, String decription,
      void Function() onPressed) {
    return Tooltip(
      message: decription,
      child: WebIconButton(
        icon,
        onPressed: onPressed,
        color: color,
        hoverColor: Theme.of(context).textTheme.bodyText2.color,
        highlightColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildDescription(CircleInfoDataModel circleInfo) {
    final style = TextStyle(
        fontSize: 14, color: Get.textTheme.bodyText1.color, height: 1.25);
    final desc = circleInfo?.description ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          IconFont.webCircleExplain,
          size: 16,
          color: Theme.of(context).primaryColor,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              desc.isEmpty ? "暂无简介".tr : desc,
              style: style,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    TextStyle style,
    CertificationProfile profile,
    int postCount,
    int memberCount,
  ) {
    final dynamic = getFormatDynamic(postCount);
    final memberStatistics = getFormatMemberStatistics(memberCount);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile != null) ...[
          Text(profile.description ?? '', style: style),
          const SizedBox(height: 14, child: VerticalDivider(width: 20)),
        ],
        Text.rich(
          TextSpan(children: [
            TextSpan(
                text: dynamic.item1,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Get.textTheme.bodyText2.color)),
            TextSpan(
                text: dynamic.item2,
                style: Get.textTheme.bodyText1.copyWith(fontSize: 14)),
          ]),
        ),
        const SizedBox(height: 14, child: VerticalDivider(width: 20)),
        Text.rich(
          TextSpan(children: [
            TextSpan(
                text: memberStatistics.item1,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Get.textTheme.bodyText2.color)),
            TextSpan(
                text: memberStatistics.item2,
                style: Get.textTheme.bodyText1.copyWith(fontSize: 14))
          ]),
        ),
      ],
    );
  }

// Widget _buildPinnedDynamics() {
//   final List<Widget> pinnedWidgetList = [];
//   for (int i = 0; i < 3; i++) {
//     if (i < controller.pinnedList.length) {
//       final dataModel = controller.pinnedList[i];
//       pinnedWidgetList.add(_buildPinnedDynamic(dataModel));
//     } else {
//       pinnedWidgetList.add(const Flexible(child: SizedBox()));
//     }
//   }
//   return Container(
//     padding: const EdgeInsets.only(left: 9, right: 24, top: 24),
//     color: Theme.of(context).backgroundColor,
//     child: Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: pinnedWidgetList,
//     ),
//   );
// }
//
// Widget _buildPinnedDynamic(CirclePinedPostDataModel dataModel) {
//   final Color color =
//       pinnedDynamicTitleColor[dataModel.typeId] ?? const Color(0xff0073E6);
//
//   final theme = Theme.of(context);
//   return Flexible(
//     child: GestureDetector(
//       onTap: () {
//         Routes.pushCirclePage(context,
//                 extraData: ExtraData(
//                     channelId: dataModel.channelId,
//                     topicId: dataModel.topicId,
//                     postId: dataModel.postId,
//                     commentId: '',
//                     guildId: dataModel.guildId,
//                     extraType: ExtraType.postLike))
//             /*.then((value) {
//           if (value == true || needRefreshWhenPop) {
//             controller.reloadData();
//           }
//         })*/
//             ;
//       },
//       child: Container(
//         margin: const EdgeInsets.only(left: 15),
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         decoration: BoxDecoration(
//             color: theme.scaffoldBackgroundColor.withOpacity(0.5),
//             borderRadius: BorderRadius.circular(8)),
//         height: 48,
//         child: Row(
//           children: [
//             Container(
//               width: 40,
//               height: 28,
//               decoration: BoxDecoration(
//                   color: color, borderRadius: BorderRadius.circular(4)),
//               alignment: Alignment.center,
//               padding: const EdgeInsets.only(bottom: kIsWeb ? 2 : 0),
//               child: Text(
//                 dataModel.typeName,
//                 style: theme.textTheme.bodyText2
//                     .copyWith(color: Colors.white, fontSize: 12),
//               ),
//             ),
//             sizeWidth12,
//             Expanded(
//                 child: Text(dataModel.title.trim(),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: theme.textTheme.bodyText2
//                         .copyWith(fontSize: 14, wordSpacing: 0.28)))
//           ],
//         ),
//       ),
//     ),
//   );
// }
}
