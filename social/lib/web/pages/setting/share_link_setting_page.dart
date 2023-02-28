import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/invite_code.dart';
import 'package:im/api/invite_api.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/pages/setting/edit_link_setting_page.dart';
import 'package:im/web/utils/confirm_dialog/setting_dialog.dart';
import 'package:im/web/utils/show_dialog.dart';
import 'package:oktoast/oktoast.dart';
import 'package:tuple/tuple.dart';

typedef OnShareTypeTap = void Function(
  GuildTarget guild,
  String title,
  String subtitle,
  String lnk,
  String icon,
);

void showShareLinkSettingPage(BuildContext context,
    {ChatChannel channel, String url}) {
  showAnimationDialog(
    context: context,
    builder: (_) => ShareLinkSettingPage(
      channel: channel,
      url: url,
    ),
  );
}

class ShareLinkSettingPage extends SettingDialog {
  final ChatChannel channel;
  final VoidCallback closeCallback;
  final String url;

  ShareLinkSettingPage({
    this.channel,
    this.closeCallback,
    this.url,
  });

  @override
  _ShareLinkSettingPageState createState() => _ShareLinkSettingPageState();
}

class _ShareLinkSettingPageState
    extends SettingDialogState<ShareLinkSettingPage> {
  bool isSelf;
  final ValueNotifier<Tuple2<EntityInviteUrl, bool>> _link =
      ValueNotifier(const Tuple2(null, false));
  static bool _first = true;

  int currentTimes = -1;
  int currentDeadLine = -1;

  /// 设置页面的管理
  final settingTimes = ValueNotifier(Tuple2('无限'.tr, -1));
  final settingDeadLine = ValueNotifier(Tuple2('永久'.tr, -1));
  final settingRemark = ValueNotifier('');

  /// 是否传入了分享url
  bool get hasInitialUrl => widget.url != null;

  /// 分享链接
  String get url => _link.value.item1?.url ?? widget.url;

  @override
  void initState() {
    if (hasInitialUrl) {
      super.initState();
      return;
    }
    if (_first) {
      _first = false;
      // 优化弹出卡顿
      Future.delayed(const Duration(milliseconds: 300), _getInviteUrl);
    } else {
      _getInviteUrl();
    }
  }

  @override
  bool get showSeparator => false;

  // String get title =>
  //'邀请好友加入 ${widget.channel?.name != null ? '#' : ''}${widget.channel?.name ?? ChatTargetsModel.instance.selectedChatTarget?.name ?? ''}';
  @override
  String get title {
    final name = widget.channel?.name ??
        ChatTargetsModel.instance.selectedChatTarget?.name ??
        '';
    final placeholderName = null != widget.channel?.name ? '#' : '';
    return '邀请好友加入 %s%s'.trArgs([placeholderName, name]);
  }

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget body() {
    if (hasInitialUrl) {
      return SizedBox(
        height: 100,
        child: _buildUrlContent(),
      );
    }

    return SizedBox(
      height: 132,
      child: _buildContent(),
    );
  }

  Widget _buildUrlContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '分享此链接，朋友点击即可加入'.tr,
            style: Theme.of(context).textTheme.bodyText1,
          ),
          sizeHeight10,
          Row(
            children: [
              Expanded(
                child: borderWraper(
                  padding: const EdgeInsets.only(left: 16),
                  child: SelectableText(
                    url ?? '',
                    style: Theme.of(context).textTheme.bodyText2,
                    maxLines: 1,
                  ),
                ),
              ),
              sizeWidth16,
              Container(
                width: 88,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Theme.of(context).primaryColor,
                ),
                child: TextButton(
                  onPressed: _onCopy,
                  child: Text(
                    '复制'.tr,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          sizeHeight10,
          if (!hasInitialUrl) _deadLineWidget(_link.value),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ValueListenableBuilder<Tuple2>(
      valueListenable: _link,
      builder: (_, __, ___) => Stack(
        children: [
          _buildUrlContent(),
          if (_link.value.item2 ?? false)
            Positioned.fill(
              child: Container(
                  color: CustomColor(context).backgroundColor6,
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(IconFont.buffChatWifiOff)),
                      sizeHeight6,
                      Text(
                        '网络异常，请检查网络后重试'.tr,
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1
                            .copyWith(fontSize: 14),
                      )
                    ],
                  )),
            )
          else if (_link.value.item1?.url == null ||
              _link.value.item1.url.isEmpty)
            Positioned.fill(
              child: Container(
                color: CustomColor(context).backgroundColor6,
                child: DefaultTheme.defaultLoadingIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget footer() => null;

  Future<EntityInviteUrl> _getInviteUrl({
    int number,
    int time,
    String remark,
  }) async {
    final Map params = {
      'channel_id': widget.channel?.id,
      'guild_id': ChatTargetsModel.instance.selectedChatTarget.id,
      'user_id': Global.user.id,
      'v': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    if (number != null && time != null) {
      params['number'] = number;
      params['time'] = time;
      params['remark'] = remark;
      params['type'] = 1;
    } else {
      params['type'] = 2;
    }
    try {
      final value = await InviteApi.getInviteInfo(params);
      if (value?.url != null) {
        if (mounted) _link.value = Tuple2(value, false);
        setState(() {
          currentTimes = int.parse(value.numberLess ?? '0');
          currentDeadLine = int.parse(value.expire ?? '0');
        });
      } else {
        _link.value = const Tuple2(null, false);
      }
      return value;
    } catch (e) {
      if (e is DioError) {
        if (e.type != DioErrorType.cancel && e.type != DioErrorType.response) {
          _link.value = const Tuple2(null, true);
        }
      }
      if (e is RequestArgumentError) {
        if (e.code == 1012) {
          showToast('提示该频道没有分享权限'.tr);
        }
      }
      return null;
    }
  }

  Widget _deadLineWidget(Tuple2 value) {
    String str = '';
    final isExpire = currentDeadLine == 0 || currentTimes == 0;
    if (currentDeadLine == -1) {
      str += '永久有效，'.tr;
    } else {
      str += '有效期还剩 %s，'.trArgs([formatSecond(currentDeadLine)]);
    }
    if (currentTimes == -1) {
      str += '无限次数'.tr;
    } else {
      str += '使用次数还剩 %s次'.trArgs([currentTimes.toString()]);
    }
    if (isExpire) {
      str += '，请重置'.tr;
    }
    str += '。 '.tr;

    final _theme = Theme.of(context);

    return Text.rich(TextSpan(
        text: str,
        style: TextStyle(
            fontSize: 14,
            height: 1,
            color: isExpire
                ? _theme.errorColor
                : _theme.textTheme.bodyText1.color),
        children: [
          WidgetSpan(
              child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      settingTimes.value =
                          getTimes(int.parse(value.item1.number ?? '0'));
                      settingDeadLine.value =
                          getDeadLine(int.parse(value.item1.time ?? '0'));
                      settingRemark.value = value.item1.remark ?? '';
//                      _pageController.animateToPage(1,
//                          duration: kThemeAnimationDuration,
//                          curve: Curves.easeInOut);
                      showEditLinkSettingPage(
                        context,
                        settingDeadLine: settingDeadLine,
                        settingTimes: settingTimes,
                        settingRemark: settingRemark,
                        saveCallback: () => _getInviteUrl(
                          number: settingTimes.value.item2,
                          time: settingDeadLine.value.item2,
                          remark: settingRemark.value ?? '',
                        ),
                      );
                    },
                    child: Text(
                      '编辑邀请链接'.tr,
                      style: _theme.textTheme.bodyText1.copyWith(
                        color: _theme.primaryColor,
                      ),
                    ),
                  ))),
          const TextSpan(text: ' ') // flutter bug，不加这行不显示
        ]));
  }

  void _onCopy() {
    final ClipboardData data = ClipboardData(text: url);
    Clipboard.setData(data);
    showToast('邀请链接已复制'.tr);
  }

  bool get isLinkEmpty =>
      _link.value.item1?.url == null || _link.value.item1.url.isEmpty;
}
