import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/bottom_bar/keyboard_container2.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_callback_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_base.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tun_editor/controller.dart';
import 'package:tun_editor/tun_editor_toolbar.dart';
import 'package:tuple/tuple.dart';

import '../../../../../../global.dart';
import '../../../../../../routes.dart';
import '../../../check_permission.dart';
import '../model/editor_model_tun.dart';

class ToolbarTunCallback extends ToolbarCallbackBase {
  @override
  Future<void> showAtList(BuildContext context, RichEditorModelBase model,
      {bool fromInput = false}) {
    return showTunAtList(context, model, fromInput: fromInput);
  }

  @override
  Future<void> showChannelList(BuildContext context, RichEditorModelBase model,
      {bool fromInput = false}) {
    return showTunChannelList(context, model, fromInput: fromInput);
  }

  @override
  Future<void> pickImages(BuildContext context, RichEditorModelBase model) {
    return pickImagesTun(context, model);
  }

  @override
  Future<void> showEmojiTab(BuildContext context, RichEditorModelBase model) {
    return showTunEmojiTab(context, model);
  }

  Future<void> showTunChannelList(
      BuildContext context, RichEditorModelBase modelBase,
      {bool fromInput = false}) async {
    final model = modelBase as RichTunEditorModel;
    model.tabIndex.value = null;
    model.expand.value = KeyboardStatus.hide;

    final controller = model.editorController;
    final ChatChannel channel =
        await Routes.pushRichEditorChannelListPage(context);
    if (channel == null) {
      // model.editorFocusNode.requestFocus();
      return;
    }
    final String channelId = TextEntity.getChannelLinkString(channel.id);
    final String channelMark = '#${channel.name}';

    controller.insertMention(channelId, channelMark,
        prefixChar: '#', replaceLength: fromInput ? 1 : 0, appendSpace: true);
  }

  Future<void> showTunAtList(
      BuildContext context, RichEditorModelBase modelBase,
      {bool fromInput = false}) async {
    final model = modelBase as RichTunEditorModel;
    model.tabIndex.value = null;
    model.expand.value = KeyboardStatus.hide;
    final controller = model.editorController;
    final List res = await Routes.pushRichEditorAtListPage(context,
        channel: model.channel, guildId: model.channel.guildId);
    if (res == null || res.isEmpty) {
      return;
    }
    res.forEach((e) {
      String atId = '';
      String atMark = '';
      if (e is Role) {
        atId = TextEntity.getAtString(e.id, true);
        atMark = '@${e.name}';
      } else if (e is UserInfo) {
        atId = TextEntity.getAtString(e.userId, false);
        atMark = '@${e.showName(guildId: model.channel.guildId)}';
      }
      controller.insertMention(atId, atMark,
          prefixChar: '@', replaceLength: fromInput ? 1 : 0, appendSpace: true);
    });
  }

  Future<void> showTunEmojiTab(
      BuildContext context, RichEditorModelBase modelBase) async {
    final model = modelBase as RichTunEditorModel;
    model.editorFocusNode.unfocus();
    model.expand.value = KeyboardStatus.extend_keyboard;
    model.tabIndex.value = ToolbarMenu.emoji;
  }

  Future<void> pickImagesTun(
      BuildContext context, RichEditorModelBase modelBase) async {
    /// 检测相册权限
    final hasPermission = await checkPhotoAlbumPermissions();

    /// 未授权
    if (hasPermission != true) return;
    final model = modelBase as RichTunEditorModel;
    try {
      model.editorFocusNode.unfocus();
      final controller = model.editorController;
      final mediaNum = controller.document
          .toDelta()
          .toList()
          .where((element) => element.isImage || element.isVideo)
          .length;
      if (model.maxMediaNum - mediaNum <= 0) {
        showToast('最多只能上传%s个文件'.trArgs([mediaNum.toString()]));
        return;
      }
      model.tabIndex.value = null;
      model.expand.value = KeyboardStatus.hide;
      final maxNum = min(9, model.maxMediaNum - mediaNum);
      final result = await MultiImagePicker.pickImages(
          maxImages: maxNum,
          doneButtonText: '确定'.tr,
          cupertinoOptions: CupertinoOptions(
              takePhotoIcon: "chat",
              selectionStrokeColor:
                  "#${Theme.of(context).primaryColor.value.toRadixString(16)}",
              selectionFillColor:
                  "#${Theme.of(context).primaryColor.value.toRadixString(16)}"),
          materialOptions: MaterialOptions(
            allViewTitle: "所有图片".tr,
            selectCircleStrokeColor:
                "#${Theme.of(context).primaryColor.value.toRadixString(16)}",
          ));
      final List<String> identifiers = [];
      for (final item in result['identifiers']) {
        identifiers.add(item.toString());
      }
      // await delay(() => {}, 1000);
      // model.editorFocusNode.requestFocus();
      unawaited(
        insertImageWithTun(
            context,
            (result['identifiers'] as List).cast<String>(),
            controller,
            !(result['thumb'] ?? false),
            model),
      );
    } on Exception catch (e) {
      if (e is PlatformException) {
        if (e.code == "PERMISSION_PERMANENTLY_DENIED") {
          await checkSystemPermissions(
            context: context,
            permissions: [
              if (UniversalPlatform.isIOS) Permission.photos,
              if (UniversalPlatform.isAndroid) Permission.storage,
            ],
          );
        } else if (e.code == "CANCELLED") {
          // model.editorFocusNode.requestFocus();
        }
      }
    }
  }

  Future<void> insertImage(
      BuildContext context,
      List<String> assets,
      TunEditorController controller,
      bool isOrigin,
      RichTunEditorModel model) async {
    Loading.show(context);
    List<Asset> assetList;
    final List<String> fileSizeList = [];
    final List<String> bigFileList = [];
    try {
      assetList = await MultiImagePicker.requestMediaData(
          thumb: !isOrigin, selectedAssets: assets);
      assetList.forEach((element) {
        fileSizeList.add("${File(element.filePath).lengthSync()}");
      });
      Loading.hide();
    } catch (e) {
      logger.severe('富文本获取媒体失败', e);
      Loading.hide();
    }
    for (int i = 0; i < assetList.length; i++) {
      final e = assetList[i];
      final fileSize = double.parse(fileSizeList[i] ?? '0');
      if (fileSize > 1024 * 1024 * 100) {
        bigFileList.add(e.name);
        continue;
      }
      final size = await _getMediaSize(e);
      if (e?.filePath != null && e.fileType.startsWith('image/')) {
        final checkPath = e.checkPath.hasValue
            ? e.checkPath.substring(e.checkPath.lastIndexOf('/') + 1)
            : e.name;
        controller.replaceText(
          controller.selection.end,
          0,
          ImageEmbed(
            width: size.item1,
            height: size.item2,
            source: e.name,
            checkPath: checkPath,
          ),
          TextSelection.collapsed(offset: controller.selection.end + 2),
          autoAppendNewlineAfterImage: e == assetList.last,
        );
      }

      if (e?.filePath != null && e.fileType.startsWith('video')) {
        controller.replaceText(
          controller.selection.end,
          0,
          VideoEmbed(
            width: size.item1,
            height: size.item2,
            source: e.name,
            fileType: e.fileType,
            duration: e.duration == null ? 0 : e.duration.toInt(),
            thumbUrl: e.thumbName,
          ),
          TextSelection.collapsed(offset: controller.selection.end + 2),
          autoAppendNewlineAfterImage: e == assetList.last,
        );
      }
    }
    if (bigFileList.isNotEmpty) {
      showToast('文件: %s 超出大小限制'.trArgs([bigFileList.join('、'.tr)]));
    }
  }

  Future<void> insertImageWithTun(
      BuildContext context,
      List<String> assets,
      TunEditorController controller,
      bool isOrigin,
      RichTunEditorModel model) async {
    Loading.show(context);
    List<Asset> assetList;
    final List<String> fileSizeList = [];
    final List<String> bigFileList = [];
    final List<Embeddable> insertEmbeds = [];
    try {
      assetList = await MultiImagePicker.requestMediaData(
          thumb: !isOrigin, selectedAssets: assets);
      assetList.forEach((element) {
        fileSizeList.add("${File(element.filePath).lengthSync()}");
      });
      Loading.hide();
    } catch (e) {
      logger.severe('富文本获取媒体失败', e);
      Loading.hide();
    }
    for (int i = 0; i < assetList.length; i++) {
      final e = assetList[i];
      final fileSize = double.parse(fileSizeList[i] ?? '0');
      if (fileSize > 1024 * 1024 * 100) {
        bigFileList.add(e.name);
        continue;
      }
      final size = await _getMediaSize(e);
      if (e?.filePath != null && e.fileType.startsWith('image/')) {
        final checkPath = e.checkPath.hasValue
            ? e.checkPath.substring(e.checkPath.lastIndexOf('/') + 1)
            : e.name;

        // controller.insertImage(
        //   name: '',
        //   source: e.name,
        //   width: size.item1,
        //   height: size.item2,
        //   checkPath: checkPath,
        //   appendNewLine: true,
        // );

        insertEmbeds.add(ImageEmbed(
            source: e.name,
            width: size.item1,
            height: size.item2,
            name: '',
            checkPath: checkPath));
      }

      if (e?.filePath != null && e.fileType.startsWith('video')) {
        // controller.insertVideo(
        //   source: e.name,
        //   width: size.item1,
        //   height: size.item2,
        //   thumbUrl: e.thumbName,
        //   thumbName: '',
        //   duration: e.duration ?? 0.0,
        //   fileType: e.fileType,
        // );
        insertEmbeds.add(VideoEmbed(
            width: size.item1,
            height: size.item2,
            source: e.name,
            fileType: e.fileType,
            duration: (e.duration ?? 0.0).toInt(),
            thumbUrl: e.thumbName));
      }
    }
    controller.batchInsertEmbed(
      embeds: insertEmbeds,
      appendNewLine: false,
      appendNewLineAfterImage: true,
      appendNewLineAfterVideo: true,
    );
    controller.focus();
    if (bigFileList.isNotEmpty) {
      showToast('文件: %s 超出大小限制'.trArgs([bigFileList.join('、'.tr)]));
    }
  }
}

Future<Tuple2<double, double>> _getMediaSize(Asset e) async {
  double width = 0;
  double height = 0;
  if (e.fileType.startsWith('image/')) {
    width = e.originalWidth;
    height = e.originalHeight;
    if (width == 0 || width == null) {
      final res = await getImageInfoByProvider(
          FileImage(File('${Global.deviceInfo.thumbDir}${e.name}')));
      width = res.image.width.toDouble();
      height = res.image.height.toDouble();
    }
  } else if (e.fileType.startsWith('video')) {
    width = e.thumbWidth;
    height = e.thumbHeight;
    if (width == 0 || width == null) {
      final res = await getImageInfoByProvider(
          FileImage(File('${Global.deviceInfo.thumbDir}${e.thumbName}')));
      width = res.image.width.toDouble();
      height = res.image.height.toDouble();
    }
  }
  return Tuple2(width, height);
}
