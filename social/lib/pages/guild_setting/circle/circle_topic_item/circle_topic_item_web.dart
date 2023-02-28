import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill/flutter_quill.dart' as fq;
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/like_button.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_widget.dart';
import 'package:im/pages/guild_setting/circle/component/all_like_grid.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/round_image.dart';
import 'package:im/widgets/topic_tag_text.dart';
import 'package:im/widgets/video_play_button.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

import '../circle_detail_page/menu_button/menu_button.dart';
import '../component/circle_user_info_row.dart';

class CircleTopicItem extends StatefulWidget {
  final CirclePostDataModel circlePostDataModel;
  final Function() onRefreshCallBack;
  final Function(CirclePostDataModel model) onItemDeleteCallBack;
  final Function(List topicIds) onItemModifyCallBack;

  ///圈子搜索的关键词
  final String searchKey;

  const CircleTopicItem(
    this.circlePostDataModel, {
    Key key,
    this.onItemDeleteCallBack,
    this.onRefreshCallBack,
    this.onItemModifyCallBack,
    this.searchKey,
  }) : super(key: key);

  @override
  _CircleTopicItemState createState() => _CircleTopicItemState();
}

class _CircleTopicItemState extends State<CircleTopicItem> {
  ThemeData _theme;
  static const int _maxLikeAvatar = 5;
  List<Operation> _operationList;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    final postInfoDataModel = widget.circlePostDataModel.postInfoDataModel;
    final userInfoDataModel = widget.circlePostDataModel.userDataModel;
    final subInfoDataModel = widget.circlePostDataModel.postSubInfoDataModel;
    Document document;
    try {
      final contentJson = List<Map<String, dynamic>>.from(jsonDecode(
          postInfoDataModel.postContent() ??
              RichEditorUtils.defaultDoc.encode()));

      RichEditorUtils.transformAToLink(contentJson);
      document = Document.fromJson(contentJson);
    } catch (e) {
      document = RichEditorUtils.defaultDoc;
      logger.severe('圈子格式错误:$e');
    }

    _operationList = _operationList =
        RichEditorUtils.formatDelta(document.toDelta()).toList();

    int imageCount = 0;

    fq.Operation media;

    for (final item in _operationList) {
      if (item.isMedia) {
        media ??= item;
        imageCount++;
      }
    }

    final stringBuffer = StringBuffer();
    for (final e in _operationList) {
      if (e.isMedia) break;
      if (e.key == fq.Operation.insertKey && e.value is Map) {
        final embed = fq.Embeddable.fromJson(e.value);
        if (embed.data is Map && embed.data['value'] is String) {
          stringBuffer.write(embed.data['value']);
        }
      } else {
        if (e.data is String) {
          stringBuffer.write(e.data);
        }
      }
    }

    final title = postInfoDataModel.title;

    const leadingSpace = 16.0;
    const totalMaxLines = 5;
    int contentMaxLines = 5;
    final textStyle = Theme.of(context).textTheme.bodyText2.copyWith(
        height: 1.25,
        fontSize: OrientationUtil.portrait ? 16 : 14,
        color: Colors.black);
    if (title.isEmpty) {
      contentMaxLines = totalMaxLines;
    } else {
      final width = MediaQuery.of(context).size.width;
      final paint = calculateTextHeight(
          context,
          title,
          textStyle.copyWith(fontWeight: FontWeight.bold),
          width - leadingSpace * 2,
          totalMaxLines);
      int lineCount = 0;
      try {
        lineCount = paint.computeLineMetrics().length;
      } catch (e) {
        lineCount = paint.height ~/ paint.preferredLineHeight;
      }
      contentMaxLines = max(totalMaxLines - lineCount, 0);
    }

    final tmpString = stringBuffer
        .toString()
        .trim()
        .replaceAllMapped(RegExp("(\n| )+"), (match) => match.group(1));
    // 由于动态列表页面最多展示5行，而第5行结尾如果是\n ParseText不会展示...，所以手动加上。
    final contents = tmpString.split('\n');
    if (contents.length > contentMaxLines) {
      contents.replaceRange(contentMaxLines - 1, contentMaxLines,
          ['${contents[contentMaxLines - 1]}...']);
    }
    final content = contents.join('\n');

    /// web
    int contentLength = 0;
    if (OrientationUtil.landscape) {
      final paint = calculateTextHeight(context, content, textStyle,
          MediaQuery.of(context).size.width - 310 - 40 * 2, totalMaxLines);
      int lineCount = 0;
      try {
        lineCount = paint.computeLineMetrics().length;
      } catch (e) {
        lineCount = paint.height ~/ paint.preferredLineHeight;
      }
      contentLength = lineCount;
    }

    return Container(
      decoration: BoxDecoration(
        color: _theme.backgroundColor,
        borderRadius: BorderRadius.circular(OrientationUtil.portrait ? 0 : 8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: leadingSpace),
      margin: EdgeInsets.symmetric(
          horizontal:
              OrientationUtil.portrait || widget.searchKey.hasValue ? 0 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: CircleUserInfoRow(
                createdAt: int.parse(postInfoDataModel?.createdAt ?? "0"),
                updatedAt: int.parse(
                    isNotNullAndEmpty(postInfoDataModel.updatedAt)
                        ? postInfoDataModel?.updatedAt ?? "0"
                        : postInfoDataModel?.createdAt ?? "0"),
                userId: userInfoDataModel.userId,
                avatarUrl: userInfoDataModel.avatar,
                nickName: userInfoDataModel.nickName,
              )),
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    if (widget.searchKey.hasValue)
                      Container(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerRight,
                          child: Icon(IconFont.buffChatForward,
                              color: Theme.of(context).disabledColor, size: 20))
                    else
                      ShareButton(
                        data: widget.circlePostDataModel,
                        size: 20,
                        isFromList: true,
                      ),
                    if (widget.searchKey.noValue) ...[
                      sizeWidth16,
                      MenuButton(
                          postData: widget.circlePostDataModel,
                          padding: const EdgeInsets.only(top: 12),
                          iconColor: Theme.of(context).disabledColor,
                          size: 20,
                          onRequestSuccess: (type, {param}) {
                            if (type == MenuButtonType.del) {
                              widget.onItemDeleteCallBack
                                  ?.call(widget.circlePostDataModel);
                            } else if (type == MenuButtonType.modify) {
                              widget.onItemModifyCallBack?.call(param);
                            } else {
                              widget.onRefreshCallBack?.call();
                            }
                          },
                          onRequestError: (code, type) {
                            if (code == postNotFound || code == postNotFound2) {
                              showToast(postNotFoundToast);
                            } else {
                              final errorMes = errorCode2Message["$code"] ??
                                  "错误码 %s".trArgs([code?.toString()]);
                              showToast(errorMes);
                            }
                          })
                    ],
                  ],
                ),
              )
            ],
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (widget.searchKey.hasValue)
              ParsedText(
                text: title,
                style: textStyle?.copyWith(
                        color: const Color(0xff363940),
                        fontWeight: FontWeight.bold,
                        wordSpacing: 0.3) ??
                    const TextStyle(),
                maxLines: totalMaxLines - contentMaxLines,
                overflow: TextOverflow.ellipsis,
                regexOptions: const RegexOptions(caseSensitive: false),
                parse: [
                  if (widget.searchKey != null && widget.searchKey.isNotEmpty)
                    ParsedTextExtension.matchSearchKey(
                        context,
                        widget.searchKey,
                        textStyle.copyWith(color: Get.theme.primaryColor)),
                ],
              )
            else
              Text(
                title,
                style: textStyle.copyWith(fontWeight: FontWeight.bold),
                maxLines: totalMaxLines - contentMaxLines,
                overflow: TextOverflow.ellipsis,
              ),
          ],
          if (content.isNotEmpty) ...[
            if (title.isEmpty) const SizedBox(height: 8),
            if (OrientationUtil.landscape) const SizedBox(height: 8),
            AbsorbPointer(
              absorbing: false,
              child: ParsedText(
                style: textStyle,
                textScaleFactor: MediaQuery.of(context).textScaleFactor,
                text: '$content$nullChar',
                maxLines: 5,
                overflow: OrientationUtil.landscape
                    ? TextOverflow.clip
                    : TextOverflow.ellipsis,
                regexOptions: const RegexOptions(caseSensitive: false),
                parse: [
                  ParsedTextExtension.matchCusEmoText(context, textStyle.fontSize),
                  ParsedTextExtension.matchURLText(context),
                  ParsedTextExtension.matchChannelLink(context),
                  ParsedTextExtension.matchAtText(
                    context,
                    textStyle: textStyle?.copyWith(fontSize: 15),
                  ),
                  if (widget.searchKey.hasValue)
                    ParsedTextExtension.matchSearchKey(
                        context,
                        widget.searchKey,
                        textStyle.copyWith(color: Get.theme.primaryColor)),
                ],
              ),
            ),
          ],
          if (contentLength > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '全文'.tr,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(color: const Color(0xFF576B95)),
              ),
            ),
          if (media != null) ...[
            const SizedBox(height: 8),
            _buildMediaItem(media, totalImage: imageCount)
          ],
          if (postInfoDataModel.topicName != null &&
              postInfoDataModel.topicName.isNotEmpty) ...[
            const SizedBox(height: 8),
            TopicTagText([postInfoDataModel.topicName])
          ],
          _buildLikeAvatar(postInfoDataModel.postId, subInfoDataModel),
        ],
      ),
    );
  }

  Widget _buildMediaItem(Operation o, {int totalImage = 0}) {
    Widget child;
    if (o.isImage) {
      final url = RichEditorUtils.getEmbedAttribute(o, 'source');
      child = Container(
          foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: CustomColor(context).backgroundColor1,
                width: 0.5,
              )),
          child: Stack(
            alignment: AlignmentDirectional.bottomEnd,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: RoundImage(
                  url: url,
                  radius: 4,
                  placeholder: (context, url) =>
                      const Center(child: CupertinoActivityIndicator()),
                ),
              ),
              Visibility(
                  visible: totalImage > 1,
                  child: Container(
                    height: 155,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.15)
                            ])),
                  )),
              Visibility(
                visible: totalImage > 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: Icon(IconFont.buffCircleMoreImage,
                            color: Colors.white, size: 12),
                      ),
                      sizeWidth4,
                      Text(
                        '$totalImage',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12, height: 1),
                      )
                    ],
                  ),
                ),
              )
            ],
          ));
    } else if (o.isVideo) {
      final thumbUrl = RichEditorUtils.getEmbedAttribute(o, 'thumbUrl');
      final duration = RichEditorUtils.getEmbedAttribute(o, 'duration');

      child = Container(
        foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: CustomColor(context).backgroundColor1,
              width: 0.5,
            )),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoWidget(
            borderRadius: 4,
            backgroundColor: const Color.fromARGB(255, 0xf0, 0xf1, 0xf2),
            duration: duration,
            child: RoundImage(
              url: thumbUrl,
              placeholder: (context, url) =>
                  const Center(child: CupertinoActivityIndicator()),
            ),
          ),
        ),
      );
    }
    if (child == null) return const SizedBox();
    if (OrientationUtil.portrait)
      return child;
    else
      return ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 320,
          maxHeight: 180,
        ),
        child: child,
      );
  }

  Widget _buildLikeAvatar(
      String postId, CirclePostSubInfoDataModel subInfoDataModel) {
    final List<Widget> widgetList = [];
    for (var i = 0;
        i < min(_maxLikeAvatar, subInfoDataModel.likeListCount());
        i++) {
      widgetList.add(Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: CustomColor(context).backgroundColor8, width: 2),
            color: CustomColor(context).backgroundColor8,
          ),
          child: RealtimeAvatar(
              size: 24,
              userId: subInfoDataModel.likeDetailDataModelAtIndex(i).userId)));
    }

    final int displayNum = widgetList.length;
    final List<Widget> _list = [];
    for (var i = 0; i < displayNum; i++) {
      _list.add(Positioned(
        left: i * 24.0,
        child: widgetList[i],
      ));
    }

    return Container(
      alignment: Alignment.center,
      height: 48,
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onLongPress: () {
                showBottomModal(context,
                    backgroundColor: Theme.of(context).backgroundColor,
                    builder: (c, s) =>
                        AllLikeGrid(postId, subInfoDataModel.likeTotal));
              },
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child:
                        Stack(alignment: Alignment.centerLeft, children: _list),
                  ),
                ],
              ),
            ),
          ),
          if (widget.searchKey.hasValue)
            LikeButton(
              padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
              isLike: subInfoDataModel.iLiked == '1',
              count: subInfoDataModel.totalLikeNum,
              fontWeight: FontWeight.w500,
            )
          else
            ValidPermission(
                channelId: widget.circlePostDataModel.postInfoDataModel.topicId,
                permissions: [Permission.CIRCLE_ADD_REACTION],
                builder: (hasPermission, isOwner) {
                  return AnimatedLikeButton(
                    padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                    isLike: subInfoDataModel.iLiked == '1',
                    count: subInfoDataModel.totalLikeNum,
                    unLikeColor: Theme.of(context).disabledColor,
                    fontWeight: FontWeight.w500,
                    onTap: (liked) async {
                      // 先判断是否有权限进行点赞
                      if (!hasPermission && !isOwner) {
                        showToast('你没有此动态的点赞权限'.tr);
                        return false;
                      }

                      final postInfoDataModel =
                          widget.circlePostDataModel.postInfoDataModel;
                      try {
                        if (subInfoDataModel.iLiked == '1') {
                          await CircleApi.circleDelReaction(
                              postInfoDataModel.channelId,
                              postInfoDataModel.postId,
                              postInfoDataModel.topicId,
                              'post',
                              subInfoDataModel.likeId,
                              '');
                          widget.circlePostDataModel
                              .modifyLikedState('0', '', postId: postId);
                          setState(() {});
                        } else {
                          final result = await CircleApi.circleAddReaction(
                              postInfoDataModel.channelId,
                              postInfoDataModel.postId,
                              postInfoDataModel.topicId,
                              'post',
                              '');
                          if (result.containsKey('id')) {
                            widget.circlePostDataModel.modifyLikedState(
                                '1', result['id'],
                                postId: postId);
                            unawaited(Future.delayed(kThemeAnimationDuration)
                                .then((value) {
                              setState(() {});
                            }));
                          }
                          await HapticFeedback.lightImpact();
                        }
                      } catch (e) {
                        if (e is RequestArgumentError) {
                          if (e.code == postNotFound ||
                              e.code == postNotFound2) {
                            showToast(postNotFoundToast);
                          } else if (e.code == commentNotFound) {
                            showToast(postNotFoundToast);
                          }
                        }
                      }
                      return subInfoDataModel.iLiked == '1';
                    },
                  );
                }),
          IconButton(
              padding: const EdgeInsets.all(0),
              alignment: Alignment.centerRight,
              icon: Icon(IconFont.buffCircleReply,
                  color: _theme.disabledColor, size: 24),
              onPressed: null),
          if (int.tryParse(subInfoDataModel.commentTotal) > 0)
            const SizedBox(width: 2),
          if (int.tryParse(subInfoDataModel.commentTotal) > 0)
            Text(subInfoDataModel.commentTotal,
                style: _theme.textTheme.bodyText2.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _theme.disabledColor)),
          if (OrientationUtil.portrait)
            ShareButton(data: widget.circlePostDataModel, isFromList: true)
        ],
      ),
    );
  }

  ///动态不存在时的处理
// void _onRequestError(Exception e, BuildContext context,
//     {bool deletePost = false}) {
//   bool needRefresh = false;
//   if (e is RequestArgumentError) {
//     if (deletePost && (e.code == postNotFound || e.code == postNotFound2)) {
//       needRefresh = true;
//     } else if (!deletePost && e.code == commentNotFound) {
//       needRefresh = false;
//     } else if (!deletePost &&
//         (e.code == postNotFound || e.code == postNotFound2)) {
//       needRefresh = true;
//     }
//   } else {
//     if (mounted) {
//       showToast('网络异常，请检查后重试'.tr);
//     }
//     needRefresh = false;
//   }
//   if (needRefresh)
//     Future.delayed(const Duration(seconds: 1), () {
//       widget.onItemDeleteCallBack(widget.circlePostDataModel);
//     });
// }
}
