import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/json/file_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/file_controller.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/file_util.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../../icon_font.dart';

/// - 描述：聊天页面，文件类型的ui
///
/// - author: seven
/// - data: 2021/10/21 2:58 下午
/// - fixme 如果有相邻的重试上传文件，点击重试会出现ui位置刷新不准确的问题，还在找原因
class FileItem extends StatefulWidget {
  final FileEntity entity;
  final MessageEntity message;

  const FileItem({Key key, this.entity, this.message}) : super(key: key);

  @override
  _FileItemState createState() => _FileItemState();
}

class _FileItemState extends State<FileItem> {
  FileController controller;
  String tagId;

  @override
  void initState() {
    super.initState();

    // tagId =
    //     widget.entity.fileId + DateTime.now().millisecondsSinceEpoch.toString();
    tagId = widget.entity.fileId;
    widget.entity.controllerTagId = tagId;
    controller = FileController.to(
      widget.entity.fileName,
      widget.message.userId,
      widget.entity.fileId,
      tagId,
    );
    controller.entity = widget.entity;
    controller.messageId = widget.message.messageId;
    controller.fileSavePath(widget.entity);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FileController>(
        init: controller,
        tag: tagId,
        builder: (controller) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F8),
              borderRadius: BorderRadius.circular(4),
            ),
            width: 287,
            child: InkWell(
              onTap: () {
                // 文件点击 本地没有？下载：打开
                controller.openFile(context, widget.entity);
              },
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFileIcon(widget.entity),
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildFileMessage(widget.entity, controller),
                              _buildFileCancelDownload(
                                  widget.entity, controller),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: controller.hasFileTask(),
                    child: Positioned(
                      left: 2,
                      right: 2,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: controller.progressValue,
                        minHeight: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF5562F2)),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  /// - 构建文件取消下载控件
  Widget _buildFileCancelDownload(
      FileEntity entity, FileController controller) {
    return Visibility(
      visible: controller.hasFileTask(),
      child: InkWell(
        onTap: () async {
          final res = await showConfirmDialog(
              title: '确定终止${controller.isUploading ? '上传' : '下载'}？'.tr,
              confirmText: '确定'.tr,
              confirmStyle: Get.theme.textTheme.bodyText2
                  .copyWith(fontSize: 16, color: primaryColor),
              barrierDismissible: true);
          if (res) {
            final isUploading = controller.isUploading;
            controller.cancelTask();
            if (isUploading) {
              // 终止上传,删除消息体
              TextChannelController.to(channelId: widget.message.channelId)
                  .deleteMessage(widget.message.messageId);
            }
          }
        },
        child: Container(
          alignment: Alignment.center,
          width: 40,
          height: 40,
          child: const Icon(
            IconFont.buffFileCancel,
            size: 22,
            color: Color(0xFF646A73),
          ),
        ),
      ),
    );
  }

  /// - 构建文件信息
  Widget _buildFileMessage(FileEntity entity, FileController controller) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.only(
          left: 12,
          right: controller.hasFileTask() ? 0 : 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entity.fileName.breakWord,
              style: Get.theme.textTheme.bodyText2
                  .copyWith(color: const Color(0xFF363940)),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            sizeHeight6,
            SizedBox(
              height: 15,
              child: Row(
                children: [
                  Text(
                    FileUtil.getFileSize(entity.fileSize),
                    style: Get.theme.textTheme.bodyText2.copyWith(
                      fontSize: 12,
                      color: const Color(0xFF8F959E),
                    ),
                  ),
                  sizeWidth12,
                  Text(
                    controller.fileCurrentStatusMsg(entity),
                    style: Get.theme.textTheme.bodyText2.copyWith(
                      fontSize: 12,
                      color: const Color(0xFF8F959E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// - 构建文本的Icon
  Widget _buildFileIcon(FileEntity entity) {
    final fileType = FileUtil.getFileTypeByIndex(entity.fileType - 1);
    return WebsafeSvg.asset(
      FileUtil.getFileSvgIcons(fileType, entity.fileExt),
      width: 40,
      height: 40,
    );
  }
}
