import 'dart:typed_data';

import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/user_api.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/routes.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/themes/web_light_theme.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/web/utils/image_picker/image_picker.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/circle_icon.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

Future<bool> showLoginModifyUserInfoDialog(BuildContext context,
    {bool isRegistered = true}) async {
  if (isRegistered) {
    unawaited(SpService.to.setString(SP.unModifyInfo, Global.user.id));
  }
  return showDialog(
      context: context,
      builder: (_) {
        return LoginModifyUserInfoDialog(isRegistered: isRegistered);
      });
}

class LoginModifyUserInfoDialog extends StatefulWidget {
  final bool isRegistered;

  const LoginModifyUserInfoDialog({Key key, this.isRegistered = true})
      : super(key: key);

  @override
  _LoginModifyUserInfoDialogState createState() =>
      _LoginModifyUserInfoDialogState();
}

class _LoginModifyUserInfoDialogState extends State<LoginModifyUserInfoDialog> {
  int _gender = 0;
  bool _loading = false;
  String _avatar = '';
  Uint8List _selectImage;
  bool _enableConfirm = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    _controller.addListener(() {
      setState(updateEnableConfirm);
    });
    if (!widget.isRegistered) {
      _avatar = Global.user.avatar;
      _controller.text = Global.user.nickname;
      _gender = Global.user.gender;
      _enableConfirm = true;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    return GestureDetector(
      onTap: widget.isRegistered ? null : Get.back,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
            child: Container(
              width: 400,
              height: widget.isRegistered ? 520 : 440,
              decoration: webBorderDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Column(
                children: [
                  const SizedBox(
                    height: 60,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '设置你的个人信息'.tr,
                      style: _theme.textTheme.bodyText2
                          .copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(
                    height: 48,
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            foregroundDecoration: (_selectImage == null)
                                ? null
                                : BoxDecoration(
                                    image: DecorationImage(
                                        image: MemoryImage(_selectImage),
                                        fit: BoxFit.cover),
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(60)),
                            decoration:
                                (_selectImage == null && _avatar.isEmpty)
                                    ? DottedDecoration(
                                        shape: Shape.circle,
                                        borderRadius: BorderRadius.circular(
                                            10), //remove this to get plane rectange
                                      )
                                    : null,
                            child: _avatar.isNotEmpty
                                ? Avatar(
                                    url: _avatar,
                                  )
                                : const SizedBox(),
                          ),
                          const Align(
                              alignment: Alignment.bottomRight,
                              child: CircleIcon(
                                icon: Icons.camera_alt,
                                backgroundColor: Colors.black,
                                color: Colors.white,
                                radius: 14,
                                size: 18,
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                        color: _theme.backgroundColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFDEE0E3))),
                    height: 42,
                    child: TextField(
                      controller: _controller,
                      style: _theme.textTheme.bodyText2,
                      inputFormatters: <TextInputFormatter>[
                        LengthLimitingTextInputFormatter(30),
                      ],
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        fillColor: const Color(0x00000000),
                        filled: true,
                        hintText: "请输入用户名".tr,
                        hintStyle: _theme.textTheme.bodyText1,
                        suffixIcon: IconButton(
                            icon: Icon(
                              _controller.text.isEmpty
                                  ? null
                                  : IconFont.buffClose,
                              color: const Color(0xFFaaaaaa),
                              size: 20,
                            ),
                            onPressed: _controller.clear),
                      ),
//                onChanged: _onNicknameChange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.isRegistered) ...[
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '选定性别后不可再修改哦～'.tr,
                          style: _theme.textTheme.bodyText1,
                        )),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        _buildGenderItem(true),
                        sizeWidth16,
                        _buildGenderItem(false),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    // ignore: deprecated_member_use
                    child: FlatButton(
                      onPressed: _enableConfirm ? _onConfirm : null,
                      disabledColor: _theme.primaryColor.withOpacity(0.4),
                      disabledTextColor: Colors.white.withOpacity(0.4),
                      textColor: Colors.white,
                      color: _theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _loading
                          ? DefaultTheme.defaultLoadingIndicator(
                              color: Colors.white)
                          : Text(
                              '完成'.tr,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderItem(bool isMale) {
    final _theme = Theme.of(context);
    final icon = isMale ? IconFont.buffTabMale : IconFont.buffTabFemale;
    final text = isMale ? '男'.tr : '女'.tr;
    final isSelected = _gender == (isMale ? 1 : 2);

    return Flexible(
      child: GestureDetector(
        onTap: () {
          _gender = isMale ? 1 : 2;
          setState(updateEnableConfirm);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: isSelected ? _theme.primaryColor : _theme.backgroundColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : const Color(0xFFDEE0E3))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : _theme.textTheme.bodyText1.color.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 16,
                  color: isSelected ? _theme.primaryColor : Colors.white,
                ),
              ),
              sizeWidth10,
              Text(text,
                  style: _theme.textTheme.bodyText2.copyWith(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyText2.color)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onConfirm() async {
    /// 如果没有任何修改则立刻返回
    if (!widget.isRegistered &&
        _controller.text == Global.user.nickname &&
        _gender == Global.user.gender &&
        _selectImage == null) {
      Get.back();
      return;
    }

    if (_controller.text.trim().length < 2) {
      showToast('昵称需包括2-30个字符'.tr);
      return;
    }

    setState(() {
      _loading = true;
    });
    // final String avatar = _selectImage == null
    //     ? _avatar
    //     : await uploadFileIfNotExist(
    //         bytes: _selectImage, fileType: "headImage");
    final String avatar = _selectImage == null
        ? _avatar
        : await CosFileUploadQueue.instance
            .onceForBytes(_selectImage, CosUploadFileType.headImage);
    try {
      await UserApi.updateUserInfo(
          Global.user.id, _controller.text.trim(), avatar, _gender);
    } catch (e) {
      setState(() {
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = false;
    });
    unawaited(SpService.to.setString(SP.unModifyInfo, ''));
    if (widget.isRegistered) {
      await Routes.pushHomePage(context, queryString: webUtil.getQuery());
    } else
      Get.back();
    await Global.user.update(
      nickname: _controller.text.trim(),
      avatar: avatar,
      gender: _gender,
      avatarNft: _selectImage != null ? '' : null,
      avatarNftId: _selectImage != null ? '' : null,
    );
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker.pickFile(accept: 'image/*');
    if (image != null) {
      try {
        final size =
            await webUtil.compressImageFromElement(image.pickedFile.path);
        setState(() {
          _selectImage = size;
        });
        updateEnableConfirm();
      } catch (e) {
        print('e: $e');
        showToast('该图片已损坏，请重新选择'.tr);
      }
    }
  }

  void updateEnableConfirm() {
    _enableConfirm = (_gender != 0 || !widget.isRegistered) &&
        _controller.text.isNotEmpty &&
        (_selectImage != null || _avatar.isNotEmpty);
  }
}
