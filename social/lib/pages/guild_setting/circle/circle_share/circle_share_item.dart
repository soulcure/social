import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/modules/circle_detail/circle_detail_router.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_util.dart';
import 'package:im/app/modules/circle_video_page/controllers/circle_video_page_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/db.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/circle_page.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/view/record_view/sound_play_manager.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/routes.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/audio_player_manager.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:pedantic/pedantic.dart';
import 'package:tuple/tuple.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../icon_font.dart';

/// * 圈子分享消息
class CircleShareItem extends StatefulWidget {
  final CircleShareEntity entity;
  final MessageEntity message;

  const CircleShareItem({Key key, this.entity, this.message}) : super(key: key);

  @override
  _CircleShareItemState createState() => _CircleShareItemState();
}

class _CircleShareItemState extends State<CircleShareItem> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable:
            memoryPostInfo?.deletedListener ?? ValueNotifier<bool>(false),
        builder: (ctx, value, child) {
          final hasDeleted = value ?? false;
          this.hasDeleted = hasDeleted;
          return GestureDetector(
            onTap: () => hasDeleted ? null : turnToCircle(context),
            child: Container(
              width: (Get.width - 15) / 2,
              decoration: BoxDecoration(
                color: appThemeData.scaffoldBackgroundColor,
                border: Border.all(
                    color: appThemeData.scaffoldBackgroundColor.withOpacity(0)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: hasDeleted ? buildDeleteWidget() : buildContent(),
            ),
          );
        });
  }

  Widget buildContent() {
    final titleTextStyle = appThemeData.textTheme.bodyText1.copyWith(
      fontSize: 14,
      height: 1.25,
      fontWeight: FontWeight.bold,
    );
    final contentTextStyle =
        appThemeData.textTheme.bodyText2.copyWith(fontSize: 14, height: 1.25);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<String>(
            valueListenable: memoryPostInfo?.titleListener ??
                ValueNotifier<String>("加载中...".tr),
            builder: (context, titleValue, _) {
              return ValueListenableBuilder<String>(
                  valueListenable: memoryPostInfo?.contentListener ??
                      ValueNotifier<String>("加载中...".tr),
                  builder: (context, contentValue, _) {
                    final tuple2 =
                        getContentAndMedia(contentValue ?? postContent);
                    //  是否有标题
                    final hasTitle = titleValue.hasValue;
                    //  是否有图
                    final hasImage = tuple2.item2 != null;
                    //  没有内容和标题，如果有提示用户就展示提示用户
                    List<String> mentions = [];
                    if (tuple2.item1.noValue && !hasTitle) {
                      mentions = getMentions(contentValue ?? postContent);
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasImage) _buildMediaItem(tuple2.item2, context),
                        if (!hasImage)
                          _getContent(
                              tuple2.item1, contentTextStyle, 5, hasImage),
                        if (hasImage && !hasTitle)
                          _getContent(
                              tuple2.item1, titleTextStyle, 2, hasImage),
                        if (hasTitle) _getTitle(titleValue ?? title),
                        if (mentions != null && mentions.isNotEmpty)
                          _buildMentionsView(mentions, titleTextStyle),
                      ],
                    );
                  });
            }),
        _getBottomRow(),
      ],
    );
  }

  /// * 标题，最多两行
  Widget _getTitle(String title) => title.noValue
      ? sizedBox
      : Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: appThemeData.textTheme.bodyText1.copyWith(
              fontSize: 14,
              height: 1.25,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

  /// * 动态内容
  Widget _getContent(
      String content, TextStyle textStyle, int maxLines, bool hasImage) {
    final textWidget = ParsedText(
      style: textStyle,
      text: content,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      parse: [
        ParsedTextExtension.matchCusEmoText(context, textStyle.fontSize),
        ParsedTextExtension.matchAtText(
          context,
          textStyle: textStyle,
          guildId: guildId,
          useDefaultColor: false,
          tapToShowUserInfo: false,
        ),
        ParsedTextExtension.matchChannelLink(
          context,
          textStyle: textStyle,
          tapToJumpChannel: false,
          hasBgColor: false,
          refererChannelSource: RefererChannelSource.CircleLink,
        ),
      ],
    );

    return content.noValue
        ? sizedBox
        : hasImage
            ? Container(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                width: double.infinity,
                alignment:
                    maxLines == 5 ? Alignment.center : Alignment.centerLeft,
                child: textWidget,
              )
            : LayoutBuilder(
                builder: (context, constraint) {
                  final width = constraint.maxWidth;
                  final height = width * 0.75;
                  return Container(
                    color: const Color(0xFFFBFBFD),
                    padding: const EdgeInsets.fromLTRB(9, 12, 8, 0),
                    width: width,
                    height: height,
                    alignment: Alignment.center,
                    child: textWidget,
                  );
                },
              );
  }

  /// * 底部用户头像和昵称，订阅图标
  Widget _getBottomRow() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: RealtimeAvatar(
            userId: userId,
            size: 16,
            guildId: guildId,
            showBorder: true,
          ),
        ),
        sizeWidth4,
        Expanded(
          child: RealtimeNickname(
            userId: userId,
            showNameRule: ShowNameRule.remarkAndGuild,
            style: appThemeData.textTheme.caption.copyWith(
              color: appThemeData.dividerColor.withOpacity(1),
              fontSize: 12,
            ),
          ),
        ),
        sizeWidth5,
        ValueListenableBuilder<bool>(
            valueListenable:
                memoryPostInfo?.followListener ?? ValueNotifier<bool>(false),
            builder: (context, value, _) {
              final _isFollow = value ?? isFollow;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Throttle.milliseconds(1000, postFollow),
                child: Container(
                  width: 50,
                  height: 35,
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.only(bottom: 9, right: 5),
                  child: Icon(
                    _isFollow
                        ? IconFont.buffCircleSubscribeSelect
                        : IconFont.buffCircleSubscribeUnselect,
                    size: 18,
                    color: _isFollow ? appThemeData.primaryColor : null,
                  ),
                ),
              );
            }),
      ],
    );
  }

  ///订阅和取消订阅
  Future postFollow() async {
    final result = await CircleDetailUtil.postFollow(
        channelId, postId, isFollow ? '0' : '1');
    if (result == null) return;
    if (result == '1') {
      data?.postSubInfoDataModel?.isFollow = true;
    } else {
      data?.postSubInfoDataModel?.isFollow = false;
    }
    memoryPostInfo?.setData(followed: isFollow);
  }

  /// * 第一张图片或视频封面
  Widget _buildMediaItem(Operation o, BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      String url;
      if (o.isImage)
        url = RichEditorUtils.getEmbedAttribute(o, 'source');
      else
        url = RichEditorUtils.getEmbedAttribute(o, 'thumbUrl');
      if (url.noValue) return sizedBox;

      final widgetWidth = constraint.maxWidth;
      double widgetHeight;
      double width, height;
      final w = RichEditorUtils.getEmbedAttribute(o, 'width');
      if (w is int) {
        width = w.toDouble();
      } else {
        width = w as double;
      }
      final h = RichEditorUtils.getEmbedAttribute(o, 'height');
      if (h is int) {
        height = h.toDouble();
      } else {
        height = h as double;
      }

      // 按照宽高比范围，计算高度
      widgetHeight = getImageHeightByRatio(width, height, widgetWidth);
      final child = Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6),
            ),
            child: ContainerImage(
              url,
              width: widgetWidth,
              height: widgetHeight,
              thumbWidth: CircleController.circleThumbWidth,
              fit: BoxFit.cover,
              cacheManager: CircleCachedManager.instance,
              placeHolder: (_, url) =>
                  const Center(child: CupertinoActivityIndicator()),
            ),
          ),
          if (o.isVideo)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.all(
                    Radius.circular(12),
                  ),
                ),
                width: 24,
                height: 24,
                child: WebsafeSvg.asset(
                  SvgIcons.circleVideoPlay,
                  width: 11,
                  height: 11,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      );
      return child;
    });
  }

  /// 组装视图：被提醒的人名称
  Widget _buildMentionsView(List<String> userIds, TextStyle style) => Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: UserInfo.getUserIdListWidget(
          userIds,
          guildId: guildId,
          builder: (context, users, child) {
            String mentionName = "";
            users.forEach((key, user) {
              mentionName += "@${user.showName(guildId: guildId)} ";
            });
            return Text(
              mentionName,
              style: style,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
      );

  /// * 动态被删除
  Widget buildDeleteWidget() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: Text(
            '该动态已被删除'.tr,
            style: appThemeData.textTheme.headline2.copyWith(fontSize: 14),
          ),
        )
      ],
    );
  }

  /// * 打开圈子详情页 或 沉浸式视频页
  Future turnToCircle(BuildContext context) async {
    //如果是视频类型，跳转沉浸式视频页
    if (data?.postInfoDataModel?.postType == CirclePostDataType.video &&
        data.postInfoDataModel?.firstMedia != null &&
        data.postInfoDataModel.firstMedia.isNotEmpty) {
      //如果语音或音乐在播放，先停止
      unawaited(SoundPlayManager().forceStop());
      if (AudioPlayerManager.instance.isPlaying) {
        unawaited(AudioPlayerManager.instance.stop());
      }
      return Routes.pushCircleVideo(
        Get.context,
        CircleVideoPageControllerParam(
          model: data,
          topicId: data.postInfoDataModel.topicId,
          circlePostDateModels: [data],
        ),
      );
    }
    //其他类型：跳转详情页
    return CircleDetailRouter.push(CircleDetailData(
      data,
      extraData: ExtraData(extraType: ExtraType.fromChatView),
      onBack: (value) {
        if (value == null) return;
        if (value is CirclePostDataModel) {
          widget.entity?.data?.updateByAnother(value);
          Future.delayed(300.milliseconds).then((_) {
            postInfoMap[postId]?.setData(followed: isFollow);
            refresh();
          });
        }
      },
    ));
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    try {
      final postInfo = postInfoMap[postId];
      if (postInfo == null) {
        final map = Db.circleShareBox.get(postId) ?? {};
        final commentTotal = map['commentTotal'] ?? this.commentTotal;
        final likeTotal = map['likeTotal'] ?? this.likeTotal;
        final likeByMyself = map['liked'] ?? this.likeByMyself;
        final deleted = map['deleted'] ?? false;
        final title = map['title'] ?? this.title ?? '';
        final isFollow = map['isFollow'] ?? this.isFollow;

        ///兼容旧版本
        final content = map['content'] ??
            postContent ??
            RichEditorUtils.defaultDoc.encode();
        postInfoMap[postId] = PostInfo(
          ValueNotifier(commentTotal),
          ValueNotifier(likeTotal),
          ValueNotifier(title),
          ValueNotifier(content),
          ValueNotifier(likeByMyself),
          ValueNotifier(deleted),
          postId,
          followListener: ValueNotifier(isFollow),
        );
      }

      final channelId = data?.postInfoDataModel?.channelId;
      final topicId = data?.postInfoDataModel?.topicId;

      //从服务器获取数据
      if (!_updatedPost.contains(postId) &&
          channelId.hasValue &&
          topicId.hasValue) {
        getModelFromNet(topicId, channelId, postId).then((value) {
          data?.updateByAnother(value);
          Future.delayed(300.milliseconds).then((_) {
            postInfoMap[postId]?.setData(followed: isFollow);
            refresh();
          });
        }).catchError((e) {
          if (e is RequestArgumentError && postIsDelete(e.code)) {
            postInfoMap[postId]?.setData(deleted: true);
          }
        });
      }
    } catch (e, s) {
      logger.severe("circle share item initState", e, s);
    }
  }

  @override
  void dispose() {
    super.dispose();
    Throttle.clear(postFollow);
    final entity = widget.entity;
    if (widget.message.localStatus != MessageLocalStatus.illegal)
      ChatTable.modifyMessage(widget.message.messageId, content: entity);
  }

  CirclePostDataModel get data => widget.entity?.data;

  CirclePostInfoDataModel get postInfo => data?.postInfoDataModel;

  CirclePostSubInfoDataModel get subInfo => data?.postSubInfoDataModel;

  CirclePostUserDataModel get userInfo => data?.userDataModel;

  String get commentTotal => subInfo?.commentTotal;

  String get likeTotal => subInfo?.likeTotal;

  bool get likeByMyself => subInfo?.iLiked == '1';

  String get createTime => postInfo?.createdAt ?? '';

  String get userId => userInfo?.userId ?? '';

  String get content => postInfo?.content;

  String get contentV2 => postInfo?.contentV2;

  String get postType => postInfo?.postType;

  String get title => postInfo?.title ?? '';

  String get postId => postInfo?.postId ?? '';

  String get channelId => postInfo?.channelId ?? '';

  String get guildId => data?.postInfoDataModel?.guildId ?? '';

  ///是否订阅
  bool get isFollow => data?.postSubInfoDataModel?.isFollow ?? false;

  String get postContent {
    if (postType.isEmpty) {
      return content;
    } else if (postType == CirclePostDataType.article ||
        postType == CirclePostDataType.image ||
        postType == CirclePostDataType.video) {
      return contentV2;
    } else {
      return null;
    }
  }

  PostInfo get memoryPostInfo => postInfoMap[postId];

  bool hasDeleted = false;

  void addTotalLike() {
    int num = 0;
    if (likeTotal.isNotEmpty) num = int.parse(likeTotal);
    num++;
    subInfo?.likeTotal = '$num';
    memoryPostInfo?.setData(likeTotal: '$num');
  }

  void removeTotalLike() {
    int num = 1;
    if (likeTotal.isNotEmpty) num = int.parse(likeTotal);
    if (num > 0) num--;
    subInfo.likeTotal = '$num';
    memoryPostInfo?.setData(likeTotal: '$num');
  }

  void changeLiked(bool liked) {
    memoryPostInfo?.setData(liked: liked);
    subInfo?.iLiked = liked ? '1' : '0';
  }

  /// * 解析动态的内容
  Tuple2<String, Operation> getContentAndMedia(String contentValue) {
    final list = getOperationList(contentValue);
    final media = list.firstWhere(
      (o) => o.isMedia,
      orElse: () => null,
    );
    final richTextSb = getRichText(list);
    final tempText = richTextSb.toString().compressLineString();
    return Tuple2(tempText, media);
  }

  /// * 获取消息内容中的@提醒用户数据
  List<String> getMentions(String contentValue) {
    try {
      final List<Map<String, dynamic>> list =
          List<Map<String, dynamic>>.from(jsonDecode(contentValue));
      final mansion = list?.firstWhere(
        (map) {
          final attributes = map["attributes"];
          if (attributes == null) {
            return false;
          }
          return attributes["mentions"] != null;
        },
        orElse: () => null,
      );
      if (mansion == null) return null;
      final List<dynamic> mentions = mansion["attributes"]["mentions"] ?? [];
      return mentions.map((mention) => mention.toString()).toList();
    } catch (_) {}
    return null;
  }
}

Future<CirclePostDataModel> getModelFromNet(
    String topicId, String channelId, String postId,
    {bool showErrorToast = false}) async {
  _updatedPost.add(postId);
  final postInfoDataModel =
      CirclePostDataModel.fromNet(topicId, channelId, postId);
  await postInfoDataModel.initFromNet(showErrorToast: showErrorToast);
  final subInfo = postInfoDataModel.postSubInfoDataModel;
  final postInfo = postInfoDataModel.postInfoDataModel;
  if (subInfo == null) {
    _updatedPost.remove(postId);
    return postInfoDataModel;
  }

  ///兼容旧版本
  final contentParam =
      postInfo.postContent() ?? RichEditorUtils.defaultDoc.encode();
  postInfoMap[postId]?.setData(
    commentTotal: subInfo.commentTotal,
    likeTotal: subInfo.likeTotal,
    title: postInfo.title,
    content: contentParam,
    liked: subInfo.iLiked == '1',
  );
  _updateInfo(postInfoDataModel);
  return postInfoDataModel;
}

void _updateInfo(CirclePostDataModel model, {CircleShareEntity entity}) {
  if (entity == null) return;
  final data = entity.data;
  data.postInfo = model.postInfo;
  data.dataInfo = model.dataInfo;
  data.subInfo = model.subInfo;
  data.userInfo = model.userInfo;
}

class ShareReplyWidget extends StatelessWidget {
  final InputModel inputModel;

  const ShareReplyWidget({Key key, @required this.inputModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.disabledColor;
    final textStyle = TextStyle(color: color, fontSize: 14);
    final reply = inputModel.reply;
    final localReplyUser = Db.userInfoBox.get(reply.userId);
    final replyName = localReplyUser?.showName() ?? '';

    return SizedBox(
      height: 40,
      child: Row(
        children: <Widget>[
          FadeButton(
            onTap: () => inputModel.reply = null,
            padding: const EdgeInsets.all(12),
            child: Icon(Icons.close, color: color, size: 16),
          ),
          SizedBox(
              height: 16,
              child: VerticalDivider(color: color.withOpacity(0.5))),
          const SizedBox(width: 12),
          Expanded(
            child: FutureBuilder(
                future: (reply.content as CircleShareEntity)
                    .toReplyNotificationString(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  const style =
                      TextStyle(color: color3, fontSize: 14, height: 1.25);
                  final String end = '的动态]'.tr;
                  final nameLength = replyName.length;
                  final data = snapshot.data?.toString() ?? '';
                  final nameBiggerThanOneLine =
                      nameLength * 14 > 300 || data.length * 14 > 300;

                  if (nameBiggerThanOneLine) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$replyName: ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: style,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                data,
                                style: style,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Text(
                              end,
                              style: style,
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  return RichText(
                      maxLines: 2,
                      text: TextSpan(
                          text: '$replyName : ',
                          style: textStyle,
                          children: [
                            TextSpan(text: snapshot.data),
                            TextSpan(text: '的动态]'.tr),
                          ]));
                }),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class ShareQuoteWidget extends StatelessWidget {
  final String userId;
  final MessageEntity entity;

  const ShareQuoteWidget({Key key, this.userId, this.entity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        UserInfo.get(userId),
        (entity.content as CircleShareEntity).toReplyNotificationString()
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 21);
        final String end = '的动态]'.tr;
        final UserInfo user = snapshot.data[0];
        const style = TextStyle(color: color3, fontSize: 14, height: 1.25);
        final name = user.showName();
        final nameLength = name.length;
        final data = snapshot.data[1]?.toString() ?? '';
        final nameBiggerThanOneLine = (nameLength * style.fontSize > 300) ||
            (data.length * style.fontSize > 300);

        if (nameBiggerThanOneLine) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$name: ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      data,
                      style: style,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Text(
                    end,
                    style: style,
                  ),
                ],
              ),
            ],
          );
        }
        return RichText(
          text: TextSpan(
              style: style,
              text:
                  "${user.showName()}: ${data?.replaceAll(RegExp("\n{2,}"), '\n')}",
              children: [
                TextSpan(text: end),
              ]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

///key 为 [postId]
final Map<String, PostInfo> postInfoMap = {};

///key为[postId],记录更新过的[post]
final Set<String> _updatedPost = {};

class PostInfo {
  final ValueNotifier<String> commentTotalListener;
  final ValueNotifier<String> likeTotalListener;
  final ValueNotifier<String> titleListener;
  final ValueNotifier<String> contentListener;
  final ValueNotifier<bool> likedListener;
  final ValueNotifier<bool> deletedListener;
  ValueNotifier<bool> followListener;
  final String postId;

  PostInfo(
    this.commentTotalListener,
    this.likeTotalListener,
    this.titleListener,
    this.contentListener,
    this.likedListener,
    this.deletedListener,
    this.postId, {
    this.followListener,
  }) {
    followListener ??= ValueNotifier(false);
  }

  void setData(
      {String commentTotal,
      String likeTotal,
      String title,
      String content,
      bool liked,
      bool deleted,
      bool needRefresh = true,
      bool followed}) {
    final map = Db.circleShareBox?.get(postId) ?? {};
    if (commentTotal != null) {
      if (needRefresh) commentTotalListener.value = commentTotal;
      map['commentTotal'] = commentTotal;
    }
    if (likeTotal != null) {
      if (needRefresh) likeTotalListener.value = likeTotal;
      map['likeTotal'] = likeTotal;
    }
    if (title != null) {
      if (needRefresh) titleListener.value = title;
      map['title'] = title;
    }
    if (content != null) {
      if (needRefresh) contentListener.value = content;
      map['content'] = content;
    }
    if (liked != null) {
      if (needRefresh) likedListener.value = liked;
      map['liked'] = liked;
    }
    if (deleted != null) {
      if (needRefresh) deletedListener.value = deleted;
      map['deleted'] = deleted;
    }
    if (followed != null) {
      if (needRefresh) followListener?.value = followed;
      map['isFollow'] = followed;
    }
    Db.circleShareBox?.put(postId, map);
  }
}

const timeColor = Color(0xff8F959E);
const contentColor = Color(0xff1F2125);
final color1 = primaryColor.shade600;
final color2 = primaryColor.shade500;
const color3 = Color(0xff6d6f73);
