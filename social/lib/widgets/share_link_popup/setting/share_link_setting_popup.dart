import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/loggers.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/button/back_button.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/share_link_popup/const.dart';

import '../controller/share_link_controller.dart';
import '../share_link_navigator.dart';

class ShareLinkSettingParam {
  final String channelName;
  final ShareLinkTimes settingTimes;
  final ShareLinkDeadLine settingDeadLine;
  final String settingRemark;
  final String url;

  const ShareLinkSettingParam({
    this.channelName,
    this.settingTimes,
    this.settingDeadLine,
    this.settingRemark,
    this.url,
  });
}

class ShareLinkSettingPopup extends StatefulWidget {
  final ShareLinkSettingParam param;

  const ShareLinkSettingPopup({
    @required this.param,
  });

  @override
  _ShareLinkSettingPopupState createState() => _ShareLinkSettingPopupState();
}

class _ShareLinkSettingPopupState extends State<ShareLinkSettingPopup> {
  final ValueNotifier loading = ValueNotifier(false);
  ShareLinkTimes _settingTimes;
  ShareLinkDeadLine _settingDeadLine;
  String _settingRemark;
  ShareLinkController controller;

  @override
  void initState() {
    _settingTimes = widget.param.settingTimes;
    _settingDeadLine = widget.param.settingDeadLine;
    _settingRemark = widget.param.settingRemark;
    try {
      controller = GetInstance().find<ShareLinkController>();
    } catch (e) {
      logger.warning('can not find ShareLinkController');
    }
    super.initState();
  }

  @override
  void dispose() {
    loading.dispose();
    super.dispose();
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
            '设置邀请链接'.tr,
            style: Theme.of(context).textTheme.headline5,
          ),
          elevation: 0,
          actions: [
            ValueListenableBuilder(
              valueListenable: loading,
              builder: (context, isLoading, child) {
                return isLoading
                    ? Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: DefaultTheme.defaultLoadingIndicator(),
                      )
                    : child;
              },
              child: CupertinoButton(
                onPressed: () async {
                  loading.value = true;
                  await controller.fetchInviteUrl(
                    number: _settingTimes.value,
                    time: _settingDeadLine.value,
                    remark: _settingRemark,
                  );
                  loading.value = false;
                  shareLinkKey.currentState.pop();
                },
                child: Text(
                  '确定'.tr,
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
        if (widget.param.channelName != null)
          _Item('邀请频道'.tr, Text(widget.param.channelName)),
        _Item(
          '有效期'.tr,
          Text(_settingDeadLine?.desc ?? ''),
          onTap: () async {
            final index = await shareLinkKey.currentState.pushNamed(
                ShareLinkNavigatorState.linkHomeSettingDeadline,
                arguments: _settingDeadLine.value);
            if (index != null) {
              setState(() {
                _settingDeadLine = ShareLinkDeadLine.values[index];
              });
            }
          },
        ),
        _Item(
          "使用次数".tr,
          Text(_settingTimes?.desc ?? ''),
          onTap: () async {
            final index = await shareLinkKey.currentState.pushNamed(
                ShareLinkNavigatorState.linkHomeSettingTimes,
                arguments: _settingTimes.value);
            if (index != null) {
              setState(() {
                _settingTimes = ShareLinkTimes.values[index];
              });
            }
          },
        ),
        _Item(
          '设置备注'.tr,
          Text(_settingRemark ?? ''),
          onTap: () async {
            final content = await shareLinkKey.currentState.pushNamed(
                ShareLinkNavigatorState.linkHomeSettingRemark,
                arguments: _settingRemark ?? '');
            if (content != null && content != _settingRemark) {
              setState(() {
                _settingRemark = content;
              });
            }
          },
        )
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final String title;

  final Widget trailing;

  final VoidCallback onTap;

  const _Item(this.title, this.trailing, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          Container(
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyText2
                      .copyWith(fontWeight: FontWeight.w500, fontSize: 17),
                ),
                Expanded(
                  child: DefaultTextStyle(
                    style: theme.textTheme.bodyText1.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    child: trailing,
                  ),
                ),
                if (onTap != null) const MoreIcon(),
              ],
            ),
          ),
          Divider(
            thickness: theme.dividerTheme.thickness,
            indent: 16,
            color: const Color(0x338F959E),
          ),
        ],
      ),
    );
  }
}
