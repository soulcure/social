import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/controllers/circle_topic_controller.dart';
import 'package:im/app/modules/circle/models/circle_share_poster_model.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/modules/circle_detail/circle_detail_router.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_video_page/controllers/circle_video_page_controller.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/circle_page.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/like_button.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/menu_button/menu_button.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_widget.dart';
import 'package:im/pages/guild_setting/circle/component/all_like_grid.dart';
import 'package:im/pages/guild_setting/circle/component/circle_user_info_row.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/pages/home/view/gallery/model/gallery_item.dart';
import 'package:im/pages/home/view/gallery/photo_view.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/cos_file_cache_index.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/topic_tag_text.dart';
import 'package:oktoast/oktoast.dart';
import 'package:websafe_svg/websafe_svg.dart';

class CircleTopicItem extends StatefulWidget {
  final CirclePostDataModel circlePostDataModel;
  final Function() onRefreshCallBack;
  final Function(CirclePostDataModel model) onItemDeleteCallBack;
  final Function(List topicIds) onItemModifyCallBack;

  ///圈子搜索的关键词
  final String searchKey;

  /// 用于详情分享海报，需要的数据
  final CircleDetailData circleDetailData;

  final List<CirclePostDataModel> circlePostDateModels;

  final String circleTopicId;

  const CircleTopicItem(
    this.circlePostDataModel, {
    Key key,
    this.onItemDeleteCallBack,
    this.onRefreshCallBack,
    this.onItemModifyCallBack,
    this.searchKey,
    this.circleDetailData,
    this.circlePostDateModels,
    this.circleTopicId,
  }) : super(key: key);

  @override
  _CircleTopicItemState createState() => _CircleTopicItemState();
}

class _CircleTopicItemState extends State<CircleTopicItem> {
  ThemeData _theme;
  List<Operation> _operationList;
  CirclePostInfoDataModel _postInfoDataModel;
  CirclePostUserDataModel _userInfoDataModel;
  CirclePostSubInfoDataModel _subInfoDataModel;
  Operation _media;
  final double _leadingSpace = 16;
  String _title;
  String _content;
  TextStyle _textStyle;
  int _contentMaxLines = 5;
  final int _totalMaxLines = 5;
  int _imageCount = 0;

  // bool _showPlay = true;
  final ValueNotifier<bool> _showPlay = ValueNotifier(true);

  @override
  void initState() {
    _initData();

    super.initState();
  }

  @override
  void didUpdateWidget(covariant CircleTopicItem oldWidget) {
    if (_postInfoDataModel != widget.circlePostDataModel?.postInfoDataModel) {
      _postInfoDataModel = widget.circlePostDataModel?.postInfoDataModel;
      _initData();
    }
    _userInfoDataModel = widget.circlePostDataModel?.userDataModel;
    _subInfoDataModel = widget.circlePostDataModel?.postSubInfoDataModel;
    super.didUpdateWidget(oldWidget);
  }

  void _initData() {
    Document document;
    try {
      _imageCount = 0;
      List<Map<String, dynamic>> contentJson = [];
      final content =
          widget.circlePostDataModel?.postInfoDataModel?.postContent2() ??
              RichEditorUtils.defaultDoc.encode();
      contentJson = List<Map<String, dynamic>>.from(jsonDecode(content));
      RichEditorUtils.transformAToLink(contentJson);
      document = Document.fromJson(contentJson);
    } catch (e, s) {
      document = RichEditorUtils.defaultDoc;
      logger.severe('圈子格式错误', e, s);
    }
    _operationList = _operationList =
        RichEditorUtils.formatDelta(document.toDelta()).toList();
    // _media = _operationList.firstWhere(
    //   (o) => o.isMedia,
    //   orElse: () => null,
    // );
    _postInfoDataModel = widget.circlePostDataModel?.postInfoDataModel;
    _userInfoDataModel = widget.circlePostDataModel?.userDataModel;
    _subInfoDataModel = widget.circlePostDataModel?.postSubInfoDataModel;

    for (final item in _operationList) {
      if (item.isMedia) {
        _media ??= item;
        _imageCount++;
      }
    }

    final stringBuffer = StringBuffer();
    for (final e in _operationList) {
      if (e.isMedia) break;
      if (e.key == Operation.insertKey && e.value is Map) {
        final embed = Embeddable.fromJson(e.value);
        if (embed.data is Map && embed.data['value'] is String) {
          stringBuffer.write(embed.data['value']);
        }
      } else {
        if (e.data is String) {
          stringBuffer.write(e.data);
        }
      }
    }
    _title = _postInfoDataModel?.title ?? "";
    final context = Global.navigatorKey.currentContext;
    _textStyle = Theme.of(context)
        .textTheme
        .bodyText2
        .copyWith(height: 1.5, fontSize: 16, color: Colors.black);
    if (_title?.isEmpty ?? true) {
      _contentMaxLines = _totalMaxLines;
    } else {
      final width = MediaQuery.of(context).size.width;
      final paint = calculateTextHeight(
          context,
          _title,
          _textStyle?.copyWith(fontWeight: FontWeight.bold) ??
              const TextStyle(),
          width - _leadingSpace * 2,
          _totalMaxLines);
      int lineCount = 0;
      try {
        lineCount = paint.computeLineMetrics().length;
      } catch (e) {
        lineCount = paint.height ~/ paint.preferredLineHeight;
      }
      _contentMaxLines = max(_totalMaxLines - lineCount, 1);
    }

    final tmpString = stringBuffer
        .toString()
        .trim()
        .replaceAllMapped(RegExp("(\n| )+"), (match) => match.group(1));
    // 由于动态列表页面最多展示5行，而第5行结尾如果是\n ParseText不会展示...，所以手动加上。
    final contents = tmpString.split('\n');
    if (contents.length > _contentMaxLines && _contentMaxLines > 0) {
      contents.replaceRange(_contentMaxLines - 1, _contentMaxLines,
          ['${contents[_contentMaxLines - 1]}...']);
    }
    _content = _postInfoDataModel.postTypeAvailable
        ? contents.join('\n')
        : '当前版本暂不支持查看此信息类型'.tr;
  }

  ///是否圈子搜索列表item
  bool isSearchItem() {
    return widget.searchKey != null && widget.searchKey.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    _textStyle ??= Theme.of(context)
        .textTheme
        .bodyText2
        .copyWith(height: 1.5, fontSize: 16, color: Colors.black);
    return normalList();
  }

  Widget plainText(
      {int maxLine,
      double fontSize = 15.0,
      double height,
      EdgeInsets insets = EdgeInsets.zero}) {
    return _postInfoDataModel.postTypeAvailable
        ? Container(
            padding: insets,
            child: ParsedText(
              style: _textStyle?.copyWith(
                  fontSize: fontSize,
                  color: const Color(0xff363940),
                  height: height ?? 1.5),
              text: '$_content$nullChar',
              maxLines: maxLine ?? _contentMaxLines,
              overflow: TextOverflow.ellipsis,
              regexOptions: const RegexOptions(caseSensitive: false),
              parse: [
                ParsedTextExtension.matchCusEmoText(context, fontSize),
                ParsedTextExtension.matchURLText(context,
                    refererChannelSource: RefererChannelSource.CircleLink),
                ParsedTextExtension.matchChannelLink(context),
                ParsedTextExtension.matchAtText(
                  context,
                  textStyle: _textStyle?.copyWith(
                      fontSize: fontSize ?? 15, height: 1.25),
                  guildId: _postInfoDataModel.guildId,
                ),
                if (isSearchItem())
                  ParsedTextExtension.matchSearchKey(context, widget.searchKey,
                      _textStyle.copyWith(color: Get.theme.primaryColor)),
              ],
            ),
          )
        : Container(
            height: 70,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                color: Color(0xFFF5F5F8)),
            child: Text(
              '当前版本暂不支持查看此信息类型\n请更新至最新版查看'.tr,
              style: Theme.of(context).textTheme.bodyText1.copyWith(
                  fontSize: 14, height: 1.35, color: const Color(0xFF646A73)),
              textAlign: TextAlign.center,
            ),
          );
  }

  Widget imageWidget(
      {@required String url,
      @required double width,
      @required double height,
      @required ProgressIndicatorBuilder progressIndicatorBuilder}) {
    return ContainerImage(
      url,
      width: width,
      height: height,
      thumbWidth: _thumbWidth,
      fit: BoxFit.cover,
      progressIndicatorBuilder: progressIndicatorBuilder,
      cacheManager: CircleCachedManager.instance,
    );
  }

  void mediaOnTap({@required String fileType, @required Map data}) {
    if (fileType == 'video') {
      Get.toNamed(
        app_pages.Routes.CIRCLE_VIDEO_PAGE,
        arguments: CircleVideoPageControllerParam(
          model: widget.circlePostDataModel,
          circlePostDateModels: widget.circlePostDateModels,
          topicId: widget.circleTopicId,
        ),
      );
    } else if (fileType == 'image') {
      showImageDialog(
        Get.context,
        items: _postInfoDataModel.mediaList.map((e) {
          final String url = e['source'];
          return GalleryItem(
            url: url,
            filePath: CosUploadFileIndexCache.cachePath(url),
            id: 'tag: $e',
            holderUrl: ContainerImage.getThumbUrl(url, thumbWidth: _thumbWidth),
          );
        }).toList(),
        index: max(
            _postInfoDataModel.mediaList
                .indexWhere((v) => v['source'] == data['source']),
            0),
        showIndicator: true,
      );
    }
  }

  int get _thumbWidth => min(_postInfoDataModel.mediaList.length, 3) > 1
      ? (Get.width / 3 * 2).toInt()
      : (Get.width * 2).toInt();

  Widget videoPlayIconWidget() {
    return Container(
      alignment: AlignmentDirectional.center,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.15),
              blurRadius: 20,
            ),
          ],
        ),
        child: WebsafeSvg.asset(
          SvgIcons.circleVideoPlay,
          width: 40,
          height: 40,
        ),
      ),
    );
  }

  Widget videoDurationWidget(int duration) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: Text(
        timeFormatted(duration),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget imageRemainingWidget(int remaining) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: Text(
        '+$remaining',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget imageItemWidget(
      {@required Map data,
      @required int curIndex,
      @required BorderRadius radius}) {
    final fileType = data['_type'] ?? '';
    final thumbUrl =
        fileType == 'video' ? (data['thumbUrl'] ?? '') : (data['source'] ?? '');
    final int duration = ((data['duration'] ?? 0) as num).toInt();

    final remaining = _postInfoDataModel.mediaList.length - 3;
    //最多显示3个图片
    final maxCount = min(_postInfoDataModel.mediaList.length, 3);

    double itemImageW = 0;
    double itemImageH = 0;
    if (maxCount > 1) {
      itemImageW = (Get.width - _leadingSpace - _leadingSpace - 7) / 3;
      itemImageH = itemImageW;
    } else {
      final double itemW = Get.width - _leadingSpace - _leadingSpace;
      final double singleW = itemW / 16;
      itemImageW = itemW;
      itemImageH = singleW * 9;
    }

    return Container(
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: appThemeData.dividerColor.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: GestureDetector(
          onTap: () {
            mediaOnTap(fileType: fileType, data: data);
          },
          child: SizedBox(
            width: itemImageW,
            height: itemImageH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageWidget(
                  url: thumbUrl,
                  width: itemImageW,
                  height: itemImageH,
                  progressIndicatorBuilder: null,
                ),
                if (fileType == 'video') ...[
                  ValueListenableBuilder(
                    valueListenable: _showPlay,
                    builder: (ctx, value, child) {
                      return Visibility(
                        visible: value,
                        child: videoPlayIconWidget(),
                      );
                    },
                  ),
                  Positioned(
                    right: 6,
                    bottom: 8,
                    child: videoDurationWidget(duration),
                  ),
                ],
                Visibility(
                  visible: remaining > 0 && curIndex >= 2,
                  child: Positioned(
                    bottom: 6,
                    right: 8,
                    child: imageRemainingWidget(remaining),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> gridViewWidget() {
    final List<Widget> items = [];
    //最多显示3个图片
    final maxCount = min(_postInfoDataModel.mediaList.length, 3);
    if (maxCount > 1) {
      for (int i = 0; i < maxCount; i++) {
        final Map data = _postInfoDataModel.mediaList[i];
        Radius topLeft = const Radius.circular(0);
        Radius bottomLeft = const Radius.circular(0);
        Radius topRight = const Radius.circular(0);
        Radius bottomRight = const Radius.circular(0);
        if (i == 0) {
          topLeft = const Radius.circular(5);
          bottomLeft = const Radius.circular(5);
        } else if (i == maxCount - 1) {
          topRight = const Radius.circular(5);
          bottomRight = const Radius.circular(5);
        }

        final Widget item = imageItemWidget(
          data: data,
          curIndex: i,
          radius: BorderRadius.only(
            topLeft: topLeft,
            bottomLeft: bottomLeft,
            topRight: topRight,
            bottomRight: bottomRight,
          ),
        );
        items.add(item);
        if (i < maxCount - 1) {
          items.add(
            const SizedBox(
              width: 3.5,
            ),
          );
        }
      }
    } else if (maxCount > 0) {
      final Map data = _postInfoDataModel.mediaList.first;
      final Widget item = imageItemWidget(
        data: data,
        curIndex: 0,
        radius: BorderRadius.circular(5),
      );
      items.add(item);
    } else {
      items.add(Container());
    }

    return items;
  }

  Widget mediaGridView() {
    final fileType = _postInfoDataModel.postType ?? '';
    if (fileType == 'image' || fileType == 'video') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: gridViewWidget(),
      );
    } else {
      return Container();
    }
  }

  Widget normalList() {
    final String postType = _postInfoDataModel.postType ?? '';
    final bool isDynamic = postType == 'image' || postType == 'video';
    final bool isDisplayMedia =
        (_postInfoDataModel?.mediaList?.isNotEmpty ?? false) ||
            (_imageCount > 0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: _leadingSpace),
      color: _theme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.only(
                    top: 5,
                  ),
                  child: CircleUserInfoRow(
                    createdAt: int.parse(_postInfoDataModel?.createdAt ?? "0"),
                    updatedAt: int.parse(
                        isNotNullAndEmpty(_postInfoDataModel?.updatedAt)
                            ? _postInfoDataModel?.updatedAt ?? "0"
                            : _postInfoDataModel?.createdAt ?? "0"),
                    userId: _userInfoDataModel?.userId ?? "",
                    avatarUrl: _userInfoDataModel?.avatar ?? "",
                    nickName: _userInfoDataModel?.nickName ?? "",
                    avatarAndNameSpace: 8,
                    nameAndTimeSpace: 2,
                  ),
                ),
              ),
              if (!isSearchItem())
                SizedBox(
                  width: 40,
                  height: 44,
                  child: MenuButton(
                      postData: widget.circlePostDataModel,
                      padding: const EdgeInsets.only(top: 12),
                      size: 20,
                      iconColor: const Color(0xff5c6273),
                      //Theme.of(context).disabledColor.withOpacity(0.7),
                      onRequestSuccess: (type, {param}) {
                        if (type == MenuButtonType.del) {
                          widget.onItemDeleteCallBack
                              ?.call(widget.circlePostDataModel);
                        } else if (type == MenuButtonType.modify) {
                          widget.onItemModifyCallBack?.call(param);
                        } else if (type == MenuButtonType.modifyTopic) {
                          //rint('getChat list --- modifyTopic: $param');
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
                      }),
                )
            ],
          ),
          sizeHeight8,
          if (_title?.isNotEmpty ?? false) ...[
            sizeHeight2,
            if (isSearchItem())
              ParsedText(
                text: _title,
                style: _textStyle?.copyWith(
                        color: const Color(0xff363940),
                        fontWeight: FontWeight.bold,
                        wordSpacing: 0.3,
                        height: 1.35) ??
                    const TextStyle(),
                maxLines: _totalMaxLines - _contentMaxLines,
                overflow: TextOverflow.ellipsis,
                regexOptions: const RegexOptions(caseSensitive: false),
                parse: [
                  if (widget.searchKey != null && widget.searchKey.isNotEmpty)
                    ParsedTextExtension.matchSearchKey(
                        context,
                        widget.searchKey,
                        _textStyle.copyWith(color: Get.theme.primaryColor)),
                ],
              )
            else
              Text(
                _title,
                style: _textStyle?.copyWith(
                        color: const Color(0xff363940),
                        fontWeight: FontWeight.bold,
                        height: 1.35,
                        wordSpacing: 0.3) ??
                    const TextStyle(),
                maxLines: _totalMaxLines - _contentMaxLines,
                overflow: TextOverflow.ellipsis,
              ),
            sizeHeight4,
          ],
          if (_content?.isNotEmpty ?? false) ...[
            // if (_title?.isEmpty ?? true) const SizedBox() else sizeHeight3,
            plainText(height: 1.53),
            sizeHeight8,
          ],
          // if (isDisplayMedia) sizeHeight12,
          if (isDisplayMedia) sizeHeight4,
          if (isDynamic)
            mediaGridView()
          else if (_media != null) ...[
            _buildMediaItem(_media, totalImage: _imageCount)
          ],
          if (isDisplayMedia) sizeHeight8,
          _buildLikeAvatar(_postInfoDataModel?.postId ?? "", _subInfoDataModel),
        ],
      ),
    );
  }

  Widget _buildMediaItem(Operation o, {int totalImage = 0}) {
    final size = MediaQuery.of(context).size;
    if (o.isImage || o.isVideo) {
      final url = RichEditorUtils.getEmbedAttribute(o, 'source');
      final thumbUrl = RichEditorUtils.getEmbedAttribute(o, 'thumbUrl');
      return Container(
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: appThemeData.dividerColor.withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(5),
          ),
          child: Stack(
            alignment: AlignmentDirectional.bottomEnd,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ContainerImage(
                  o.isImage ? url : thumbUrl,
                  width: size.width,
                  thumbWidth: size.width.toInt() * 2,
                  fit: BoxFit.cover,
                  cacheManager: CircleCachedManager.instance,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                left: 0,
                child: Visibility(
                  visible: o.isVideo,
                  child: ValueListenableBuilder(
                    valueListenable: _showPlay,
                    builder: (ctx, value, child) {
                      return Visibility(
                        visible: value,
                        child: videoPlayIconWidget(),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Visibility(
                  visible: totalImage > 1,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.15),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // const SizedBox(
                          //   width: 12,
                          //   height: 12,
                          //   child: Icon(IconFont.buffCircleMoreImage,
                          //       color: Colors.white, size: 12),
                          // ),
                          // sizeWidth4,
                          Text(
                            '+$totalImage',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12, height: 1),
                          ),
                        ],
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

    return const SizedBox();
  }

  Widget _buildLikeAvatar(
      String postId, CirclePostSubInfoDataModel subInfoDataModel) {
    final List<Widget> widgetList = [];

    widgetList.add(
      TopicTagText(
        [
          if (_postInfoDataModel?.topicName?.hasValue)
            _postInfoDataModel.topicName
          else
            '全部'
        ],
        bgColor: const Color(0xff8d93a6).withOpacity(0.1),
        textColor: const Color(0xff5c6273),
      ),
    );

    final List<Widget> _list = [];
    for (var i = 0; i < widgetList.length; i++) {
      _list.add(Positioned(
        left: i * 14.0,
        child: widgetList[i],
      ));
    }

    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.fromLTRB(0, 4, 0, 16),
      height: 24,
      child: Row(
        children: [
          Expanded(
              child: Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Stack(alignment: Alignment.centerLeft, children: _list),
              ),
            ],
          )),
          if (isSearchItem())
            LikeButton(
              padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
              isLike: subInfoDataModel.iLiked == '1',
              count: subInfoDataModel.totalLikeNum,
              iconSize: 16,
              likeIconData: IconFont.buffCircleLike2New,
              unlikeIconData: IconFont.buffCircleUnlike2New,
              fontWeight: FontWeight.w500,
            )
          else
            ValidPermission(
              channelId: widget.circlePostDataModel.postInfoDataModel.topicId,
              permissions: [Permission.CIRCLE_ADD_REACTION],
              builder: (hasPermission, isOwner) {
                return GestureDetector(
                  onLongPress: () {
                    showBottomModal(context,
                        margin: const EdgeInsets.all(0),
                        backgroundColor: Theme.of(context).backgroundColor,
                        builder: (c, s) => AllLikeGrid(
                              postId,
                              subInfoDataModel.likeTotal,
                              guildId: widget.circlePostDataModel
                                  .postInfoDataModel.guildId,
                            ));
                  },
                  child: CircleAniLikeButton(
                    iconSize: 16,
                    fontWeight: FontWeight.w500,
                    likeIconData: IconFont.buffCircleLike2New,
                    //SvgIcons.circleLike,
                    unlikeIconData: IconFont.buffCircleUnlike2New,
                    //SvgIcons.circleUnlike,
                    padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
                    liked: subInfoDataModel.iLiked == '1',
                    count: subInfoDataModel.totalLikeNum,
                    unLikeColor: const Color(0xff5c6273),
                    hasPermission: hasPermission || isOwner,
                    postData: PostData(
                        guildId: widget
                            .circlePostDataModel.postInfoDataModel.guildId,
                        channelId: widget
                            .circlePostDataModel.postInfoDataModel.channelId,
                        topicId: widget
                            .circlePostDataModel.postInfoDataModel.topicId,
                        postId:
                            widget.circlePostDataModel.postInfoDataModel.postId,
                        t: 'post',
                        likeId: widget
                            .circlePostDataModel.postSubInfoDataModel.likeId,
                        commentId: ""),
                    onLikeChange: (t, v) {
                      if (t) {
                        widget.circlePostDataModel
                            .modifyLikedState('1', v, postId: postId);
                      } else {
                        widget.circlePostDataModel
                            .modifyLikedState('0', v, postId: postId);
                      }
                      CircleController.to.updateItem(
                          widget.circlePostDataModel.topicId,
                          widget.circlePostDataModel);
                      _initData();
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          sizeWidth10,
          FadeButton(
            onTap: () {
              CircleDetailRouter.push(CircleDetailData(
                widget.circlePostDataModel,
                extraData: ExtraData(extraType: ExtraType.fromSearch),
                modifyCallBack: (info) {
                  CircleTopicController.to(
                          topicId:
                              widget.circlePostDataModel.postInfo['topic_id'])
                      .loadData(reload: true);
                },
              ));
            },
            child: Row(
              children: [
                Container(
                  alignment: Alignment.center,
                  width: 30,
                  child: const Icon(IconFont.buffCircleReplyNew,
                      color: Color(0xff5c6273), size: 16),
                ),
                if (int.tryParse(subInfoDataModel.commentTotal) > 0)
                  Text(
                    subInfoDataModel.commentTotal,
                    style: _theme.textTheme.bodyText2.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xff5c6273),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 30,
            child: isSearchItem()
                ? Container(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerRight,
                    child: const Icon(IconFont.buffChatForwardNew,
                        color: Color(0xff5c6273), size: 20),
                  )
                : ShareButton(
                    size: 16,
                    color: const Color(0xff5c6273),
                    data: widget.circlePostDataModel,
                    sharePosterModel: CircleSharePosterModel(
                        circleDetailData: widget.circleDetailData),
                    isFromList: true,
                  ),
          )
        ],
      ),
    );
  }
}
