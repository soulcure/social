// ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/pages/home/view/bottom_bar/keyboard_container2.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_callback_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/abstract_rich_text_factory.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/sub_page/at_page/at_list_page.dart';
import 'package:im/web/utils/image_picker/image_picker.dart';
import 'package:im/web/utils/show_rich_editor_tooltip.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:oktoast/oktoast.dart';
import 'package:universal_html/html.dart' as html;

import '../model/editor_model.dart';

class ToolbarCallback extends ToolbarCallbackBase {
  @override
  Future<void> showAtList(BuildContext context, RichEditorModelBase model,
      {bool fromInput = false}) {
    return showWebAtList(context, model, fromInput: fromInput);
  }

  @override
  Future<void> pickImages(BuildContext context, RichEditorModelBase model) {
    return pickImagesWeb(context, model);
  }

  @override
  Future<void> showEmojiTab(BuildContext context, RichEditorModelBase model) {
    return showWebEmojiTab(context, model);
  }

  Future<void> showWebAtList(
      BuildContext context, RichEditorModelBase modelBase,
      {bool fromInput = false}) async {
    final model = modelBase as RichEditorModel;
    FocusScope.of(context).unfocus();
    model.tabIndex.value = null;
    model.expand.value = KeyboardStatus.hide;

    await showWebRichEditorTooltip<bool>(context, builder: (c, done) {
      model.closeAtList = done;
      return SizedBox(
          height: 500,
          child: AtListPage(
            guildId: model.channel.guildId,
            channel: model.channel,
            onSelect: (list) {
              model.onSelectAt(list);
              done(true);
            },
            onClose: () => done(false),
          ));
    });
  }

  Future<void> showWebEmojiTab(
      BuildContext context, RichEditorModelBase modelBase) async {
    final model = modelBase as RichEditorModel;
    SuperTooltip _toolTop;
    _toolTop = SuperTooltip(
      arrowBaseWidth: 0,
      arrowLength: 0,
      arrowTipDistance: 0,
      borderWidth: 1,
      borderColor: const Color(0xff717D8D).withOpacity(0.1),
      shadowColor: const Color(0xff717D8D).withOpacity(0.1),
      outsideBackgroundColor: Colors.transparent,
      borderRadius: 4,
      popupDirection: TooltipDirection.rightTop,
      content: Material(
        child: SizedBox(
          width: 388,
          height: 280,
          child: AbstractRichTextFactory.instance.createRichEditorEmoji(
            model.editorController,
            onTap: () {
              _toolTop.close();
            },
          ),
        ),
      ),
    );
    _toolTop.show(context);
  }

  Future<void> pickImagesWeb(
      BuildContext context, RichEditorModelBase modelBase) async {
    final model = modelBase as RichEditorModel;
    final controller = model.editorController;
    final mediaNum = controller.document
        .toDelta()
        .toList()
        .where((element) => element.isImage || element.isVideo)
        .length;
    if (model.maxMediaNum - mediaNum <= 0) {
      showToast('已到达上传文件数量上限'.tr);
      return;
    }
    final List<html.File> originFiles =
        await ImagePicker.pickFile2(accept: 'image/*,video/*', multiple: true);
    final canUploadNum = min(model.maxMediaNum - mediaNum, 9);
    if (originFiles.isEmpty) return;
    final uploadFiles =
        originFiles.where((element) => element.size < 1024 * 1024 * 8).toList();
    final bool overFileSize = uploadFiles.length != originFiles.length;
    final bool overLimitNum = uploadFiles.length > canUploadNum;
    final uploadFilesLen = overLimitNum ? canUploadNum : uploadFiles.length;
    for (int i = 0; i < uploadFilesLen; i++) {
      final assetInfo = await webUtil.getAssetInfo(uploadFiles[i]);
      final isImage = assetInfo.fileType.startsWith('image/');
      final isVideo = assetInfo.fileType.startsWith('video/');
      if (isImage) {
        controller.replaceText(
          controller.selection.end,
          0,
          ImageEmbed(
            width: assetInfo.originalWidth,
            height: assetInfo.originalHeight,
            name: assetInfo.name,
            source: assetInfo.filePath,
          ),
          TextSelection.collapsed(offset: controller.selection.end + 2),
          // autoAppendNewlineAfterImage: i == uploadFilesLen - 1,
        );
      } else if (isVideo) {
        controller.replaceText(
          controller.selection.end,
          0,
          VideoEmbed(
            width: assetInfo.originalWidth.toInt(),
            height: assetInfo.originalHeight.toInt(),
            source: assetInfo.filePath,
            fileType: assetInfo.fileType,
            duration: assetInfo.duration.toInt(),
            thumbUrl: assetInfo.thumbFilePath,
            thumbName: assetInfo.thumbName,
          ),
          TextSelection.collapsed(offset: controller.selection.end + 2),
          // autoAppendNewlineAfterImage: i == uploadFilesLen - 1,
        );
      }
    }
    if (canUploadNum < 9) {
      showToast('最多只能上传%s个文件'.trArgs([model.maxMediaNum.toString()]));
      return;
    }
    if (overFileSize && overLimitNum) {
      showToast('一次最多只能上传9个大小小于8m的文件，已过滤掉大文件'.tr);
    } else if (overLimitNum) {
      showToast('一次最多只能上传9个文件'.tr);
    } else if (overFileSize) {
      showToast('只能上传大小小于8m的文件'.tr);
    }
  }

  @override
  Future<void> showChannelList(BuildContext context, RichEditorModelBase model,
      {bool fromInput = false}) {
    // TODO: implement showChannelList
    throw UnimplementedError();
  }
}
