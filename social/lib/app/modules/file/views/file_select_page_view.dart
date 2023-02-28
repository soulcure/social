import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/file_send_history_bean_entity.dart';
import 'package:im/app/modules/file/controllers/file_select_controller.dart';
import 'package:im/app/modules/file/file_manager/file_manager.dart';
import 'package:im/app/modules/file/views/file_select_pop_window.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/search/search_util.dart';
import 'package:im/pages/search/widgets/search_input_box.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/file_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:oktoast/oktoast.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../icon_font.dart';
import '../../../../svg_icons.dart';

///
/// - 描述：文件选择
///
/// - author: seven
/// - data: 2021/10/18 3:13 下午
class FileSelectPageView extends StatefulWidget {
  const FileSelectPageView({Key key}) : super(key: key);

  @override
  _FileSelectPageViewState createState() => _FileSelectPageViewState();
}

class _FileSelectPageViewState extends State<FileSelectPageView> {
  @override
  Widget build(BuildContext context) {
    final theme = Get.theme;
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: CustomAppbar(
          backgroundColor: theme.backgroundColor,
          leadingBuilder: (icon) {
            return IconButton(
              icon: Icon(
                IconFont.buffNavBarCloseItem,
                size: icon.size,
                color: icon.color,
              ),
              onPressed: Get.back,
            );
          },
          titleBuilder: (textStyle) {
            return _buildTitle();
          }),
      body: Stack(
        children: [
          _buildHistory(theme),
          _buildFileSelectPop(),
        ],
      ),
    );
  }

  /// - 显示文件选择项
  Widget _buildFileSelectPop() {
    return GetBuilder<FileSelectController>(
        id: FileSelectController.showTitleUpdated,
        builder: (controller) {
          return AnimatedOpacity(
            opacity: controller.isShowPopView ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: Visibility(
              visible: controller.isShowPopView,
              child: FileSelectPopWindow(
                onClick: (itemType) {
                  if (itemType == ClickType.storage) {
                    // 选择文件上传，关闭当前页面，弹出系统文件选择器
                    Get.back(result: ['systemFile']);
                  } else if (itemType == ClickType.photo) {
                    // 选择打开相册上传，关闭当前页面，弹出系统相册选择器
                    Get.back(result: ['photo']);
                  } else {
                    controller.switchShowPopView();
                  }
                },
              ),
            ),
          );
        });
  }

  /// - 构建历史收发文件列表页面
  Widget _buildHistory(ThemeData theme) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // 点击空白处 收起键盘
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context),
            Expanded(
              child: GetBuilder<FileSelectController>(
                id: FileSelectController.historyListUpdated,
                builder: (controller) => controller.fileList.isEmpty
                    ? SearchNullView(
                        svgName: SvgIcons.nullState,
                        text: '搜索历史文件'.tr,
                      )
                    : ListView.separated(
                        controller: controller.scrollController,
                        shrinkWrap: true,
                        itemCount: controller.fileList.length ?? 0,
                        itemBuilder: (context, i) => _buildHistoryItem(
                          context,
                          controller.fileList[i],
                          controller,
                        ),
                        separatorBuilder: (context, index) => Container(
                          margin: const EdgeInsets.only(left: 50),
                          child: Divider(
                            height: 0.5,
                            color: const Color(0xFF8F959E).withOpacity(0.15),
                          ),
                        ),
                      ),
              ),
            ),
            _buildBottomSend(),
          ],
        ),
      ),
    );
  }

  /// - 底部发送控件
  Widget _buildBottomSend() {
    return Container(
      width: Get.width,
      height: 52,
      alignment: Alignment.center,
      child: Column(
        children: [
          Divider(
            height: 0.5,
            color: const Color(0xFF8F959E).withOpacity(0.2),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GetBuilder<FileSelectController>(
                  id: FileSelectController.historyListUpdated,
                  builder: (controller) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (controller.canSend())
                          Text(
                            '已选：%s'.trArgs([controller.selectFileMsg()]),
                            style: Get.theme.textTheme.bodyText2.copyWith(
                              fontSize: 14,
                              color: Get.theme.primaryColor,
                              height: 1.25,
                            ),
                          )
                        else
                          Text(
                            '已选：0个文件'.tr,
                            style: Get.theme.textTheme.bodyText2.copyWith(
                              fontSize: 14,
                              color: Get.theme.disabledColor,
                              height: 1.25,
                            ),
                          ),
                        if (controller.canSend())
                          InkWell(
                            onTap: () {
                              final fileSelects = controller.getSelectFiles();
                              if (fileSelects.isEmpty) {
                                showToast('请选择文件'.tr);
                              } else {
                                Get.back(result: fileSelects);
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Get.theme.primaryColor,
                              ),
                              height: 32,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              child: Text(
                                '发送(%s/9)'.trArgs(
                                    [controller.selectCount().toString()]),
                                style: Get.theme.textTheme.bodyText2.copyWith(
                                  fontSize: 14,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFFF5F5F8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '发送'.tr,
                              style: Get.theme.textTheme.bodyText2.copyWith(
                                fontSize: 14,
                                color:
                                    Get.theme.disabledColor.withOpacity(0.75),
                                height: 1.25,
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }

  /// - 历史列表的item
  Widget _buildHistoryItem(
    BuildContext context,
    FileSendHistoryBeanEntity fileItem,
    FileSelectController controller,
  ) {
    final theme = Get.theme;
    return InkWell(
      onTap: () {
        controller.hideSoftInput();
        if (!fileItem.isSelected && controller.selectCount() >= 9) {
          showToast('单次最多选取9个文件'.tr);
        } else if (fileItem.size >
            FileManager().getSupportMaxSize() * 1024 * 1024) {
          // 单个文件超过上限
          showToast('单个文件最大${FileManager().getSupportMaxSize()}MB'.tr);
        } else if (FileManager()
            .fileUploadTasks
            .where((element) => element.filePath == fileItem.path)
            .toList()
            .isNotEmpty) {
          showToast('当前文件正在上传，请稍后重试'.tr);
        } else {
          controller.changeCheck(fileItem);
        }
      },
      child: SizedBox(
        width: double.infinity,
        height: 68,
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Icon(
                fileItem.isSelected
                    ? IconFont.buffSelectCheck
                    : IconFont.buffSelectUncheck,
                color: fileItem.isSelected
                    ? Get.theme.primaryColor
                    : const Color(0xFF8F959E).withOpacity(0.5),
                size: 22,
              ),
            ),
            WebsafeSvg.asset(
                FileUtil.getFileSvgIcons(
                  FileUtil.getFileType(fileItem.name),
                  FileUtil.getFileExt(fileItem.name),
                  isCircle: true,
                ),
                width: 40,
                height: 40),
            sizeWidth12,
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Text(
                      fileItem.name.breakWord,
                      style: theme.textTheme.bodyText2.copyWith(
                        color: const Color(0xFF363940),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  sizeHeight6,
                  Row(
                    children: [
                      Text(
                        FileUtil.getFileSize(fileItem.size),
                        style: theme.textTheme.bodyText2.copyWith(
                          color: const Color(0xFF8F959E),
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.zero,
                        height: 12,
                        child: VerticalDivider(
                          color: const Color(0xFF8F959E).withOpacity(0.4),
                          width: 16,
                          thickness: 1,
                        ),
                      ),
                      Text(
                        '创建时间：%s'
                            .trArgs([_getMessageTime(fileItem.updateTime)]),
                        style: theme.textTheme.bodyText2.copyWith(
                          color: const Color(0xFF8F959E),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// - 换算时间
  String _getMessageTime(int time) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(time);
    if (OrientationUtil.portrait)
      return formatDate2Str(dateTime, showToday: true);
    else
      return lastMsgFormatDate2Str(dateTime);
  }

  /// - 输入栏
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, top: 6, right: 12, bottom: 12),
      child: GetBuilder<FileSelectController>(builder: (controller) {
        return SizedBox(
          height: 36,
          child: SearchInputBox(
            autoFocus: false,
            searchInputModel: controller.searchInputModel,
            inputController: controller.searchInputController,
            height: 36,
            hintText: '搜索'.tr,
            focusNode: controller.searchInputModel.inputFocusNode,
          ),
        );
      }),
    );
  }

  /// - 构建中间的标题
  Widget _buildTitle() {
    return GetBuilder<FileSelectController>(
        id: FileSelectController.showTitleUpdated,
        builder: (controller) {
          return InkWell(
            onTap: () {
              controller.hideSoftInput();
              controller.switchShowPopView();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              height: 44,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fanbook文件'.tr,
                    style: Get.textTheme.bodyText2.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  sizeWidth2,
                  Transform.rotate(
                    //旋转90度
                    angle: math.pi * (controller.isShowPopView ? 1 : 0),
                    child: const Icon(
                      IconFont.buffFilePullDown,
                      size: 20,
                      color: Color(0xFF363940),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
