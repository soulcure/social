import 'package:flutter/material.dart';
import 'package:flutter_filereader/flutter_filereader.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/file/controllers/file_preview_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/pages/home/json/file_entity.dart';
import 'package:im/pages/home/view/gallery/gallery.dart';
import 'package:im/pages/home/view/gallery/model/gallery_model.dart';
import 'package:im/pages/home/view/gallery/video_view.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/file_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:share/share.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../icon_font.dart';

/// - 描述：文件预览，目前只支持图片和视频
///
/// - author: seven
/// - data: 2021/11/15 10:44 上午
class FilePreviewPageView extends StatefulWidget {
  final FileEntity entity;

  const FilePreviewPageView(this.entity, {Key key}) : super(key: key);

  @override
  _FilePreviewPageState createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<FilePreviewPageView> {
  FilePreviewController controller;

  /// - 分享是否能够点击
  bool canShare = true;

  @override
  void initState() {
    controller = FilePreviewController(widget.entity);
    Get.put(controller, tag: widget.entity.fileName);
    print(widget.entity.filePath);
    super.initState();
  }

  @override
  void dispose() {
    Get.delete<FilePreviewController>(tag: widget.entity.fileName);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.theme;
    return GetBuilder<FilePreviewController>(
        init: controller,
        tag: widget.entity.fileName,
        builder: (controller) {
          return Scaffold(
            backgroundColor: theme.backgroundColor,
            appBar: CustomAppbar(
              backgroundColor: theme.backgroundColor,
              leadingBuilder: (icon) {
                return IconButton(
                  icon: Icon(
                    IconFont.buffNavBarBackItem,
                    size: icon.size,
                    color: icon.color,
                  ),
                  onPressed: Get.back,
                );
              },
              title: controller.fileName.breakWord,
              actions: [
                AppbarIconButton(
                  icon: IconFont.buffMoreHorizontal,
                  onTap: () {
                    showMore(controller);
                  },
                ),
              ],
              elevation: 0.5,
            ),
            body: Stack(
              children: [
                _buildImage(theme, controller),
                _buildVideo(controller),
                _buildDocument(controller),
                _buildTxt(controller),
                _buildUnSupport(controller),
              ],
            ),
          );
        });
  }

  /// - 分享更多
  Future<dynamic> showMore(FilePreviewController controller) async {
    if (!canShare) return;

    if (UniversalPlatform.isAndroid) {
      canShare = false;
    }
    await Share.shareFiles([controller.filePath]);
    if (UniversalPlatform.isAndroid) {
      // fix: Android分享大文件，文件会被copy到内存中，反复多次点击分享会造成Android的ANR，
      // 这里采用延迟3秒恢复点击的防抖措施
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          canShare = true;
        }
      });
    }
  }

  Widget _buildImage(ThemeData theme, FilePreviewController controller) {
    return Visibility(
      visible: controller.fileIsImage && controller.isSupportPreview(),
      child: Container(
        width: Get.width,
        height: Get.height,
        color: Colors.black,
        child: Gallery(
          items: [
            GalleryItem(
              filePath: controller.filePath,
              url: controller.fileUrl,
              isImage: controller.fileIsImage,
            )
          ],
          isNeedLocation: false,
        ),
      ),
    );
  }

  Widget _buildVideo(FilePreviewController controller) {
    return Visibility(
      visible: controller.fileIsVideo && controller.isSupportPreview(),
      child: Container(
        width: Get.width,
        height: Get.height,
        color: Colors.black,
        child: VideoView(
          isFile: controller.fileIsFile,
          videoUrl: controller.filePath,
          autoPlay: true,
          model: GalleryModel(isShowBack: false),
        ),
      ),
    );
  }

  Widget _buildDocument(FilePreviewController controller) {
    return Visibility(
      visible: controller.fileIsDocument && controller.isSupportPreview(),
      child: Container(
        width: Get.width,
        height: Get.height,
        color: Get.theme.backgroundColor,
        child: FileReaderView(
          filePath: controller.filePath,
          unSupportFileWidget: _buildUnSupport(
            controller,
            isError: true,
            hint: '文件解析失败!'.tr,
          ),
        ),
      ),
    );
  }

  Widget _buildTxt(FilePreviewController controller) {
    return Visibility(
      visible: controller.fileIsTxt && controller.isSupportPreview(),
      child: Container(
        width: Get.width,
        height: Get.height,
        color: Get.theme.backgroundColor,
        child: controller.iosTxtToGbkSuccess || UniversalPlatform.isAndroid
            ? FileReaderView(
                filePath: controller.filePath,
                unSupportFileWidget: _buildUnSupport(
                  controller,
                  isError: true,
                  hint: '文件解析失败!'.tr,
                ),
              )
            : _buildUnSupport(controller,
                isError: true,
                hint: controller.iosNotSupportTxt()
                    ? '文件过大，无法查看'.tr
                    : '文件解析失败!'.tr),
      ),
    );
  }

  /// - 不支持的文件显示页面
  Widget _buildUnSupport(FilePreviewController controller,
      {bool isError = false, String hint = ''}) {
    return Visibility(
      visible: !controller.isSupportPreview() || isError,
      child: Container(
        color: Get.theme.backgroundColor,
        width: Get.width,
        height: Get.height,
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  sizeHeight100,
                  _buildFileIcon(controller.fileEntity),
                  sizeHeight34,
                  Text(
                    controller.fileName.breakWord,
                    style: Get.theme.textTheme.bodyText2.copyWith(
                      color: const Color(0xFF363940),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  sizeHeight20,
                  Text(
                    '文件大小: %s'.trArgs(
                        [FileUtil.getFileSize(controller.fileEntity.fileSize)]),
                    style: Get.theme.textTheme.bodyText2.copyWith(
                      fontSize: 16,
                      color: const Color(0xFF8F959E),
                    ),
                  ),
                  sizeHeight20,
                  Visibility(
                    visible: hint.isNotEmpty,
                    child: Text(
                      hint,
                      style: Get.theme.textTheme.bodyText2.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF363940),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 130),
                child: FadeButton(
                  onTap: () {
                    showMore(controller);
                  },
                  width: 210,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Get.theme.primaryColor,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '用其他应用打开'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
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
      width: 60,
      height: 60,
    );
  }
}
