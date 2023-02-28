import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';

Future<int> showPickerPopup(BuildContext context, List<String> items) async {
  return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PickerPopup(
          items: items,
        );
      });
}

class PickerPopup extends StatefulWidget {
  final List<String> items;
  const PickerPopup({
    this.items,
  });
  @override
  _PickerPopupState createState() => _PickerPopupState();
}

class _PickerPopupState extends State<PickerPopup> {
  int selectIndex = 0;

  List<Widget> items() {
    return widget.items.map((e) {
      return Container(
        height: 44,
        alignment: Alignment.center,
        child: Text(
          e,
          style: Theme.of(context).textTheme.bodyText2.copyWith(fontSize: 24),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 366,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
                color: Theme.of(context).backgroundColor),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: Get.back,
                  child: Text(
                    '取消'.tr,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(fontSize: 17),
                  ),
                ),
                CupertinoButton(
                  onPressed: () => Navigator.of(context).pop(selectIndex),
                  child: Text(
                    '确认'.tr,
                    style: TextStyle(
                        fontSize: 17,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          divider,
          Expanded(
            child: CupertinoPicker(
              backgroundColor: Theme.of(context).backgroundColor,
              itemExtent: 44,
              onSelectedItemChanged: (value) => selectIndex = value,
              children: items(),
            ),
          ),
          Container(
            color: Theme.of(context).backgroundColor,
            height: getBottomViewInset(),
          )
        ],
      ),
    );
  }
}
