import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/doc_info_item.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/utils/tc_doc_utils.dart';

import '../../../../../icon_font.dart';
import '../../document_api.dart';

class DocLinkPreviewController extends GetxController {
  final String fileId;

  DocInfoItem docInfoItem;
  LoadingStatus loadingStatus;

  static Map<String, List<String>> fileIdMap = {};

  ///添加控制器tag
  static void addTag(String guildId, String tag) {
    if (guildId.noValue || tag.noValue) return;

    List list = fileIdMap[guildId];
    list ??= <String>[];
    list.add(tag);
    fileIdMap[guildId] = list;
  }

  ///清除上一个频道的控制器
  // static void removeTags() {
  //   final String guildId = ChatTargetsModel.instance.getLastChatTargetId();
  //   if (guildId.hasValue) {
  //     final list = fileIdMap[guildId];
  //     if (list != null && list.isNotEmpty) {
  //       list.forEach((tag) {
  //         if (Get.isRegistered<DocLinkPreviewController>(tag: tag)) {
  //           Get.delete<DocLinkPreviewController>(tag: tag);
  //         }
  //       });
  //     }
  //     fileIdMap.remove(guildId);
  //   }
  // }

  ///清除所有tag,排除当前选中服务台
  static void removeAllExcludeSelectGuild() {
    final guild = ChatTargetsModel.instance?.selectedChatTarget;
    fileIdMap.forEach((key, value) {
      if (key != guild?.id && value != null && value.isNotEmpty) {
        value.forEach((tag) {
          if (Get.isRegistered<DocLinkPreviewController>(tag: tag)) {
            Get.delete<DocLinkPreviewController>(tag: tag);
          }
        });
        value.clear();
      }
    });
  }

  ///清除所有tag
  static void removeAll() {
    fileIdMap.forEach((key, value) {
      if (value != null && value.isNotEmpty) {
        value.forEach((tag) {
          if (Get.isRegistered<DocLinkPreviewController>(tag: tag)) {
            Get.delete<DocLinkPreviewController>(tag: tag);
          }
        });
        value.clear();
      }
    });
    fileIdMap.clear();
  }

  static String getFileId(String url) {
    if (TcDocUtils.docUrlReg.hasMatch(url)) {
      final match = TcDocUtils.docUrlReg.firstMatch(url)?.group(0);
      if (match != null) {
        final int index = url.indexOf(match);
        final int start = index + match.length;
        try {
          final String fileId = url.substring(start);
          return Uri.decodeComponent(fileId);
        } catch (e) {
          print(e);
        }
      }
    }
    return '';
  }

  static DocLinkPreviewController to(String fileId) {
    DocLinkPreviewController c;
    if (Get.isRegistered<DocLinkPreviewController>(tag: fileId)) {
      c = Get.find<DocLinkPreviewController>(tag: fileId);
    } else {
      c = Get.put(DocLinkPreviewController(fileId), tag: fileId);
    }
    return c;
  }

  DocLinkPreviewController(this.fileId);

  @override
  void onInit() {
    super.onInit();
    onLoading();
  }

  void onLoading() {
    _reqData(fileId);
  }

  Future<void> _reqData(String fileId) async {
    if (docInfoItem != null ||
        loadingStatus == LoadingStatus.loading ||
        fileId.noValue) return;

    loadingStatus = LoadingStatus.loading;
    final DocInfoItem res =
        await DocumentApi.docInfo(fileId, checkPermission: true);
    if (res != null) {
      docInfoItem = res;
      addTag(res.guildId ?? '0', fileId);

      loadingStatus = LoadingStatus.complete;
      update();
      return;
    }

    loadingStatus = LoadingStatus.error;
    update();
  }

  Future<String> getTitle() async {
    String replacement;

    int count = 0;
    while (loadingStatus == LoadingStatus.loading) {
      await Future.delayed(const Duration(milliseconds: 500));
      count++;

      ///等待5次
      if (count > 5) {
        break;
      }
    }

    if (docInfoItem == null) {
      loadingStatus = LoadingStatus.loading;
      docInfoItem = await DocumentApi.docInfo(fileId, checkPermission: true);
      if (docInfoItem != null) {
        loadingStatus = LoadingStatus.complete;
      } else {
        loadingStatus = LoadingStatus.error;
      }
    }

    if (docInfoItem != null) {
      replacement = ' [在线文档] ${docInfoItem.title} ';
    } else {
      ///异常处理
      replacement = ' [在线文档]  ';
    }

    return replacement;
  }

  Widget buildDocTitle(String url, {TextStyle textStyle}) {
    if (docInfoItem == null) {
      return Text(
        url,
        textScaleFactor: 1,
        style:
            textStyle ?? TextStyle(color: Get.theme.primaryColor, fontSize: 17),
      );
    }

    ///文档是否被删除
    final bool isDel = docInfoItem.fileId == null;

    final _light = TextStyle(fontSize: 17, color: Get.theme.primaryColor);
    final _gray = TextStyle(fontSize: 17, color: Get.theme.disabledColor);
    final _normal =
        TextStyle(fontSize: 17, color: Get.textTheme.bodyText2.color);

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  IconFont.buffDocument,
                  size: 16,
                  color:
                      isDel ? Get.theme.disabledColor : Get.theme.primaryColor,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          TextSpan(text: docInfoItem.getTitle(), style: isDel ? _gray : _light),
        ],
      ),
      textAlign: TextAlign.left,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: _normal,
      softWrap: true,
    );
  }
}
