import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picker/Picker.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/mute/controllers/mute_list_controller.dart';
import 'package:im/app/modules/mute/controllers/mute_time_setting_controller.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/toast.dart';

import '../../../../icon_font.dart';

/// - 描述：禁言时长设置界面
///
/// - author: seven
/// - data: 2021/12/10 11:13 上午
class MuteTimeSettingPage extends StatefulWidget {
  final String guildId;
  final String userId;

  const MuteTimeSettingPage({
    Key key,
    @required this.guildId,
    @required this.userId,
  }) : super(key: key);

  @override
  _MuteTimeSettingPageState createState() => _MuteTimeSettingPageState();
}

class _MuteTimeSettingPageState extends State<MuteTimeSettingPage> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<MuteTimeSettingController>(
        init: MuteTimeSettingController(widget.guildId, widget.userId),
        builder: (controller) {
          return Scaffold(
            appBar: CustomAppbar(
              backgroundColor: const Color(0xFFF5F6FA),
              title: '设置禁言时长'.tr,
              leadingIcon: IconFont.buffNavBarCloseItem,
              actions: [
                AppbarTextButton(
                  text: '确定'.tr,
                  enable: controller.hasSelected(),
                  onTap: () async {
                    final success = await MuteListController.to.addToMuteList(
                        controller.userId,
                        controller.guildId,
                        controller.customizeToTimeStr());
                    if (success) {
                      Toast.iconToast(
                          icon: ToastIcon.success, label: "已将用户禁言".tr);
                      Get.back();
                    }
                  },
                )
              ],
            ),
            backgroundColor: const Color(0xFFF5F6FA),
            body: Container(
              margin: const EdgeInsets.only(top: 16),
              child: ListView.separated(
                itemBuilder: (context, index) {
                  return _timerItem(
                    controller.timers[index],
                    index == controller.timers.length - 1,
                    controller,
                    context,
                  );
                },
                separatorBuilder: (context, index) {
                  return index == controller.timers.length - 1
                      ? Container()
                      : Container(
                          color: Colors.white,
                          padding: const EdgeInsets.only(left: 50),
                          child: Divider(
                            height: 0.5,
                            color: const Color(0xFF8F959E).withOpacity(0.15),
                          ),
                        );
                },
                itemCount: controller.timers.length,
              ),
            ),
          );
        });
  }

  /// - isLastItem 最后一项是自定义
  Widget _timerItem(
    TimerBean timer,
    bool isLastItem,
    MuteTimeSettingController controller,
    BuildContext context,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: FadeBackgroundButton(
        backgroundColor: Colors.white,
        tapDownBackgroundColor: CustomColor(context).backgroundColor7,
        onTap: () {
          if (isLastItem) {
            _showTimePicker(controller, context);
          } else {
            controller.setSelected(timer);
          }
        },
        child: Row(
          children: [
            if (timer.isSelected)
              const SizedBox(
                height: 52,
                width: 50,
                child: Icon(
                  IconFont.buffSelectSingle,
                  size: 19,
                  color: Color(0xFF198CFE),
                ),
              )
            else
              SizedBox(
                height: 52,
                width: 50,
                child: Icon(
                  IconFont.buffUnselectSingle,
                  size: 19,
                  color: const Color(0xFF8F959E).withOpacity(0.5),
                ),
              ),
            Expanded(
              child: Text(
                timer.timer,
                style: Get.textTheme.bodyText2,
              ),
            ),
            if (isLastItem)
              Container(
                padding: const EdgeInsets.only(right: 15),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.customizeTimeStr(),
                      style: Get.textTheme.bodyText2.copyWith(
                        fontSize: 15,
                        color: const Color(0xFF5C6273),
                      ),
                    ),
                    const MoreIcon(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// - 显示时间选择器
  void _showTimePicker(
    MuteTimeSettingController controller,
    BuildContext context,
  ) {
    Picker(
      adapter: PickerDataAdapter<String>(
          pickerdata: controller.timerPickData, isArray: true),
      height: 380,
      looping: true,
      itemExtent: 50,
      selectionOverlay: null,
      selecteds: controller.mCustomizeTime ?? [0, 0, 1],
      title: Text(
        "自定义禁言时长".tr,
        style: Get.textTheme.bodyText2.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      selectedTextStyle: const TextStyle(
        color: Color(0xFF1F2126),
        fontSize: 24,
      ),
      confirmText: '确定'.tr,
      confirmTextStyle: const TextStyle(
        color: Color(0xFF198CFE),
        fontSize: 16,
      ),
      cancel: TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(
          IconFont.buffNavBarCloseItem,
          color: Color(0xFF1F2329),
          size: 20,
        ),
      ),
      onConfirm: (picker, value) {
        // flutter: [8, 15, 14]
        // flutter: [8天, 15小时, 14分钟]
        controller.setCustomizeTime(value);
      },
    ).showModal(context);
  }
}
