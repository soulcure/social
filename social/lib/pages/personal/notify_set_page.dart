import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/button/back_button.dart';

class NotifySetPage extends StatefulWidget {
  @override
  _NotifySetPageState createState() => _NotifySetPageState();
}

class _NotifySetPageState extends State<NotifySetPage> {
  bool _notify = false;
  @override
  Widget build(BuildContext context) {
    final ThemeData _theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('通知设置'.tr),
        elevation: 0,
        backgroundColor: _theme.backgroundColor,
        leading: const CustomBackButton(),
      ),
      body: ListView(
        children: <Widget>[
          sizeHeight20,
          Column(
            children: <Widget>[
              Container(
                color: _theme.backgroundColor,
                child: ListTile(
                    dense: true,
                    leading: Text(
                      '接受推送通知'.tr,
                      style: _theme.textTheme.bodyText2,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '已开启'.tr,
                          style:
                              _theme.textTheme.bodyText1.copyWith(fontSize: 12),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_right,
                          color: Color(0xFF818487),
                        ),
                      ],
                    )),
              ),
              divider,
              Container(
                color: _theme.backgroundColor,
                child: ListTile(
                    dense: true,
                    leading: Text(
                      '应用内横幅提醒'.tr,
                      style: _theme.textTheme.bodyText2,
                    ),
                    trailing: Transform.scale(
                      scale: 0.9,
                      child: CupertinoSwitch(
                          activeColor: Theme.of(context).primaryColor,
                          value: _notify,
                          onChanged: _onNotifyChange),
                    )),
              )
            ],
          ),
        ],
      ),
    );
  }

  void _onNotifyChange(bool v) {
    setState(() {
      _notify = v;
    });
  }
}
