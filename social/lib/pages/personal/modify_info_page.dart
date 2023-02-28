import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/user_api.dart';
import 'package:im/const.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/get_image_fom_camera_or_file.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/circle_icon.dart';
import 'package:im/widgets/custom_inputbox.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

import '../../utils/cos_file_upload.dart';

class ModifyUserInfoPage extends StatefulWidget {
  @override
  _ModifyUserInfoPageState createState() => _ModifyUserInfoPageState();
}

class _ModifyUserInfoPageState extends State<ModifyUserInfoPage> {
  String _avatar;
  String _avatarNft;
  File _avatarFile;
  bool _enableConfirm = false;
  int _gender;
  TextEditingController _nicknameController;
  bool _loading = false;

  // Uint8List imageMemory;
  @override
  void initState() {
//    draw();
    _avatarNft = Global.user.avatarNft;
    _avatar = Global.user.avatar;
    _gender = Global.user.gender;
    Characters char = Characters(Global.user.nickname ?? '');
    if (char.length >= maxNickNameLength) {
      char = char.getRange(0, maxNickNameLength);
    }
    _nicknameController = TextEditingController(text: char.toString());
    updateEnableConfirm();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(!Loading.visible),
      child: GestureDetector(
        onTap: FocusScope.of(context).unfocus,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: CustomAppbar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leadingBuilder: (icon) {
              return IconButton(
                  icon: Icon(
                    IconFont.buffNavBarCloseItem,
                    size: icon.size,
                  ),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Get.back();
                  });
            },
            actions: [
              AppbarTextButton(
                loading: _loading,
                onTap: _onConfirm,
                text: '确定'.tr,
                enable: _enableConfirm,
              )
            ],
          ),
          body: Column(
            children: <Widget>[
              Builder(
                  builder: (context) => GestureDetector(
                        onTap: () => _pickImage(context),
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: Stack(
                            children: <Widget>[
                              Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        width: 2,
                                        color: const Color(0xff8F959E))),
                              ),
                              Center(
                                child: !isNotNullAndEmpty(_avatar) &&
                                        !isNotNullAndEmpty(_avatarNft) &&
                                        _avatarFile == null
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          const Icon(
                                            Icons.add,
                                            size: 26,
                                          ),
                                          sizeHeight5,
                                          Text(
                                            '设置个人头像'.tr,
                                            style: const TextStyle(
                                                color: Color(0xFF8F959E),
                                                fontSize: 12),
                                          )
                                        ],
                                      )
                                    : Avatar(
                                        url: isNotNullAndEmpty(_avatarNft)
                                            ? _avatarNft
                                            : _avatar,
                                        file: _avatarFile,
                                        radius: 50),
                              ),
                              Align(
                                  alignment: Alignment.bottomRight,
                                  child: CircleIcon(
                                    icon: IconFont.buffOtherPhoto,
                                    color: Theme.of(context).primaryColor,
                                    size: 24,
                                    radius: 12,
                                  ))
                            ],
                          ),
                        ),
                      )),
              const SizedBox(height: 44),

              Container(
                margin: const EdgeInsets.all(16),
                child: CustomInputBox(
                  borderRadius: 8,
                  fillColor: CustomColor(context).backgroundColor1,
                  controller: _nicknameController,
                  hintText: '请输入用户名'.tr,
                  maxLength: maxNickNameLength,
                  onChange: _onNicknameChange,
                ),
              ),
              // 修改性别
              Visibility(
                visible: ![1, 2].contains(Global.user.gender),
                child: Column(
                  children: <Widget>[
                    sizeHeight16,
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: <Widget>[
                          _buildGenderItem(1, _gender),
                          sizeWidth16,
                          _buildGenderItem(2, _gender),
                        ],
                      ),
                    ),
                    sizeHeight8,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text('*',
                            style: TextStyle(
                                color: Color(0xFF29CC5F), fontSize: 18)),
                        Text('选定性别后不可再修改哦~'.tr,
                            style: const TextStyle(
                                color: Color(0xFF8F959E), fontSize: 12))
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderItem(int gender, int value) {
    IconData _icon;
    String _text;
    if (gender == 1) {
      _icon = IconFont.buffTabMale;
      _text = '男'.tr;
    } else if (gender == 2) {
      _icon = IconFont.buffTabFemale;
      _text = '女'.tr;
    } else {
      return const SizedBox();
    }
    return Flexible(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _gender = gender;
            updateEnableConfirm();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: gender == value
                ? Theme.of(context).primaryColor
                : Theme.of(context).backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                _icon,
                size: 22,
                color: gender == value
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyText2.color,
              ),
              sizeWidth5,
              Text(_text,
                  style: Theme.of(context).textTheme.bodyText2.copyWith(
                      color: gender == value
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyText2.color)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onConfirm() async {
    if (!isNotNullAndEmpty(_avatar) && _avatarFile == null) {
      showToast('请上传头像'.tr);
      return;
    }
    if (_nicknameController.text.trim().length < 2) {
      showToast('昵称需包括2-12个字符'.tr);
      return;
    }
    if (![1, 2].contains(_gender)) {
      showToast('请选择性别'.tr);
      return;
    }

    final user = Global.user;
    final bool isChanged = !(user.nickname == _nicknameController.text.trim() &&
        user.avatar == _avatar &&
        user.gender == _gender);
    FocusScope.of(context).unfocus();
    if (isChanged) {
      setState(() {
        _loading = true;
        Loading.show(context, isEmpty: true);
      });
      String avatar;
      try {
        avatar = _avatarFile == null
            ? _avatar
            : await CosFileUploadQueue.instance
                .onceForPath(_avatarFile.path, CosUploadFileType.headImage);
        final nickname = _nicknameController.text.trim();
        await UserApi.updateUserInfo(Global.user.id, nickname, avatar, _gender);
        final UserInfo user = Db.userInfoBox.get(Global.user.id);
        user.nickname = nickname;
        user.avatar = avatar;
        user.gender = _gender;
        // 修改了头像，就将nft头像去掉
        if (_avatarFile != null) {
          user.avatarNft = '';
          user.avatarNftId = '';
        }

        UserInfo.set(user);
      } finally {
        Loading.hide();
        if (mounted)
          setState(() {
            _loading = false;
          });
      }
      unawaited(Global.user.update(
        nickname: _nicknameController.text.trim(),
        avatar: avatar,
        avatarNft: _avatarFile != null ? '' : null,
        avatarNftId: _avatarFile != null ? '' : null,
        gender: _gender,
      ));
    }
    if (mounted) {
      Get.back();
    }
  }

  Future<void> _pickImage(context) async {
    FocusScope.of(context).unfocus();
    final file = await getImageFromCameraOrFile(context, crop: true);
    if (file != null) {
      setState(() {
        _avatar = '';
        _avatarFile = file;
      });
      updateEnableConfirm();
    }
  }

  void _onNicknameChange(String value) {
    updateEnableConfirm();
  }

  void updateEnableConfirm() {
    final textLen = _nicknameController.text.trim().characters.length;
    if (mounted) {
      setState(() {
        _enableConfirm = textLen >= minNickNameLength &&
            textLen <= maxNickNameLength &&
            (isNotNullAndEmpty(_avatar) || _avatarFile != null) &&
            [1, 2].contains(_gender);
      });
    }
  }
}
