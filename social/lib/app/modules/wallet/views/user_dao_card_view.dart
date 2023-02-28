import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/wallet/controllers/user_dao_card_controller.dart';
import 'package:im/app/modules/wallet/controllers/wallet_collect_detail_controller.dart';
import 'package:im/app/modules/wallet/controllers/wallet_home_controller.dart';
import 'package:im/app/modules/wallet/models/wallet_collect_model.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/services/server_side_configuration.dart';
import 'package:im/themes/const.dart';
import 'package:pedantic/pedantic.dart';

import '../../../../icon_font.dart';

/// 描述：用户信息数字藏品展示卡
///
/// author: seven.cheng
/// date: 2022/4/11 16:47
class UserDaoCardView extends StatefulWidget {
  final UserInfo user;

  const UserDaoCardView({Key key, this.user}) : super(key: key);

  @override
  State<UserDaoCardView> createState() => _UserDaoCardViewState();
}

class _UserDaoCardViewState extends State<UserDaoCardView> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserDaoCardController>(
        tag: widget.user.userId,
        init: UserDaoCardController(context, widget.user.userId),
        builder: (controller) {
          // 钱包开关打开后，才能看到别人的nft信息
          return (ServerSideConfiguration.to.walletIsOpen &&
                  controller.collect != null &&
                  controller.collect.collectTotal.isNotEmpty &&
                  int.parse(controller.collect.collectTotal) > 0)
              ? GestureDetector(
                  onTap: () => Get.toNamed(
                    Routes.WALLET_HOME_PAGE,
                    preventDuplicates: false,
                    arguments: WalletHomeController.inputParams(
                      userId: widget.user.userId,
                      userName: widget.user.nickname,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white),
                    margin: const EdgeInsets.only(top: 6, bottom: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(controller.collect.collectTotal),
                        if (controller.collect.collects != null &&
                            controller.collect.collects.isNotEmpty) ...[
                          const Divider(),
                          _buildDao(controller.collect.collects),
                        ]
                      ],
                    ),
                  ),
                )
              : Container();
        });
  }

  /// - 构建标题和藏品数量
  Widget _buildTitle(String collectTotal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '数字藏品'.tr,
            style: appThemeData.textTheme.bodyText2.copyWith(fontSize: 16),
          ),
          Row(
            children: [
              Text(
                collectTotal,
                style: TextStyle(
                  color: Get.theme.disabledColor,
                  fontSize: 15,
                ),
              ),
              sizeWidth4,
              Icon(
                IconFont.buffXiayibu,
                size: 16,
                color: Get.theme.disabledColor.withOpacity(0.4),
              ),
            ],
          )
        ],
      ),
    );
  }

  /// - 构建藏品列表,动态计算item的宽
  Widget _buildDao(List<WalletCollectModel> collects) {
    // - 外部margin - 内部padding - 2个间隙   最多显示3个
    final itemWidth = (Get.width - 32 - 32 - 16) / 3;

    final List<Widget> listWidget = [];
    for (int i = 0; i < collects.length && i < 3; i++) {
      listWidget.add(_assembleCollectGridItem(collects[i], itemWidth));
      listWidget.add(sizeWidth8);
    }
    listWidget.removeLast();

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: listWidget));
  }

  /// 组装视图：藏品 - 藏品列表容器 - item
  Widget _assembleCollectGridItem(WalletCollectModel collect, double width) =>
      GestureDetector(
        onTap: () async {
          //  控制器无法真实被销毁（经常出现， Why？）
          if (Get.isRegistered<WalletCollectDetailController>()) {
            await Get.delete<WalletCollectDetailController>();
          }
          collect.collectorName = widget.user.nickname;
          unawaited(Get.toNamed(
            Routes.WALLET_COLLECT_DETAIL_PAGE,
            preventDuplicates: false,
            arguments: collect,
          ));
        },
        child: Container(
          width: width,
          height: width,
          decoration: BoxDecoration(
            border: Border.all(
              color: appThemeData.dividerColor.withOpacity(0.2),
              width: 0.5,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: ContainerImage(
            collect.displayUrl,
            radius: 4,
            fit: BoxFit.fill,
          ),
        ),
      );
}
