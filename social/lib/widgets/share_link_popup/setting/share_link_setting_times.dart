import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/widgets/button/back_button.dart';
import 'package:im/widgets/share_link_popup/const.dart';
import 'package:im/widgets/share_link_popup/share_link_navigator.dart';

import 'widgets/item.dart';

class ShareLinkSettingTimes extends StatefulWidget {
  final int defaultDeadLine;

  const ShareLinkSettingTimes({Key key, this.defaultDeadLine})
      : super(key: key);

  @override
  _ShareLinkSettingTimesState createState() => _ShareLinkSettingTimesState();
}

class _ShareLinkSettingTimesState extends State<ShareLinkSettingTimes> {
  int _currentIndex = 0;

  @override
  void initState() {
    final index = ShareLinkTimes.values
        .indexWhere((e) => e.value == widget.defaultDeadLine);
    if (index >= 0) _currentIndex = index;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          primary: false,
          leading: const CustomBackButton(),
          centerTitle: true,
          title: Text(
            '使用次数设置'.tr,
            style: Theme.of(context).textTheme.headline5,
          ),
          elevation: 0,
          actions: [
            CupertinoButton(
              onPressed: () => shareLinkKey.currentState.pop(_currentIndex),
              child: Text(
                '确定'.tr,
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return Item(
                content: ShareLinkTimes.values[index].desc,
                selected: _currentIndex == index,
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              );
            },
            itemCount: ShareLinkTimes.values.length,
          ),
        ),
      ],
    );
  }
}
