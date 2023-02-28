import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_api.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/doc_info_item.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/modules/document_online/info/controllers/doc_link_preview_controller.dart';
import 'package:im/app/modules/tc_doc_add_group_page/entities/tc_doc_group.dart';
import 'package:im/app/modules/tc_doc_page/controllers/tc_doc_page_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/json/document_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/utils/tc_doc_utils.dart';
import 'package:oktoast/oktoast.dart';
import 'package:tuple/tuple.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../../icon_font.dart';
import '../../../../../loggers.dart';
import '../../../../../svg_icons.dart';

class DocumentItem extends StatelessWidget {
  final DocumentEntity entity;
  final MessageEntity message;

  const DocumentItem({Key key, this.entity, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeButton(
      width: 280,
      alignment: Alignment.centerLeft,
      onTap: () {
        _openDocument();
      },
      child: _buildDocument(),
    );
  }

  Widget _buildDocument() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Get.theme.scaffoldBackgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDocType(),
          const SizedBox(height: 12),
          _docInfo(),
        ],
      ),
    );
  }

  ///是否可以编辑，true可以编辑，false可以阅读
  Future<bool> getStatus() async {
    final DocInfoItem res = await DocumentApi.docInfo(entity.fileId);
    return res.role == TcDocGroupRole.edit;
  }

  Widget _buildDocType() {
    final _light = TextStyle(fontSize: 17, color: Get.theme.primaryColor);
    final _gray = TextStyle(fontSize: 17, color: Get.theme.disabledColor);
    final _normal =
        TextStyle(fontSize: 17, color: Get.textTheme.bodyText2.color);

    return GetBuilder<DocLinkPreviewController>(
        init: DocLinkPreviewController(entity.fileId),
        tag: entity.fileId,
        autoRemove: false,
        builder: (c) {
          ///文档是否被删除
          final bool isDel =
              c.docInfoItem != null && c.docInfoItem.fileId == null;

          return Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: getSendName(), style: _light),
                TextSpan(text: getSendType(), style: _normal),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 4),
                      Icon(
                        IconFont.buffDocument,
                        size: 16,
                        color: isDel
                            ? Get.theme.disabledColor
                            : Get.theme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                TextSpan(
                    text: entity.documentTitle, style: isDel ? _gray : _light),
                if (entity.sendType == SendType.at)
                  TextSpan(text: '@了你'.tr, style: _normal),
              ],
            ),
            textAlign: TextAlign.left,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: _normal,
            softWrap: true,
          );
        });
  }

  Widget _docInfo() {
    return GetBuilder<DocLinkPreviewController>(
      init: DocLinkPreviewController(entity.fileId),
      tag: entity.fileId,
      autoRemove: false,
      builder: (c) {
        ///文档是否被删除
        final bool isDel =
            c.docInfoItem != null && c.docInfoItem.fileId == null;
        double height = 64;
        if (!isDel) {
          height = height + 0.5 + 32;
        }
        return Container(
          height: height,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ..._docIcon(isDel),
                      Flexible(
                        child: Text(
                          _getDocumentTitle(c, entity),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.25,
                            color: isDel
                                ? Get.theme.disabledColor
                                : Get.textTheme.headline1.color.withOpacity(1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isDel)
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Divider(),
                ),
              if (!isDel) _docStatus(isDel, c.docInfoItem),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _docIcon(bool isDel) {
    if (isDel) {
      return [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: appThemeData.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(4)),
          child: Icon(IconFont.buffDocDel,
              color: Get.theme.disabledColor, size: 20),
        ),
        const SizedBox(width: 8),
      ];
    }
    return [
      getDocumentIcon(
        entity.documentType,
        width: 32,
        height: 32,
      ),
      const SizedBox(width: 8),
    ];
  }

  Widget _docStatus(bool isDel, DocInfoItem item) {
    if (isDel || item == null) {
      return const SizedBox();
    }
    return SizedBox(
      height: 32,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: item.docStatus(),
        ),
      ),
    );
  }

  String _getDocumentTitle(DocLinkPreviewController c, DocumentEntity entity) {
    if (c.docInfoItem != null) {
      if (c.docInfoItem.fileId == null) {
        ///文档被删除
        return c.docInfoItem.getTitle();
      }
    }
    return entity.documentTitle;
  }

  Future<void> _openDocument() async {
    try {
      final DocLinkPreviewController c = Get.find(tag: entity.fileId);

      if (c.docInfoItem != null && c.docInfoItem.fileId == null) {
        showToast('文档已被删除'.tr);
        return;
      }
    } catch (e) {
      logger.warning(e.toString());
    }

    final docList = await TcDocUtils.toDocPage(entity.url);
    if (docList is List<Tuple2<TcDocPageReturnType, DocInfoItem>>) {
      if (docList == null || docList.isEmpty) return;

      docList.forEach((res) {
        final TcDocPageReturnType type = res.item1;
        final DocItem item = DocItem.fromInfo(res.item2);

        switch (type) {
          case TcDocPageReturnType.update:
            updateData(entity, item);
            break;
          default:
            break;
        }
      });
    }
  }

  ///dest目标，src源
  void updateData(DocumentEntity dest, DocItem src) {
    if (dest == null || src == null) return;

    if (src.title.hasValue && src.title != dest.documentTitle) {
      dest.documentTitle = src.title;
      InMemoryDb.updateMessageId(BigInt.parse(message.messageId), message);

      unawaited(
          InMemoryDb.getMessageList(message.channelId).saveMessage(message));

      TextChannelController.to(channelId: message.channelId).update();
    }
  }

  String getSendName() {
    final String userId = entity.sendUserId;
    final String guildId = message.guildId;

    bool isDm = false; //是否为私信
    if (guildId == null || guildId.isEmpty || guildId == '0') {
      isDm = true;
    }
    final userInfo = Db.userInfoBox.get(userId);
    final String nickName =
        userInfo?.showName(guildId: guildId, hideGuildNickname: isDm);

    if (nickName.noValue) {
      return '';
    }
    return '@$nickName ';
  }

  String getSendType() {
    String type;
    switch (entity.sendType) {
      case SendType.at:
        type = '在'.tr;
        break;
      case SendType.invite:
        type = '邀请你编辑'.tr;
        break;
      default:
        type = '在'.tr;
        break;
    }

    return type;
  }

  static Widget getDocumentIcon(DocType type,
      {double width = 40, double height = 40}) {
    Widget icon;
    switch (type) {
      case DocType.doc: //在线文档，默认值
        icon = WebsafeSvg.asset(SvgIcons.doc, width: width, height: height);
        break;
      case DocType.sheet: //在线表格
        icon = WebsafeSvg.asset(SvgIcons.sheet, width: width, height: height);
        break;
      case DocType.form: //在线收集表
        icon = WebsafeSvg.asset(SvgIcons.form, width: width, height: height);
        break;
      case DocType.slide: //在线幻灯片
        icon = WebsafeSvg.asset(SvgIcons.slide, width: width, height: height);
        break;
      case DocType.mind: //在线思维导图
        icon = WebsafeSvg.asset(SvgIcons.mind, width: width, height: height);
        break;
      case DocType.flowchart: //在线流程图
        icon =
            WebsafeSvg.asset(SvgIcons.flowchart, width: width, height: height);
        break;
      default:
        icon = WebsafeSvg.asset(SvgIcons.doc, width: width, height: height);
        break;
    }

    return icon;
  }
}
