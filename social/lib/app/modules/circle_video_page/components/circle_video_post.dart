import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/models/circle_post_data_model.dart';
import 'package:im/app/modules/circle/models/circle_post_info_data_model.dart';
import 'package:im/app/modules/circle/util.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_detail_article_topic.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_detail_widgets.dart';
import 'package:im/app/modules/circle_video_page/components/circle_video_rich_text.dart';
import 'package:im/app/modules/circle_video_page/controllers/circle_video_page_controller.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/tc_doc_utils.dart';
import 'package:im/widgets/realtime_user_info.dart';

class CircleVideoPost extends StatefulWidget {
  const CircleVideoPost({this.model, this.showAll, key}) : super(key: key);
  final CirclePostDataModel model;
  final bool showAll;

  @override
  State<CircleVideoPost> createState() => _CircleVideoPostState();
}

class _CircleVideoPostState extends State<CircleVideoPost> {
  final ValueNotifier<int> richTextLines = ValueNotifier(0);

  CirclePostInfoDataModel get postInfoDataModel =>
      widget.model.postInfoDataModel;

  String get content => CircleUtil.parsePost(postInfoDataModel);

  List<String> get atList => widget.model.atUserIdList;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CircleVideoPageController>(
      builder: (controller) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _docWidget(widget.model?.docItem),
            const SizedBox(height: 12),
            _userInfo(),
            const SizedBox(height: 12),
            if (postInfoDataModel.title.hasValue) _title(),
            //有标题且有(正文/提醒谁看)需要展示间距4pt
            if (postInfoDataModel.title.hasValue &&
                (content.hasValue || atList != null))
              const SizedBox(height: 4),
            _content(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Row _userInfo() {
    return Row(
      children: [
        RealtimeAvatar(
          userId: widget.model.userDataModel.userId,
          guildId: postInfoDataModel.guildId,
          size: 28,
          tapToShowUserInfo: true,
        ),
        sizeWidth8,
        AbsorbPointer(
          child: RealtimeNickname(
            guildId: postInfoDataModel.guildId,
            userId: widget.model.userDataModel.userId,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _title() {
    return Text(
      postInfoDataModel.title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _content() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.ease,
      child: Column(
        children: [
          ClipRect(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: Get.size.height * .57),
              child: ListView(
                padding: EdgeInsets.zero,
                physics: widget.showAll
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: [
                  if (content.hasValue)
                    CircleVideoRichText(
                      content: content,
                      guildId: postInfoDataModel.guildId,
                      showAll: widget.showAll,
                      richTextLayoutLinesCallback: (lines) =>
                          richTextLines.value = lines,
                    ),
                  //有正文且有艾特列表并在展开的时候需要间距14pt
                  if (widget.showAll && content.hasValue && atList != null)
                    const SizedBox(height: 14),
                  ValueListenableBuilder<int>(
                    valueListenable: richTextLines,
                    builder: (context, value, child) {
                      //有艾特列表且展开正文时显示，或有艾特列表但正文折叠后少于2行时显示
                      if (atList != null && (value < 2 || widget.showAll))
                        return AtUserListView(
                          widget.model.atUserIdList,
                          plainTextStyle: true,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        );
                      else
                        return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
          ),
          if (widget.showAll)
            ...() {
              return [
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleDetailTime(
                      createdAt:
                          int.tryParse(postInfoDataModel?.createdAt ?? "0"),
                      updatedAt: int.tryParse(postInfoDataModel?.updatedAt ??
                          postInfoDataModel?.createdAt ??
                          '0'),
                      textStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '收起'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(.8),
                        fontWeight: FontWeight.w400,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(.5),
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ];
            }()
        ],
      ),
    );
  }

  /// * 腾讯文档
  Widget _docWidget(DocItem docItem) {
    if (docItem == null) return sizedBox;
    final child = Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      decoration: BoxDecoration(
        color: appThemeData.textTheme.bodyText1.color.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      height: 28,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          sizeWidth2,
          const Icon(IconFont.buffDocument, size: 14, color: Colors.white),
          sizeWidth3,
          Text(
            _docTypeDesc(docItem.type),
            style: TextStyle(
              color: appThemeData.backgroundColor,
              fontSize: 12,
            ),
          ),
          sizeWidth6,
          VerticalDivider(
            width: 0.5,
            thickness: 0.5,
            indent: 4,
            endIndent: 4,
            color: appThemeData.backgroundColor.withOpacity(.4),
          ),
          sizeWidth6,
          Flexible(
            child: Text(
              docItem.fileId.hasValue ? docItem.title ?? '' : '文档已被删除'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: appThemeData.backgroundColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );

    if (docItem.fileId.hasValue)
      return GestureDetector(
        onTap: () {
          TcDocUtils.toDocPage(docItem.url);
        },
        child: child,
      );
    else
      return child;
  }

  /// * 文档类型描述
  String _docTypeDesc(DocType value) {
    String name;
    switch (value) {
      case DocType.doc:
        name = '文档';
        break;
      case DocType.sheet:
        name = '表格';
        break;
      case DocType.form:
        name = '收集表';
        break;
      case DocType.slide:
        name = '幻灯片';
        break;
      case DocType.mind:
        name = '思维导图';
        break;
      case DocType.flowchart:
        name = '流程图';
        break;
      default:
        name = '文档';
        break;
    }
    return name;
  }
}

class CircleVideoSpecialText extends SpecialTextSpanBuilder {
  CircleVideoSpecialText(this.guildId);

  final String guildId;

  @override
  SpecialText createSpecialText(String flag,
      {TextStyle textStyle, SpecialTextGestureTapCallback onTap, int index}) {
    if (flag == '') {
      return null;
    }
    if (isStart(flag, CircleVideoAtText.flag)) {
      return CircleVideoAtText(guildId);
    }
    return null;
  }
}

class CircleVideoAtText extends SpecialText {
  CircleVideoAtText(this.guildId) : super(flag, '}', const TextStyle());
  static const String flag = r'$';
  final String guildId;

  @override
  InlineSpan finishText() {
    final String atText = toString();
    final String userId = TextEntity.atPattern.firstMatch(atText)?.group(2);
    if (userId != null)
      return WidgetSpan(
        child: Padding(
          padding: const EdgeInsets.only(left: 2, right: 2),
          child: RealtimeNickname(
            guildId: guildId,
            prefix: '@',
            userId: userId,
            tapToShowUserInfo: true,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      );
    else
      return TextSpan(text: atText);
  }
}
