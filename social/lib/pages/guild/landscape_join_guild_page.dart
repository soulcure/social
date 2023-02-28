import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:im/api/invite_api.dart';
import 'package:im/core/config.dart';
import 'package:im/pages/tool/url_handler/invite_link_handler.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/widgets/app_bar/web_appbar.dart';
import 'package:im/widgets/button/primary_button.dart';
import 'package:im/widgets/custom_inputbox.dart';
import 'package:oktoast/oktoast.dart';

class LandscapeJoinGuildPage extends StatefulWidget {
  @override
  _LandscapeJoinGuildPageState createState() => _LandscapeJoinGuildPageState();
}

class _LandscapeJoinGuildPageState extends State<LandscapeJoinGuildPage> {
  bool _confirmEnable = false;
  bool _loading = false;
  TextEditingController _linkController;

  @override
  void initState() {
    _linkController = TextEditingController(text: '');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const WebAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.,
          children: <Widget>[
            sizeHeight32,
            Text(
              '加入服务器'.tr,
              style: theme.textTheme.bodyText2.copyWith(fontSize: 20),
            ),
            sizeHeight10,
            Text(
              '复制服务器的链接即可加入服务器'.tr,
              style:
                  Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14),
            ),
            sizeHeight32,
            CustomInputBox(
              borderRadius: 8,
              controller: _linkController,
              fillColor: theme.backgroundColor,
              hintText: '请输入邀请链接或邀请码'.tr,
              maxLength: 200,
              onChange: (val) {
                setState(() {
                  _confirmEnable = isNotNullAndEmpty(val.trim()) &&
                      val.trim().runes.length <= 200;
                });
              },
            ),
            sizeHeight10,
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '邀请链接示例：${Config.webLinkPrefix}ABCDEF',
                style: theme.textTheme.bodyText1.copyWith(fontSize: 12),
              ),
            ),
            sizeHeight8,
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '邀请码示例：ABCDEF'.tr,
                style: theme.textTheme.bodyText1.copyWith(fontSize: 12),
              ),
            ),
            sizeHeight32,
            LayoutBuilder(builder: (context, constraints) {
              return PrimaryButton(
                width: constraints.maxWidth,
                padding: const EdgeInsets.all(16),
                borderRadius: 8,
                loading: _loading,
                onPressed: !_confirmEnable
                    ? null
                    : () async {
                        if (_loading) return;
                        FocusScope.of(context).unfocus();
                        final url = _linkController.text.trim();
                        String code;
                        if (Config.inviteCodePattern.hasMatch(url)) {
                          code = url;
                        } else {
                          if (url.startsWith(Config.webLinkPrefix)) {
                            final index = url.lastIndexOf('/') + 1;
                            final qIndex = url.lastIndexOf('?');
                            if (index > 0 && index <= url.length) {
                              final lastIndex =
                                  qIndex > index && qIndex < url.length
                                      ? qIndex
                                      : url.length;
                              code = url.substring(index, lastIndex);
                            }
                          }
                        }

                        if (code == null) {
                          showToast('链接无效'.tr);
                          return;
                        }
                        toggleLoading(true);
                        try {
                          final Map inviteInfo = await InviteApi.getCodeInfo(
                              code,
                              showDefaultErrorToast: true);

                          toggleLoading(false);

                          await InviteLinkHandler(inviteInfo: inviteInfo)
                              .handleWithCode(code);
                        } catch (e) {
                          toggleLoading(false);
                        }
                      },
                label: '加入服务器'.tr,
              );
            })
          ],
        ),
      ),
    );
  }

  void toggleLoading(bool loading) {
    setState(() {
      _loading = loading;
    });
  }
}
