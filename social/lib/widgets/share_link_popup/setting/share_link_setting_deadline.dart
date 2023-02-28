import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/widgets/button/back_button.dart';
import 'package:im/widgets/share_link_popup/share_link_navigator.dart';

import '../const.dart';
import 'widgets/item.dart';

class ShareLinkSettingDeadline extends StatefulWidget {
  final int defaultDeadLine;

  const ShareLinkSettingDeadline({Key key, this.defaultDeadLine})
      : super(key: key);

  @override
  _ShareLinkSettingDeadlineState createState() =>
      _ShareLinkSettingDeadlineState();
}

class _ShareLinkSettingDeadlineState extends State<ShareLinkSettingDeadline> {
  int _currentIndex = 0;

  @override
  void initState() {
    final index = ShareLinkDeadLine.values
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
            '有效期设置'.tr,
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
                content: ShareLinkDeadLine.values[index].desc,
                selected: _currentIndex == index,
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              );
            },
            itemCount: ShareLinkDeadLine.values.length,
          ),
        ),
      ],
    );
  }
}
