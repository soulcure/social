import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oktoast/oktoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:x_picker/x_picker.dart';

export 'package:im/utils/content_checker.dart';

XPicker xPicker = XPicker.fromPlatform();

//打开相册
Future<XFile> openImagePicker(BuildContext context) async {
  XFile pickedFile;
  // 从相册选择图片
  final bool authed = await checkSystemPermissions(
    context: context,
    permissions: [
      if (getPlatform() == 'ios') Permission.photos else Permission.storage
    ],
    // rejectedTips: "请允许访问相册",
  );
  if (authed != true) return null;

  final mobileOptions = PickImageMobileOptions(
    maxHeight: 1024,
    maxWidth: 1024,
    imageQuality: 100,
  );

  pickedFile = await xPicker.pickMedia(
    type: MediaType.IMAGE,
    mobileOptions: mobileOptions,
  );

  if (pickedFile != null) {
    if (pickedFile.path.isEmpty) {
      //ios14开启所选照片权限后选择权限之外的照片进行该提示
      showToast('无权限访问当前选中文件，请确认您的相册权限'.tr);
      return null;
    }
    final file = File(pickedFile.path);
    final fileLength = file.lengthSync();
    if (!file.existsSync() || fileLength <= 0) {
      showToast('文件破损,请选择其他文件'.tr);
      return null;
    }
    if (fileLength > 20 * 1024 * 1024) {
      showToast('文件过大,请选择其他文件'.tr);
      return null;
    }
  }

  return pickedFile;
}

//打开相机
Future<XFile> openCamera(BuildContext context) async {
  // 拍照选择图片
  final bool authed = await checkSystemPermissions(
    context: context,
    permissions: [Permission.camera],
    // rejectedTips: "请允许相机权限",
  );
  if (authed != true) return null;

  final mobileOptions = PickImageMobileOptions(
    source: ImageSource.camera,
    maxHeight: 750,
    maxWidth: 750,
    imageQuality: 100,
  );

  final pickedFile = await xPicker.pickMedia(
    type: MediaType.BOTH,
    mobileOptions: mobileOptions,
  );

  return pickedFile;
}

Future<File> getImageFromCameraOrFile(BuildContext context,
    {String title,
    bool crop = false,
    CropAspectRatio cropRatio,
    // VoidCallback beforeCheck,
    int compressQuality = 100,
    int maxWidth,
    int maxHeight,
    CheckType checkType = CheckType.defaultType,
    String channel = ImageChannelType.headImage}) async {
  final _theme = Theme.of(context);

  title ??= '设置个人头像'.tr;

  /// 弹出选择图片ActionSheet
  final res = await showCustomActionSheet([
    Text('拍照'.tr, style: _theme.textTheme.bodyText2),
    Text('从手机相册选择'.tr, style: _theme.textTheme.bodyText2),
  ]);

  if (res == null) {
    /// 取消选择图片
    return null;
  }

  /// 从拍照或相册选取的图片文件
  XFile pickedFile;
  if (res == 0) {
    /// 是否首次打开相机
    final isFirstOpenCamera = SpService.to.getBool(SP.isFirstOpenCamera);
    if (UniversalPlatform.isAndroid && (isFirstOpenCamera ?? true)) {
      await SpService.to.setBool(SP.isFirstOpenCamera, false);
      final bool isConfirm = await showConfirmDialog(
          title: '"%s"  想访问您的照片，如果不被允许，您将无法发送相册中的图片和视频'
              .trArgs([Global.packageInfo.appName]));
      if (isConfirm != null && isConfirm == true) {
        pickedFile = await openCamera(context);
      }
    } else {
      pickedFile = await openCamera(context);
    }
  } else if (res == 1) {
    /// 是否首次打开相册
    final isFirstOpenImagePicker =
        SpService.to.getBool(SP.isFirstOpenImagePicker);
    if (UniversalPlatform.isAndroid && (isFirstOpenImagePicker ?? true)) {
      await SpService.to.setBool(SP.isFirstOpenImagePicker, false);
      final bool isConfirm = await showConfirmDialog(
          title: '"%s"  想访问您的照片，如果不被允许，您将无法发送相册中的图片和视频'
              .trArgs([Global.packageInfo.appName]));
      if (!(isConfirm == true)) {
        return null;
      }
    }

    pickedFile = await openImagePicker(context);
  }

  if (pickedFile == null) {
    /// 选择图片失败
    return null;
  }

  /// 最终返回的图片文件
  File resultFile;
  if (crop) {
    // 图片需要缩放
    resultFile = await imageCrop(
      pickedFile,
      cropRatio: cropRatio,
      compressQuality: compressQuality,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
    );
  } else {
    // 直接返回选择的图片
    resultFile = File(pickedFile.path);
  }

  if (resultFile == null) {
    return null;
  }

  /// 审核敏感图片
  Loading.show(context);
  try {
    final checkResult = await CheckUtil.startCheck(ImageCheckItem.fromFile(
      [resultFile],
      channel,
      checkType: checkType,
      needCompress: true,
    ));
    Loading.hide();
    return checkResult ? resultFile : null;
  } catch (e) {
    Loading.hide();
    return null;
  }
}

Future<File> imageCrop(
  XFile file, {
  CropAspectRatio cropRatio,
  int compressQuality = 90,
  int maxWidth = 375,
  int maxHeight = 375,
}) async {
  final File croppedFile = await ImageCropper.cropImage(
      sourcePath: file.path,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      compressQuality: compressQuality,
      aspectRatio: cropRatio ?? const CropAspectRatio(ratioX: 1, ratioY: 1.01),
      androidUiSettings: AndroidUiSettings(
        statusBarColor: Colors.black,
        toolbarTitle: '图片裁剪'.tr,
        // toolbarColor: Theme.of(context).primaryColor,
        toolbarWidgetColor: Colors.black,
        initAspectRatio: CropAspectRatioPreset.original,
        lockAspectRatio: true,
      ),
      iosUiSettings: IOSUiSettings(
        cancelButtonTitle: '取消'.tr,
        doneButtonTitle: '完成'.tr,
        minimumAspectRatio: 1,
        aspectRatioPickerButtonHidden: true,
      ));

  return croppedFile;
}
