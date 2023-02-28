import 'dart:typed_data';

import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/extension/state_extension.dart';
import 'package:im/web/utils/image_picker/image_picker.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/circle_icon.dart';
import 'package:im/widgets/custom_inputbox_web.dart';
import 'package:oktoast/oktoast.dart';

class WebCircleBaseInfo extends StatefulWidget {
  final CircleInfoDataModel circleInfoDataModel;

  const WebCircleBaseInfo(this.circleInfoDataModel);

  @override
  _WebCircleBaseInfoState createState() => _WebCircleBaseInfoState();
}

class _WebCircleBaseInfoState extends State<WebCircleBaseInfo> {
  Uint8List _selectImage;
  TextEditingController _nameController;
  TextEditingController _descController;
  String originCircleName;
  String originDesc;
  String originCircleIcon;

  @override
  void initState() {
    originCircleName = widget.circleInfoDataModel.circleName;
    originDesc = widget.circleInfoDataModel.description;
    originCircleIcon = widget.circleInfoDataModel.circleIcon;
    _nameController =
        TextEditingController(text: widget.circleInfoDataModel.circleName);
    _descController =
        TextEditingController(text: widget.circleInfoDataModel.description);
    checkFormChanged();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      formDetectorModel.setCallback(onReset: _onReset, onConfirm: _onConfirm);
    });
    super.initState();
  }

  bool get formChanged {
    return originCircleName != _nameController.text ||
        originDesc != _descController.text ||
        _selectImage != null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formItem(label: '圈子头像'.tr, child: _buildAvatar(originCircleIcon)),
        sizeHeight24,
        _formItem(label: '圈子昵称'.tr, child: _buildName()),
        sizeHeight24,
        _formItem(label: '圈子简介'.tr, child: _buildDesc()),
        sizeHeight32,
      ],
    );
  }

  Widget _buildAvatar(String avatar) {
    return GestureDetector(
      onTap: _pickImage,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 64,
          height: 64,
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
                decoration: (_selectImage == null && avatar.isEmpty)
                    ? DottedDecoration(
                        shape: Shape.circle,
                        borderRadius: BorderRadius.circular(
                            10), //remove this to get plane rectange
                      )
                    : null,
                child: avatar.isNotEmpty
                    ? Avatar(
                        url: avatar,
                      )
                    : const SizedBox(),
              ),
              const Align(
                  alignment: Alignment.bottomRight,
                  child: CircleIcon(
                    icon: Icons.camera_alt,
                    backgroundColor: Colors.black,
                    color: Colors.white,
                    radius: 12,
                    size: 15,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildName() {
    return WebCustomInputBox(
      controller: _nameController,
      fillColor: Theme.of(context).backgroundColor,
      hintText: '请输入圈子昵称'.tr,
      maxLength: 30,
      onChange: (val) => checkFormChanged(),
    );
  }

  Widget _buildDesc() {
    return WebCustomInputBox(
      controller: _descController,
      fillColor: Theme.of(context).backgroundColor,
      hintText: '请描述圈子的用途、公告、规则等信息'.tr,
      maxLength: 30,
      onChange: (val) => checkFormChanged(),
    );
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker.pickFile(accept: 'image/*');
    if (image != null) {
      try {
        final fileBytes = await image.pickedFile.readAsBytes();
        final info = await getImageInfoByProvider(MemoryImage(fileBytes))
            .timeout(const Duration(seconds: 1))
            .then((value) {});
        if (info != null && (info.image.width < 1 || info.image.height < 1)) {
          showToast('该图片已损坏，请重新选择'.tr);
          return;
        }
        setState(() {
          _selectImage = fileBytes;
        });
        checkFormChanged();
      } catch (e) {
        print('e: $e');
        showToast('该图片已损坏，请重新选择'.tr);
      }
    }
  }

  Widget _formItem({@required String label, @required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text(
            '$label：',
            style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14),
          ),
        ),
        sizeWidth8,
        Expanded(child: child),
      ],
    );
  }

  void checkFormChanged() {
    formDetectorModel.toggleChanged(formChanged);

    final nameLen = _nameController.text.trim().characters.length;
    final descLen = _descController.text.trim().characters.length;
    final enable = nameLen > 0 && nameLen <= 30 && descLen <= 30;
    formDetectorModel.confirmEnabled(enable);
  }

  Future<void> _onConfirm() async {
    final channelId = widget.circleInfoDataModel.channelId;
    final guildId = widget.circleInfoDataModel.guildId;
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    if (name.isEmpty) {
      showToast('请输入圈子昵称'.tr);
      return;
    }
    if (name.characters.length > 30) {
      showToast('圈子昵称不能超过30个字符'.tr);
      return;
    }
    String icon;
    if (_selectImage != null) {
      // icon = await uploadFileIfNotExist(
      //     bytes: _selectImage, fileType: "circleIcon");
      icon = await CosFileUploadQueue.instance
          .onceForBytes(_selectImage, CosUploadFileType.circleIcon);
    }

    await CircleApi.updateCircle(
      channelId,
      guildId,
      icon: icon,
      name: name,
      description: desc,
    );
    if (icon != null) originCircleIcon = icon;
    _selectImage = null;
    originDesc = desc;
    originCircleName = name;

    checkFormChanged();
  }

  Future<void> _onReset() async {
    setState(() {
      _selectImage = null;
      _nameController.value = TextEditingValue(
          text: originCircleName,
          selection: TextSelection.collapsed(offset: originCircleName.length));
      _descController.value = TextEditingValue(
          text: originDesc,
          selection: TextSelection.collapsed(offset: originDesc.length));
    });
    checkFormChanged();
  }
}
