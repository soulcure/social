import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/themes/const.dart';
import 'package:im/web/utils/confirm_dialog/setting_dialog.dart';
import 'package:im/web/widgets/popup/web_popup.dart';
import 'package:im/widgets/custom_inputbox_web.dart';
import 'package:tuple/tuple.dart';

List<Tuple2<String, int>> timesList = [
  Tuple2('无限'.tr, -1),
  const Tuple2('1', 1),
  const Tuple2('5', 5),
  const Tuple2('10', 10),
  const Tuple2('25', 25),
  const Tuple2('50', 50),
  const Tuple2('100', 100),
];

Tuple2<String, int> getTimes(int value) {
  for (final m in timesList) {
    if (m.item2 == value) return m;
  }
  return null;
}

List<Tuple2<String, int>> deadLineList = [
  Tuple2('永久'.tr, -1),
  Tuple2('1天'.tr, 24 * 60 * 60),
  Tuple2('12小时'.tr, 12 * 60 * 60),
  Tuple2('6小时'.tr, 6 * 60 * 60),
  Tuple2('1小时'.tr, 60 * 60),
  Tuple2('30分钟'.tr, 30 * 60),
];

Tuple2<String, int> getDeadLine(int value) {
  for (final m in deadLineList) {
    if (m.item2 == value) return m;
  }
  return null;
}

Future showEditLinkSettingPage(
  BuildContext context, {
  ValueNotifier settingTimes,
  ValueNotifier settingDeadLine,
  ValueNotifier settingRemark,
  String channelName,
  Future Function() saveCallback,
}) {
  return showDialog(
    context: context,
    builder: (_) => EditLinkSettingPage(
      settingTimes: settingTimes,
      settingDeadLine: settingDeadLine,
      settingRemark: settingRemark,
      channelName: channelName,
      saveCallback: saveCallback,
    ),
  );
}

class EditLinkSettingPage extends SettingDialog {
  final String channelName;
  final ValueNotifier settingTimes;
  final ValueNotifier settingDeadLine;
  final ValueNotifier settingRemark;
  final Future Function() saveCallback;

  EditLinkSettingPage({
    @required this.settingTimes,
    @required this.settingDeadLine,
    @required this.settingRemark,
    @required this.saveCallback,
    this.channelName,
  });

  @override
  _EditLinkSettingPageState createState() => _EditLinkSettingPageState();
}

class _EditLinkSettingPageState
    extends SettingDialogState<EditLinkSettingPage> {
  @override
  String get title => '邀请链接设置'.tr;

  TextEditingController _remarkController;

  @override
  void initState() {
    super.initState();
    _remarkController = TextEditingController(
        text: (widget.settingRemark.value as String) ?? '');
  }

  @override
  bool get showSeparator => false;

  @override
  Future<void> finish() async {
    final res = await widget.saveCallback();
    if (res != null) Get.back();
  }

  @override
  Widget body() {
    return Column(
      children: [
        if (widget.channelName != null)
          _selectItem('邀请频道'.tr, Text(widget.channelName)),
        Builder(builder: (context) {
          return _selectItem(
            '有效期'.tr,
            ValueListenableBuilder(
              valueListenable: widget.settingDeadLine,
              builder: (_, value, __) => Text(
                value?.item1 ?? '',
                style: Theme.of(context).textTheme.bodyText2,
              ),
            ),
            onTap: () async {
              final index = await showWebSelectionPopup(context,
                  items: deadLineList.map((e) => e.item1).toList(),
                  width: 392,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  offsetY: 12);
              if (index != null) {
                widget.settingDeadLine.value = deadLineList[index];
              }
            },
          );
        }),
        Builder(builder: (context) {
          return _selectItem(
            "使用次数".tr,
            ValueListenableBuilder(
              valueListenable: widget.settingTimes,
              builder: (_, value, __) => Text(value?.item1 ?? '',
                  style: Theme.of(context).textTheme.bodyText2),
            ),
            onTap: () async {
              final index = await showWebSelectionPopup(context,
                  items: timesList.map((e) => e.item1).toList(),
                  width: 392,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  offsetY: 12);
              if (index != null) {
                setState(() {
                  widget.settingTimes.value = timesList[index];
                });
              }
            },
          );
        }),
        _commonItem(
          '设置备注'.tr,
          WebCustomInputBox(
              contentPadding: const EdgeInsets.fromLTRB(12, 13, 60, 13),
              controller: _remarkController,
              fillColor: Theme.of(context).backgroundColor,
              hintText: '输入备注名'.tr,
              placeholderColor: const Color(0xFFA3A8BF),
              maxLength: 12,
              onChange: (content) {
                final val = content?.trim() ?? '';
                widget.settingRemark.value = val;
                enable.value = val.trim().length <= 12;
              }),
        ),
        sizeHeight16,
      ],
    );
  }

  Widget _itemWrapper(String title, Widget child) {
    final theme = Theme.of(context);
    return Container(
      height: 80,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyText1,
          ),
          sizeHeight4,
          child,
        ],
      ),
    );
  }

  Widget _commonItem(String title, Widget contentWidget) {
    return _itemWrapper(title, contentWidget);
  }

  Widget _selectItem(String title, Widget contentWidget, {VoidCallback onTap}) {
    return _itemWrapper(
      title,
      GestureDetector(
        onTap: onTap,
        child: borderWraper(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              contentWidget,
              const Icon(
                Icons.arrow_drop_down,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
