import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/black_list/black_item.dart';
import 'package:im/app/modules/black_list/black_list_api.dart';
import 'package:im/app/modules/black_list/controllers/black_list_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/svg_tip_widget.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class BlackListPage extends GetView<BlackListController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: CustomAppbar(
        title: '黑名单'.tr,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return GetBuilder(
      init: BlackListController(),
      builder: (c) {
        if (c.users.isEmpty) {
          if (c.noData)
            return _emptyList();
          else
            return _initStatus();
        }
        return _buildList(c.users);
      },
    );
  }

  /// 加载中
  Widget _initStatus() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 100),
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }

  /// 没有成员
  Widget _emptyList() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: SvgTipWidget(
          svgName: SvgIcons.nullState,
          text: '暂无成员'.tr,
        ),
      ),
    );
  }

  ///有成员
  Widget _buildList(List<BlackItem> users) {
    return SmartRefresher(
      enablePullDown: false,
      enablePullUp: true,
      controller: controller.refreshController,
      onLoading: controller.onLoading,
      footer: CustomFooter(
        builder: (context, mode) {
          if (mode == LoadStatus.idle) {
            return sizedBox;
          } else if (mode == LoadStatus.loading) {
            return const CupertinoActivityIndicator.partiallyRevealed(
                radius: 8);
          } else if (mode == LoadStatus.failed) {
            return const Icon(Icons.error, size: 20, color: Colors.grey);
          } else if (mode == LoadStatus.canLoading) {
            return sizedBox;
          } else if (mode == LoadStatus.noMore) {
            return Column(
              children: [
                SizedBox(
                  height: 46,
                  child: Center(
                    child: Text("没有更多了".tr,
                        style: const TextStyle(
                            color: Color(0xFF8F959E), fontSize: 14)),
                  ),
                ),
                SizedBox(height: Get.mediaQuery.padding.bottom),
              ],
            );
          } else {
            return sizedBox;
          }
        },
      ),
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 12),
        shrinkWrap: true,
        itemCount: users.length,
        itemBuilder: (context, index) {
          return _item(context, users[index]);
        },
        separatorBuilder: (context, index) {
          return const Divider(
            height: 12,
            thickness: 12,
            color: Color(0xFFF5F6FA),
          );
        },
      ),
    );
  }

  Widget _item(BuildContext context, BlackItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(children: [
            InkWell(
                onTap: () {
                  showUserInfoPopUp(context,
                      userId: item.userId, showRemoveMember: false);
                },
                child: RealtimeAvatar(userId: item.userId, size: 32)),
            sizeWidth12,
            Expanded(
                child: RealtimeNickname(
              userId: item.userId,
              showNameRule: ShowNameRule.remarkAndGuild,
              style: const TextStyle(color: Color(0xFF1F2126)),
            )),
            SizedBox(
              width: 60,
              height: 32,
              child: ElevatedButton(
                  onPressed: () async {
                    await _checkKickOut(item);
                  },
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.pressed)) {
                        return const Color(0x40198CFE);
                      }
                      return const Color(0x1A198CFE);
                    }),
                  ),
                  child: Text(
                    '解除'.tr,
                    style:
                        const TextStyle(color: Color(0xFF198CFE), fontSize: 14),
                  )),
            )
          ]),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '操作者:'.tr,
                style: const TextStyle(color: Color(0xBF5C6273), fontSize: 14),
              ),
              const SizedBox(width: 4),
              FutureBuilder(
                  future: item.createName(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        snapshot.data,
                        style: const TextStyle(
                            color: Color(0xBF5C6273), fontSize: 14),
                      );
                    } else {
                      return const SizedBox();
                    }
                  }),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '操作时间:'.tr,
                style: const TextStyle(color: Color(0xBF5C6273), fontSize: 14),
              ),
              const SizedBox(width: 4),
              Text(
                item.createTime,
                style: const TextStyle(color: Color(0xBF5C6273), fontSize: 14),
              ),
            ],
          ),
          if (item.blackReason.hasValue) const SizedBox(height: 6),
          if (item.blackReason.hasValue)
            Row(
              children: [
                Text(
                  '备注:'.tr,
                  style:
                      const TextStyle(color: Color(0xFF1F2126), fontSize: 14),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.blackReason,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Color(0xFF1F2126), fontSize: 14),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _checkKickOut(BlackItem item) async {
    await Get.bottomSheet<bool>(_bottomSheet(item));
  }

  Widget _bottomSheet(BlackItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.white),
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 24),
            child: Text('确定将用户从黑名单中解除？解除后该用户可加入服务器'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8D93A6), fontSize: 14)),
          ),
          const Divider(),
          InkWell(
            onTap: () async {
              final bool res =
                  await BlackListApi.removeBlackList(item.guildId, item.userId);
              if (res) {
                controller.removeItem(item);
              }
              Get.back();
            },
            child: Container(
              width: Get.width,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Text(
                '确定解除'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF198CFE), fontSize: 16),
              ),
            ),
          ),
          const Divider(
            height: 12,
            thickness: 12,
            color: Color(0xFFF5F6FA),
          ),
          InkWell(
            onTap: Get.back,
            child: Container(
              width: Get.width,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Text(
                '取消'.tr,
                style: const TextStyle(color: Color(0xFF1F2125), fontSize: 16),
              ),
            ),
          ),
          SizedBox(height: Get.mediaQuery.padding.bottom),
        ],
      ),
    );
  }
}
