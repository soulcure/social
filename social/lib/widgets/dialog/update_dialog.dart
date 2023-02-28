import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/check_info_api.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/fb_ui_kit/form/form_builder.dart';
import 'package:im/widgets/fb_ui_kit/form/form_fix_child_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatefulWidget {
  final String version;
  final String updateInfo;
  final String updateUrl;
  final bool isForce;
  final Color backgroundColor;
  final Color updateInfoColor;

  const UpdateDialog({
    this.version = "1.0.0",
    this.updateInfo = "",
    this.updateUrl = "",
    this.isForce = false,
    this.backgroundColor,
    this.updateInfoColor,
  });

  @override
  State<StatefulWidget> createState() => UpdateDialogState();
}

class UpdateDialogState extends State<UpdateDialog> {
  CancelToken token;
  UploadingFlag uploadingFlag = UploadingFlag.idle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = widget.updateInfoColor ?? theme.textTheme.bodyText2.color;
    final bgColor = theme.scaffoldBackgroundColor;
    final cancelBgColor = theme.backgroundColor;
    final confirmBgColor = theme.primaryColor;

    final updateButton = GestureDetector(
      onTap: () async {
        if (UniversalPlatform.isIOS) {
          if (downloadUrl != null) await launchURL(downloadUrl);
          return;
        } else
          await launchURL(widget.updateUrl);

        if (!widget.isForce) Get.back();
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          color: confirmBgColor,
        ),
        child: Center(
          child: Text(
            '立即升级'.tr,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            width: 295,
            height: 365,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: bgColor,
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 32, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '发现新版本：Fanbook\nv%s'.trArgs([widget.version]),
                    style: TextStyle(color: textColor, fontSize: 20),
                  ),
                  Container(
                    height: 1,
                    color: const Color(0xffFFFFFF),
                    margin: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                  ),
                  Expanded(
                      child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '更新内容:'.tr,
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                        sizeHeight20,
                        Text(
                          widget.updateInfo ?? "",
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  )),
                  Container(
                    height: 40,
                    margin: const EdgeInsets.only(top: 20),
                    alignment: Alignment.center,
                    child: widget.isForce
                        ? SizedBox(
                            width: 250,
                            child: updateButton,
                          )
                        : Row(
                            children: <Widget>[
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Get.back();
                                  },
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(6)),
                                      color: cancelBgColor,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '取消'.tr,
                                        style: TextStyle(
                                            color: textColor, fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: updateButton,
                              ),
                            ],
                          ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    token = CancelToken();
    super.initState();
  }

  @override
  void dispose() {
    if (!token.isCancelled) token?.cancel();
    super.dispose();
  }
}

enum UploadingFlag { uploading, idle, uploaded, uploadingFailed }

Future launchURL(String url, {bool isCheck = true}) async {
  if (!isCheck || await canLaunch(url)) {
    if (UniversalPlatform.isAndroid && url.endsWith('.apk')) {
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      final AndroidDeviceInfo info = await deviceInfoPlugin.androidInfo;
      final String brand = info?.brand?.toLowerCase();

      bool res = false;

      ///5大android渠道才使用应用市场更新
      switch (brand) {
        case 'huawei':
        case 'xiaomi':
        case 'oppo':
        case 'vivo':
        case 'meizu':
          final PackageInfo packageInfo = await PackageInfo.fromPlatform();
          final String marketUri =
              "market://details?id=${packageInfo.packageName}";
          res = await launch(marketUri);
          break;
        default:
          res = false;
          break;
      }

      ///打开应用市场成功，返回
      if (res) return;
    }

    ///打开应用市场失败，使用浏览器打开下载地址
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class CheckUpdateButton extends StatefulWidget {
  /// - 是否是在我的页面
  final bool isFromPersonalPage;

  const CheckUpdateButton({this.isFromPersonalPage = false});

  @override
  _CheckUpdateButtonState createState() => _CheckUpdateButtonState();
}

class _CheckUpdateButtonState extends State<CheckUpdateButton> {
  String versionInfo = '';
  CancelToken cancelToken;
  bool isChecking = false;

  @override
  void initState() {
    initialData();
    super.initState();
  }

  Future initialData() async {
    cancelToken = CancelToken();
    final packageInfo = await PackageInfo.fromPlatform();
    versionInfo = packageInfo.version;
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    cancelToken?.cancel();
    cancelToken = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIos = UniversalPlatform.isIOS;
    const textStyle =
        TextStyle(fontSize: 16, color: Color(0xFF363940), height: 1.25);
    return widget.isFromPersonalPage
        ? _buildPersonalView(context, isIos, textStyle)
        : _buildFadeBackgroundButton(theme, isIos, textStyle, context);
  }

  /// - 在"我的"页面的样式
  Widget _buildPersonalView(
      BuildContext context, bool isIos, TextStyle textStyle) {
    return FbForm.common(
      isIos ? '版本信息'.tr : '版本更新'.tr,
      isShowArrow: !isIos,
      suffixChildModel: FbFormWidgetSuffixChild(_buildSuffixChild(isIos)),
      position: FbFormPosition.middle,
      onTap: () => checkUpdate(context),
    );
  }

  Widget _buildSuffixChild(bool isIos) {
    return Container(
      margin: EdgeInsets.only(right: isIos ? 16 : 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Version $versionInfo',
              style: TextStyle(color: appThemeData.textTheme.headline2.color)),
          ValueListenableBuilder(
            valueListenable: needToUpdate,
            builder: (ctx, v, _) {
              return v ? getUpdateNotify() : const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  FadeBackgroundButton _buildFadeBackgroundButton(
      ThemeData theme, bool isIos, TextStyle textStyle, BuildContext context) {
    return FadeBackgroundButton(
      backgroundColor: theme.backgroundColor,
      tapDownBackgroundColor: theme.backgroundColor.withOpacity(0.5),
      child: ListTile(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(isIos ? '版本信息'.tr : '版本更新'.tr, style: textStyle),
            ValueListenableBuilder(
              valueListenable: needToUpdate,
              builder: (ctx, v, _) {
                return v ? getUpdateNotify() : const SizedBox();
              },
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Version $versionInfo'),
            const SizedBox(
              width: 16,
            ),
            if (isIos) const SizedBox() else const MoreIcon(),
          ],
        ),
        onTap: () => checkUpdate(context),
      ),
    );
  }

  Future<void> checkUpdate(BuildContext context) async {
    if (!isChecking) {
      isChecking = true;
      await CheckInfoApi.postCheckUpdate(context,
          token: cancelToken, showUpdateDialog: true, isManual: true);
      isChecking = false;
    }
  }

  Widget getUpdateNotify() {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: TextChatUICreator.makeTag(
        "有新版本".tr,
        primaryColor,
        Colors.white,
      ),
    );
  }
}
