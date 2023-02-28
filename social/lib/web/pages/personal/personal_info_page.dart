import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/user_api.dart';
import 'package:im/const.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/tool/debug_page.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/web/extension/state_extension.dart';
import 'package:im/web/utils/image_picker/image_picker.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:im/web/widgets/button/web_hover_button.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/custom_inputbox_web.dart';
import 'package:im/widgets/id_with_copy.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';

class PersonalInfoPage extends StatefulWidget {
  @override
  _PersonalInfoPageState createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  bool _editing = false;
  Uint8List _headImageBytes;
  final _controller = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      formDetectorModel.setCallback(onConfirm: _onConfirm, onReset: _onReset);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: 648,
        height: 128,
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(4)),
        child: Row(
          children: [
            sizeWidth24,
            ChangeNotifierProvider.value(
              value: Global.user,
              child: Consumer<LocalUser>(builder: (context, user, _) {
                return Expanded(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                                foregroundDecoration: (_headImageBytes == null)
                                    ? null
                                    : BoxDecoration(
                                        image: DecorationImage(
                                            image: MemoryImage(_headImageBytes),
                                            fit: BoxFit.cover),
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(40)),
                                child: Avatar(url: user.avatar, radius: 40)),
                            if (_editing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                  ),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      IconFont.webImage,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),
                      sizeWidth16,
                      Expanded(
                        child: !_editing
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      RealtimeNickname(
                                        userId: user.id,
                                        breakWord: true,
                                        maxLength: 15,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2
                                            .copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                      sizeWidth4,
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                            color: user.gender == 1
                                                ? const Color(0xFF677CE6)
                                                : const Color(0xFFE900FE),
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: Icon(
                                          user.gender == 1
                                              ? IconFont.buffTabMale
                                              : IconFont.buffTabFemale,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  sizeHeight12,
                                  Padding(
                                    padding: const EdgeInsets.only(top: 1),
                                    child: IdWithCopy(user.username),
                                  ),
                                ],
                              )
                            : Container(
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Theme.of(context).dividerColor),
                                    borderRadius: BorderRadius.circular(4)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: WebCustomInputBox(
                                        controller: _controller,
                                        fillColor: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        borderColor: Colors.transparent,
                                        hintText: '请输入用户昵称'.tr,
                                        maxLength: maxNickNameLength,
                                        onChange: (val) {
                                          checkFormChanged();
                                        },
                                      ),
                                    ),
                                    sizeWidth16,
                                    const SizedBox(
                                      height: 20,
                                      width: 1,
                                      child: VerticalDivider(),
                                    ),
                                    sizeWidth16,
                                    Text(
                                      '#${user.username}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyText1
                                          .copyWith(fontSize: 12),
                                    ),
                                    sizeWidth16,
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            if (!_editing)
              WebHoverButton(
                width: 88,
                height: 32,
                padding: EdgeInsets.zero,
                color: Theme.of(context).primaryColor,
                borderRadius: 4,
                hoverColor: Theme.of(context).textTheme.bodyText2.color,
                onTap: () {
                  _controller.text = Global.user.nickname;
                  setState(() {
                    _editing = true;
                  });
                },
                child: Text(
                  '编辑'.tr,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2
                      .copyWith(color: Colors.white),
                ),
              ),
            sizeWidth24,
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    if (!_editing) {
      DebugPage.show();
      return;
    }
    final image = await ImagePicker.pickFile(accept: 'image/*');
    if (image.size > 8 * 1024 * 1024) {
      showToast('上传的头像不能超过8M\n如果需要上传更大的图片，请下载App');
      return;
    }
    if (image.size > 8) if (image != null) {
      try {
        final size =
            await webUtil.compressImageFromElement(image.pickedFile.path);
        final checkResult = await CheckUtil.startCheck(ImageCheckItem.fromBytes(
            [U8ListWithPath(size, image.pickedFile.path)],
            ImageChannelType.headImage,
            needCompress: true));
        if (!checkResult) {
          return;
        }
        setState(() {
          _headImageBytes = size;
        });
        checkFormChanged();
      } catch (e) {
        print('e: $e');
        showToast('该图片已损坏，请重新选择'.tr);
      }
    }
  }

  void _onReset() {
    setState(() {
      _controller.text = Global.user.nickname;
      _headImageBytes = null;
      _editing = false;
    });
    checkFormChanged();
  }

  Future<void> _onConfirm() async {
    if (_controller.text.trim().length < minNickNameLength ||
        _controller.text.trim().length > maxNickNameLength) {
      showToast('昵称需包括2-12个字符'.tr);
      return;
    }

    // final String avatar = _headImageBytes == null
    //     ? Global.user.avatar
    //     : await uploadFileIfNotExist(
    //         bytes: _headImageBytes, fileType: "headImage");
    final String avatar = _headImageBytes == null
        ? Global.user.avatar
        : await CosFileUploadQueue.instance
            .onceForBytes(_headImageBytes, CosUploadFileType.headImage);

    try {
      await UserApi.updateUserInfo(
          Global.user.id, _controller.text.trim(), avatar, Global.user.gender);

      final UserInfo user = Db.userInfoBox.get(Global.user.id);
      user.nickname = _controller.text.trim();
      user.avatar = avatar;
      user.gender = Global.user.gender;
      UserInfo.set(user);

      await Global.user.update(
        nickname: _controller.text.trim(),
        avatar: avatar,
        gender: Global.user.gender,
        avatarNft: _headImageBytes != null ? '' : null,
        avatarNftId: _headImageBytes != null ? '' : null,
      );
      _onReset();

      // TextChannelController.to().segmentMemberListModel?.updateUserInfo(user);
    } catch (e) {
      return;
    }
  }

  bool get formChanged {
    return Global.user.nickname != _controller.text || _headImageBytes != null;
  }

  void checkFormChanged() {
    formDetectorModel.toggleChanged(formChanged);
  }
}
