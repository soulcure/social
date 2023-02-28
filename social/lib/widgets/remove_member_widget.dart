import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/bot_market/bot_utils.dart';
import 'package:im/pages/bot_market/model/channel_cmds_model.dart';
import 'package:im/pages/bot_market/model/robot_model.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/blacklist_textfild_widget.dart';
import 'package:im/widgets/toast.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

import 'fb_check_box.dart';

enum RemoveMemberWidgetFrom {
  edit_member,
  card,
}

class RemoveMemberWidget extends StatefulWidget {
  const RemoveMemberWidget(
      this.guildId, this.memberId, this.memberName, this.isBot, this.from,
      {Key key})
      : super(key: key);

  final String guildId;
  final String memberId;
  final String memberName;
  final bool isBot;
  final RemoveMemberWidgetFrom from;

  @override
  _RemoveMemberWidgetState createState() => _RemoveMemberWidgetState();
}

class _RemoveMemberWidgetState extends State<RemoveMemberWidget>
    with WidgetsBindingObserver {
  RxBool rxBan = false.obs;
  String banReason;
  ScrollController controller;

  ///true表示用户手动滑动了
  bool isUser = false;
  bool _kickOutLoading = false;

  @override
  void initState() {
    super.initState();
    controller = ScrollController();
    controller.addListener(() {
      if (!isUser) {
        isUser = true;
      }
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isUser) {
        controller.jumpTo(controller.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return _bottomSheet();
  }

  double getHeight() {
    if (UniversalPlatform.isIOS) {
      return 320 + Get.mediaQuery.padding.bottom;
    }
    return 350;
  }

  Widget _bottomSheet() {
    return Container(
      width: Get.width,
      height: getHeight(),
      padding: const EdgeInsets.only(left: 27, right: 27, top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.white),
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: SingleChildScrollView(
        controller: controller,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 35,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFE0E2E6),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 24),
            Text('将该成员移出服务器'.tr,
                style: const TextStyle(
                    color: Color(0xFF1F2126),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _getContent(),
            const SizedBox(height: 10),
            ObxValue(
              (data) {
                if ((data as RxBool).value)
                  return SizedBox(
                    height: 68,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 10),
                      child: BlackListTextField((text) {
                        banReason = text;
                      }),
                    ),
                  );
                return const SizedBox(height: 48);
              },
              rxBan,
            ),
            const SizedBox(height: 30),
            _getButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _getContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: 24,
          child: Padding(
            padding: const EdgeInsets.only(top: 3.5),
            child: ObxValue(
              (data) => FBCheckBox(
                value: data.value,
                onChanged: (flag) {
                  data.value = flag;
                  if (!flag) {
                    banReason = '';
                  }
                },
              ),
              rxBan,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            maxLines: 2,
            text: TextSpan(
                text: '同时将该成员'.tr,
                style: const TextStyle(color: Color(0xFF646A73), fontSize: 16),
                //手势监听
                // recognizer: ,
                children: [
                  TextSpan(
                      text: '加入黑名单'.tr,
                      style: const TextStyle(
                          color: Color(0xFF1F2126),
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  TextSpan(
                    text: '，之后无法再加入此服务器。'.tr,
                    style:
                        const TextStyle(color: Color(0xFF646A73), fontSize: 16),
                  ),
                ]),
          ),
        )
      ],
    );
  }

  Widget _getButton() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () => Get.back(result: false),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  const Color(0xFFF5F6FA),
                ),
                shape: MaterialStateProperty.all(
                  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(6),
                    ),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('取消'.tr,
                    style: const TextStyle(
                      color: Color(0xFF1F2126),
                      fontSize: 16,
                    )),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () async => _kickOut(),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  const Color(0xFF198CFE),
                ),
                shape: MaterialStateProperty.all(
                  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(6),
                    ),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('确定移出'.tr,
                    style: const TextStyle(
                      color: Color(0xFFF5F6FA),
                      fontSize: 16,
                    )),
              ),
            ),
          ),
        )
      ],
    );
  }

  ///解决emoji字符长度问题
  bool checkBanReasonLength() {
    if (banReason.noValue) return false;
    final int len = banReason.characters.length;
    return len > BlackListTextField.inputLength;
  }

  Future<void> _kickOut() async {
    if (rxBan.value && checkBanReasonLength()) {
      showToast("内容长度超出限制".tr);
      return;
    }
    if (_kickOutLoading) return;
    try {
      _kickOutLoading = true;
      if (widget.isBot) {
        // 移除该机器人下的快捷指令，需在移出服务器前移除频道指令，否则会返回1007（用户不在服务器内）
        // TODO 待优化点：移除频道指令和移除机器人两个异步操作，可合并成一个请求
        // 优化方案：移除机器人时由服务端移除频道指令，客户端只接收通知
        await ChannelCmdsModel.instance.removeAllChannelCmds(
          guildId: widget.guildId,
          robotId: widget.memberId,
        );
      }
      //  获取成功结果
      await GuildApi.removeUser(
        guildId: widget.guildId,
        userId: Global.user.id,
        userName: widget.memberName,
        memberId: widget.memberId,
        ban: rxBan.value,
        blackReason: banReason,
        isOriginDataReturn: true,
      ).whenComplete(() {
        if (widget.isBot)
          BotUtils.dLogDelEvent(
            widget.guildId,
            widget.memberId,
            success: false,
            botRemovePosition: _getBotRemovePosition(widget.from),
          );
      });

      //  移除成功后提示成功内容
      Toast.iconToast(
          icon: ToastIcon.success,
          label: rxBan.value ? "已将用户加入黑名单".tr : "已将用户移出服务器".tr);

      // 移除对应服务台机器人
      unawaited(RobotModel.instance
          .removeGuildRobot(widget.guildId, widget.memberId));

      // 用户退出服务器清空角色
      RoleBean.update(widget.memberId, widget.guildId, null);
      _kickOutLoading = false;
      Get.back(result: true);
    } catch (e, s) {
      logger.severe('kickOut', e, s);
      _kickOutLoading = false;
    }
  }
}

BotRemovePosition _getBotRemovePosition(RemoveMemberWidgetFrom from) {
  switch (from) {
    case RemoveMemberWidgetFrom.card:
      return BotRemovePosition.bot_card;
    case RemoveMemberWidgetFrom.edit_member:
      return BotRemovePosition.edit_member;
    default:
      return null;
  }
}
