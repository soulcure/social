import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/mute_list_bean.dart';
import 'package:im/app/modules/mute/controllers/mute_list_controller.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/refresh/net_checker.dart';
import 'package:im/widgets/refresh/refresh_header.dart';
import 'package:im/widgets/svg_tip_widget.dart';
import 'package:im/widgets/toast.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:im/widgets/user_info/realtime_nick_name.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../icon_font.dart';
import '../../../../svg_icons.dart';

/// - 描述：禁言列表界面
///
/// - author: seven
/// - data: 2021/12/10 11:13 上午
class MuteListPage extends StatefulWidget {
  const MuteListPage({Key key}) : super(key: key);

  @override
  _MuteListPageState createState() => _MuteListPageState();
}

class _MuteListPageState extends State<MuteListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        backgroundColor: Colors.white,
        title: '禁言名单'.tr,
        leadingIcon: IconFont.buffNavBarBackItemNew,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: _buildContent(),
    );
  }

  /// - 构建内容
  Widget _buildContent() {
    return GetBuilder<MuteListController>(
      init: MuteListController.to,
      builder: (controller) {
        final smartRefresher = SmartRefresher(
          enablePullDown: false,
          enablePullUp: true,
          controller: controller.refreshController,
          onRefresh: controller.onRefresh,
          onLoading: controller.onLoadMore,
          header: const RefreshHeader(),
          footer: const CustomFooterView(),
          child: controller.mMuteList.isNotEmpty
              ? ListView.builder(
                  itemBuilder: (context, index) =>
                      _itemView(controller.mMuteList[index], controller),
                  itemCount: controller.mMuteList.length,
                )
              : GestureDetector(
                  onTap: () => MuteListController.to.onRefresh(),
                  child: Center(
                    child: SvgTipWidget(
                      svgName: SvgIcons.nullState,
                      text: '暂无用户'.tr,
                    ),
                  ),
                ),
        );

        return NetChecker(
          futureGenerator: controller.onRefresh,
          retry: () {
            controller.update();
          },
          builder: (_) {
            return smartRefresher;
          },
        );
      },
    );
  }

  /// - 条目
  Widget _itemView(MuteListBean muteBean, MuteListController controller) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              showUserInfoPopUp(
                context,
                userId: muteBean.forbidUserId.toString(),
                guildId: controller.getGuildId(),
                hideGuildName: true,
              );
            },
            child: RealtimeAvatar(
              userId: muteBean.forbidUserId.toString(),
              size: 40,
            ),
          ),
          sizeWidth12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RealtimeNickname(
                  userId: muteBean.forbidUserId.toString(),
                  style: const TextStyle(color: Color(0xFF363940)),
                  guildId: controller.getGuildId(),
                  showNameRule: ShowNameRule.remarkAndGuild,
                ),
                sizeHeight6,
                Text(
                  '%s后解除禁言'
                      .trArgs([controller.getUnMuteTime(muteBean.endtime)]),
                  style: Get.textTheme.bodyText1.copyWith(
                    color: const Color(0xFF8F959E),
                    fontSize: 13,
                  ),
                ),
                sizeHeight4,
                Text(
                  '操作者: %s'.trArgs([muteBean.createUserNickname]),
                  style: Get.textTheme.bodyText1.copyWith(
                    color: const Color(0xFF8F959E),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          sizeWidth12,
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(0),
            ),
            onPressed: () async {
              if (!controller.enableRemove(muteBean)) return;

              final res = await showConfirmDialog(
                content: '确定解除该用户的禁言?'.tr,
                confirmText: '确定解除'.tr,
                confirmStyle: const TextStyle(
                  color: Color(0xFF198CFE),
                  fontSize: 16,
                ),
              );
              if (!res) return;
              final success = await controller.removeFromMuteList(
                  muteBean.forbidUserId.toString(), controller.getGuildId());
              if (success) {
                Toast.iconToast(icon: ToastIcon.success, label: "已解除禁言".tr);
              } else {
                showToast("解除屏蔽失败，请检查网络。".tr);
              }
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(top: 1),
              height: 32,
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: controller.enableRemove(muteBean)
                    ? const Color(0xFF198CFE).withOpacity(0.1)
                    : const Color(0xFF8D93A6).withOpacity(0.1),
              ),
              child: Text(
                '解除'.tr,
                style: Get.textTheme.bodyText1.copyWith(
                  color: controller.enableRemove(muteBean)
                      ? const Color(0xFF198CFE)
                      : const Color(0xFF8D93A6),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    Get.delete<MuteListController>();
  }
}
