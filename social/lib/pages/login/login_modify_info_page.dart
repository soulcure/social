import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/check_info_api.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/const.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/routes.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/get_image_fom_camera_or_file.dart';
import 'package:im/utils/invite_code/invite_code_util.dart';
import 'package:im/utils/upload.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/circle_icon.dart';
import 'package:im/widgets/custom_inputbox_close.dart';
import 'package:websafe_svg/websafe_svg.dart';

class LoginModifyUserInfoPage extends StatefulWidget {
  final bool isFirstIn;

  const LoginModifyUserInfoPage({Key key, this.isFirstIn = false})
      : super(key: key);

  @override
  _LoginModifyUserInfoPageState createState() =>
      _LoginModifyUserInfoPageState();
}

class _LoginModifyUserInfoPageState extends State<LoginModifyUserInfoPage> {
  String _avatar = '';
  File _avatarFile;
  bool _enableConfirm = false;
  int _gender;
  TextEditingController _nicknameController;
  ThemeData _theme;
  bool _loading;
  final GlobalKey _autoGenAvatarKey = GlobalKey();

  String get username => _nicknameController.text.trim();

  final randomBgColors = [
    const Color(0xFF198CFE),
    const Color(0xFF00BF7F),
    const Color(0xFFFA9D3B),
  ];
  Color defaultAvatarColor;

  @override
  void initState() {
    // 选择一种默认颜色
    defaultAvatarColor = randomBgColors[Random().nextInt(3)];

    /// todo 优化审核后去掉，临时加在这里解决头像不审核问题
    CheckInfoApi.postCheckInfo(context);

    final user = Global.user;
    _loading = false;
    _gender = 0;
    _avatar = user.avatar ?? '';
    if (_avatar.isEmpty) {
      final path = SpService.to.rawSp.getString(Global.user.mobile);
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (file.existsSync()) _avatarFile = file;
      }
    }
    final nickname =
        SpService.to.rawSp.getString(Global.user.mobile + NICKNAME);
    if ((user.nickname == null || user.nickname.isEmpty) && nickname != null)
      user.nickname = nickname;
    final gender = SpService.to.getInt2(Global.user.mobile + GENDER);
    if (gender != null) _gender = gender;
    _nicknameController = TextEditingController(text: user.nickname ?? '');
    updateEnableConfirm();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        // 禁止android物理返回键返回登录页面
        if (widget.isFirstIn) await Routes.popAndPushLoginPage(null, null);
        return false;
      },
      child: GestureDetector(
        onTap: FocusScope.of(context).unfocus,
        child: Stack(
          children: [
            Container(
              color: Colors.white,
              alignment: Alignment.topCenter,
              child: WebsafeSvg.asset(
                'assets/svg/login_page_bg.svg',
                fit: BoxFit.fitWidth,
                width: Get.width,
              ),
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: FbAppBar.custom(
                '',
                actions: [
                  AppBarTextPrimaryActionModel(
                    '保存',
                    isEnable: _enableConfirm,
                    isLoading: _loading,
                    actionBlock: _enableConfirm ? _onConfirm : null,
                  ),
                ],
                leadingBlock: () {
                  Routes.popAndPushLoginPage(Global.user.mobile, null);
                  return true;
                },
                backgroundColor: Colors.transparent,
              ),
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ListView(
                  children: <Widget>[
                    const SizedBox(height: 36),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        GestureDetector(
                          onTap: _pickImage,
                          child: SizedBox(
                            width: 120,
                            height: 120,
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Container(
                                    alignment: Alignment.center,
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: appThemeData.disabledColor
                                            .withOpacity(.35),
                                        width: username.isEmpty ? 0 : .5,
                                      ),
                                    ),
                                    child: _buildAvatar(),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: CircleIcon(
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                    icon: Icons.camera_alt,
                                    backgroundColor: _theme.primaryColor,
                                    color: Colors.white,
                                    radius: 16,
                                    size: 14,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(btnBorderRadius),
                        border: Border.all(
                            color: appThemeData.disabledColor.withOpacity(.35),
                            width: .5),
                      ),
                      height: 48,
                      child: CustomInputCloseBox(
                        controller: _nicknameController,
                        style: _theme.textTheme.bodyText2,
                        inputFormatters: <TextInputFormatter>[
                          LengthLimitingTextInputFormatter(12),
                          // FilteringTextInputFormatter.allow(
                          //     RegExp(' |[a-zA-Z]|[\u4e00-\u9fa5]|[0-9]'))
                        ],
                        maxLength: maxNickNameLength,
                        hintText: "请输入用户名".tr,
                        fillColor: Colors.transparent,
                        hintStyle: TextStyle(
                          color: appThemeData.disabledColor.withOpacity(.75),
                          height: 1.25,
                        ),
                        onChange: _onNicknameChange,
                      ),
                    ),
                    sizeHeight16,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: <Widget>[
                          _buildGenderItem(1, _gender),
                          sizeWidth12,
                          _buildGenderItem(2, _gender),
                        ],
                      ),
                    ),
                    sizeHeight16,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          '* 选定性别后不可再修改哦~'.tr,
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              .copyWith(fontSize: 12),
                        )
                      ],
                    ),
                    const SizedBox(height: 32),
                    sizeHeight32
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderItem(int gender, int value) {
    IconData _icon;
    String _text;
    Color _color;
    if (gender == 1) {
      _icon = IconFont.buffBoy;
      _text = '男'.tr;
      _color = _theme.primaryColor;
    } else if (gender == 2) {
      _icon = IconFont.buffGirl;
      _text = '女'.tr;
      _color = const Color(0xffFF3377);
    } else {
      return const SizedBox();
    }
    return Flexible(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _gender = gender;
            SpService.to.rawSp.setInt(Global.user.mobile + GENDER, gender);
            updateEnableConfirm();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: gender == value ? Colors.white : const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(btnBorderRadius),
            border:
                gender == value ? Border.all(color: _color, width: .5) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                _icon,
                size: 20,
                color: gender == value
                    ? _color
                    : _theme.disabledColor.withOpacity(.8),
              ),
              sizeWidth5,
              Text(
                _text,
                style: _theme.textTheme.bodyText2.copyWith(
                  color: gender == value
                      ? _color
                      : _theme.disabledColor.withOpacity(.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onConfirm() async {
    setState(() {
      _loading = true;
    });
    FocusScope.of(context).unfocus();
    String avatar;
    try {
      if (_avatarFile != null) {
        avatar = await uploadHeadFile(_avatarFile);
      } else if (_avatar.isNotEmpty) {
        avatar = _avatar;
      } else {
        ///用户没有上传头像，则获取头像截图上传COS获取URL
        final RenderRepaintBoundary boundary =
            _autoGenAvatarKey.currentContext.findRenderObject();
        final image = await boundary.toImage();
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        avatar = await uploadFileIfNotExist(
          bytes: byteData.buffer.asUint8List(),
          fileType: "headImage",
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }

    try {
      await UserApi.updateUserInfo(
          Global.user.id, _nicknameController.text.trim(), avatar, _gender);
      DLogManager.getInstance().customEvent(
          actionEventId: 'register_info_status',
          actionEventSubId: '1',
          pageId: 'page_register_info',
          extJson: {"invite_code": InviteCodeUtil.inviteCode});
    } catch (e) {
      setState(() {
        _loading = false;
      });
      DLogManager.getInstance().customEvent(
          actionEventId: 'register_info_status',
          actionEventSubId: '0',
          actionEventSubParam: e?.toString(),
          pageId: 'page_register_info',
          extJson: {"invite_code": InviteCodeUtil.inviteCode});
      return;
    }
    await Global.user.update(
      nickname: _nicknameController.text.trim(),
      avatar: avatar,
      gender: _gender,
      avatarNft: _avatarFile != null ? '' : null,
      avatarNftId: _avatarFile != null ? '' : null,
    );
    await Routes.pushHomePage(context);
  }

  Future<void> _pickImage() async {
    FocusScope.of(context).unfocus();
    final file = await getImageFromCameraOrFile(context, crop: true);
    if (file != null) {
      setState(() {
        _avatar = '';
        _avatarFile = file;
        updateEnableConfirm();
      });
      if (file.existsSync()) {
        await SpService.to.rawSp.setString(
          Global.user.mobile,
          file.path,
        );
      }
    }
  }

  void _onNicknameChange(String value) {
    updateEnableConfirm();
    if (value.isNotEmpty)
      SpService.to.rawSp.setString(Global.user.mobile + NICKNAME, value);
    setState(() {});
  }

  void updateEnableConfirm() {
    bool avatarAvailable;
    // 华为渠道跳过头像选择
    if (Global.deviceInfo.channel == 'HW0S0N00666') {
      avatarAvailable = true;
    } else {
      avatarAvailable = isNotNullAndEmpty(_avatar) || _avatarFile != null;
    }
    _enableConfirm = avatarAvailable &&
        _nicknameController.text.trim().runes.isNotEmpty &&
        [1, 2].contains(_gender);
  }

  Widget _buildAvatar() {
    if (isNotNullAndEmpty(_avatar) || _avatarFile != null) {
      return Avatar(
        url: _avatar,
        file: _avatarFile,
        radius: 60,
      );
    }
    return _buildTextAvatar();
  }

  Widget _buildTextAvatar() {
    return RepaintBoundary(
      key: _autoGenAvatarKey,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        color: defaultAvatarColor,
        child: const SizedBox(
          child: Text(
            '未设置',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

const NICKNAME = 'nickname';
const GENDER = 'gender';
