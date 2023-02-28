import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/redpack/send_pack/controllers/send_redpack_controller.dart';
import 'package:im/app/modules/redpack/send_pack/views/count_input_field.dart';
import 'package:im/app/modules/redpack/send_pack/views/greeting_input_field.dart';
import 'package:im/app/modules/redpack/send_pack/views/money_input_field.dart';
import 'package:im/app/theme/app_colors.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/icon_font.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';

//发送红包入参
class RedPackParams {
  final bool isSingleRedPack;
  final String guildId;
  final String channelId;
  final String picture;
  final String quoteL1;
  final String quoteL2;

  const RedPackParams({
    @required this.isSingleRedPack,
    @required this.guildId,
    @required this.channelId,
    @required this.quoteL1,
    @required this.quoteL2,
    this.picture = '',
  });
}

class SendRedPackPage extends GetView<SendRedPackController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: appThemeData.scaffoldBackgroundColor,
      appBar: FbAppBar.custom(
        '发红包'.tr,
        backgroundColor: appThemeData.scaffoldBackgroundColor,
      ),
      body: GestureDetector(
        onVerticalDragEnd: _handleDragEnd,
        onVerticalDragUpdate: _handleDragMove,
        excludeFromSemantics: true,
        behavior: HitTestBehavior.translucent,
        child: _buildBody(context),
      ),
    );
  }

  ///点击后关闭软键盘
  void _handleDragEnd(DragEndDetails details) {
    controller.hideKeyBoard();
  }

  ///垂直滑动关闭软键盘
  void _handleDragMove(DragUpdateDetails details) {
    final double delta = details.primaryDelta;
    if (delta.abs() > 7) {
      controller.hideKeyBoard();
    }
  }

  Widget _showError() {
    return GetBuilder<SendRedPackController>(
        init: SendRedPackController(),
        builder: (controller) {
          final String error = controller.getErrorInfo();
          if (!controller.checkSendStatus() && error.hasValue) {
            return Container(
              width: double.infinity,
              height: 32,
              alignment: Alignment.center,
              color: redTextColor.withOpacity(0.2),
              child: Text(error,
                  style: const TextStyle(color: redTextColor, fontSize: 14)),
            );
          }
          return const SizedBox(height: 32);
        });
  }

  Widget _countMoney() {
    return GetBuilder<SendRedPackController>(
      init: SendRedPackController(),
      builder: (controller) {
        return SizedBox(
          height: 50,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(controller.getTotalAmount(),
                  style: TextStyle(
                    color: appThemeData.textTheme.bodyText2.color,
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    textBaseline: TextBaseline.alphabetic,
                  )),
              const SizedBox(width: 4),
              Text('元'.tr,
                  style: TextStyle(
                    color: appThemeData.textTheme.bodyText2.color,
                    fontSize: 14,
                    textBaseline: TextBaseline.alphabetic,
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _setTotalAmount() {
    return GetBuilder<SendRedPackController>(
      init: SendRedPackController(),
      builder: (controller) {
        final bool inputError = !controller.checkMoneyInput();
        return Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 10),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: Row(
              children: [
                if (controller.isRandomGroupRedPack())
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      IconFont.buffIconPing,
                      size: 20,
                      color: goldLuckColor,
                    ),
                  ),
                Text(controller.getCurrentRedPackEntrance(),
                    style: inputError
                        ? const TextStyle(color: redTextColor, fontSize: 16)
                        : appThemeData.textTheme.bodyText2),
                Expanded(
                  child: NotificationListener(
                    onNotification: (notification) {
                      return true;
                    },
                    child: MoneyInputField(
                      (text) {
                        if (text.hasValue) {
                          controller.checkSpecialError(text);
                          final double amount = double.tryParse(text);
                          controller.setRedPackAmount(amount);
                        } else {
                          controller.setRedPackAmount(0);
                        }
                      },
                      controller.moneyController,
                      controller.moneyMaxInput(),
                      hintText: '输入金额'.tr,
                      isError: inputError,
                    ),
                  ),
                ),
                Text('元'.tr,
                    style: inputError
                        ? const TextStyle(color: redTextColor, fontSize: 16)
                        : appThemeData.textTheme.bodyText2),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _changePackType() {
    return GetBuilder<SendRedPackController>(
      init: SendRedPackController(),
      builder: (controller) {
        if (controller.isGroupRedPackEntrance())
          return Row(
            children: [
              const SizedBox(width: 32),
              Text("当前为".tr, style: appThemeData.textTheme.caption),
              Text(controller.getCurrentRedPackTypeStr(),
                  style: appThemeData.textTheme.caption),
              Text("，", style: appThemeData.textTheme.caption),
              Text("改为".tr, style: appThemeData.textTheme.caption),
              InkWell(
                onTap: () => controller.changePackType(),
                child: Text(controller.getOtherRedPackTypeStr(),
                    style:
                        TextStyle(color: Get.theme.primaryColor, fontSize: 14)),
              ),
            ],
          );
        else
          return const SizedBox();
      },
    );
  }

  Widget _redPackCount() {
    return GetBuilder<SendRedPackController>(
        init: SendRedPackController(),
        builder: (controller) {
          final bool inputError = !controller.checkCountInput();

          if (controller.isGroupRedPackEntrance())
            return Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 6, bottom: 10),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                child: Row(
                  children: [
                    Text("红包个数".tr,
                        style: inputError
                            ? const TextStyle(color: redTextColor, fontSize: 16)
                            : appThemeData.textTheme.bodyText2),
                    Expanded(
                      child: NotificationListener(
                        onNotification: (notification) {
                          return true;
                        },
                        child: CountInputField(
                          (text) {
                            if (text.hasValue) {
                              final int amount = int.tryParse(text);
                              controller.setRedPackTotal(amount);
                            } else {
                              controller.setRedPackTotal(0);
                            }
                          },
                          controller.countController,
                          controller.countMaxInput(),
                          hintText: "填写红包个数".tr,
                          isError: inputError,
                        ),
                      ),
                    ),
                    Text('个'.tr,
                        style: inputError
                            ? const TextStyle(color: redTextColor, fontSize: 16)
                            : appThemeData.textTheme.bodyText2),
                  ],
                ),
              ),
            );
          return const SizedBox();
        });
  }

  Widget _getSendButton(BuildContext context) {
    return GetBuilder<SendRedPackController>(
      init: SendRedPackController(),
      builder: (controller) {
        return Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
          child: SizedBox(
            width: Get.width,
            height: 44,
            child: ElevatedButton(
              onPressed: controller.checkSendStatus()
                  ? () {
                      _sendRedPack(context);
                    }
                  : _sendError,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  controller.checkSendStatus()
                      ? redTextColor
                      : redTextColor.withOpacity(0.2),
                ),
                shape: MaterialStateProperty.all(
                  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(6),
                    ),
                  ),
                ),
              ),
              child: Text('塞钱进红包'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  )),
            ),
          ),
        );
      },
    );
  }

  Widget _getRedPackGreetingsInput() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 10),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        padding: const EdgeInsets.only(left: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        child: NotificationListener(
          onNotification: (notification) {
            return true;
          },
          child: GreetingInputField(
            (text) {
              controller.redPackGreetings = text;
            },
            hintText: controller.hintText,
          ),
        ),
      ),
    );
  }

  //#8D93A6
  Widget _redPackInfo() {
    return KeyboardVisibilityBuilder(builder: (context, visible) {
      if (visible) return const SizedBox(); // 键盘隐藏
      return Text(
        '24小时未领取将自动失效'.tr,
        style: TextStyle(
            color: appThemeData.textTheme.headline2.color, fontSize: 14),
        maxLines: 2,
        textAlign: TextAlign.center,
      );
    });
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        _showError(),
        _countMoney(),
        const SizedBox(height: 16),
        _setTotalAmount(),
        _changePackType(),
        const SizedBox(height: 8),
        _redPackCount(),
        _getRedPackGreetingsInput(),
        const SizedBox(height: 10),
        _getSendButton(context),
        const Spacer(flex: 4),
        _redPackInfo(),
        const SizedBox(height: 16),
        SizedBox(height: Get.mediaQuery.padding.bottom),
      ],
    );
  }

  Future<void> _sendRedPack(BuildContext context) async {
    final bool res = await controller.sendRedPack(context);
    if (res) Get.back();
  }

  void _sendError() {
    controller.sendError();
  }
}
