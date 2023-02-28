import 'dart:convert';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_link_preview/flutter_link_preview.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/web_api.dart';
import 'package:im/app/modules/document_online/info/views/doc_link_preview.dart';
import 'package:im/common/extension/list_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/tool/url_handler/web_link_handler.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/utils/message_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/tc_doc_utils.dart';
import 'package:im/web/utils/web_util/link_preview_parse.dart';
import 'package:im/web/widgets/web_video_player/web_video_player.dart';
import 'package:pedantic/pedantic.dart';

import '../loggers.dart';
import 'fanbook_link_preview.dart';
import 'flutter_video_link_parser/flutter_video_link_parser.dart';
import 'network_audio_player.dart';
import 'network_video_player.dart';

class LinkPreview extends StatefulWidget {
  final MessageEntity message;
  final String url;
  final bool onlyLink;
  final Function onTap;
  final Widget child;
  final String messageId;
  final String channelId;
  final String quoteL1;

  const LinkPreview(
      {Key key,
      this.message,
      this.url,
      this.child,
      this.onlyLink,
      this.onTap,
      this.messageId,
      this.channelId,
      this.quoteL1})
      : super(key: key);

  @override
  _LinkPreviewState createState() => _LinkPreviewState();
}

Map<String, Future<MeidaInfo>> _cache = {};

class _LinkPreviewState extends State<LinkPreview> {
  @override
  Widget build(BuildContext context) {
    final videoLinkType = MeidaLinkParser.linkType(widget.url);
    // 通用解析规则
    if (videoLinkType == SupportedVideoLink.unsupoorted) {
      if (isDocumentUrl(widget.url)) {
        return _buildDocument(widget.url);
      }
      return _buildCommonLink(widget.url, widget.child, context);
    }

    /// 已支持链接解析
    var future = _cache[widget.url];
    if (future == null) {
      future = MeidaLinkParser.parseByType(videoLinkType, widget.url);
      _cache[widget.url] = future;
      future.then((value) {
        if (value != null && widget.url != null)
          Db.videoCardBox.put(widget.url, value.toJson());
      }).catchError((e) => logger.severe("parse error: $e"));
    }
    MeidaInfo cacheInfo;
    if (Db.videoCardBox.containsKey(widget.url)) {
      try {
        cacheInfo = MeidaInfo.fromJson(Db.videoCardBox.get(widget.url));
        // ignore: empty_catches
      } catch (e) {
        logger.severe("error parse cached video card: ", e.toString());
      }
    }
    return FutureBuilder<MeidaInfo>(
        initialData: cacheInfo,
        future: future,
        builder: (context, snapshot) {
          //对于支持的链接解析，请求完成才渲染解析结果，防止_CachedLinkPreview解析导致的页面跳动
          if (snapshot.connectionState == ConnectionState.done ||
              snapshot.data != null) {
            return _buildMediaCard(context, videoLinkType, snapshot.data);
          } else {
            return _wrapInCard(widget.child, context);
          }
        });
  }

  bool isDocumentUrl(String url) {
    if (url != null && TcDocUtils.docUrlReg.hasMatch(url)) {
      return true;
    }
    return false;
  }

  ///在线文档widget
  Widget _buildDocument(String url) {
    String fileId;
    final match = TcDocUtils.docUrlReg.firstMatch(url)?.group(0);
    if (match != null) {
      final int start = widget.url.indexOf(match) + match.length;
      try {
        fileId = widget.url.substring(start);
        fileId = Uri.decodeComponent(fileId);
      } catch (e) {
        print(e);
      }
    }

    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.child,
          const SizedBox(height: 12),
          DocLinkPreview(url, fileId),
        ],
      ),
    );
  }

  Widget _buildCommonLink(String url, Widget child, BuildContext context) {
    return _CachedLinkPreview(
      message: widget.message,
      channelId: widget.channelId,
      url: url,
      builder: (info) {
        if (info == null) {
          return _wrapInCard(child, context);
        }

        if (info is WebVideoInfo) {
          return _wrapInCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                child,
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                AspectRatio(
                    aspectRatio: 16 / 9,
                    child: NetworkVideoPlayer(
                      info.mediaUrl,
                      widget.messageId,
                      widget.channelId,
                      duration: 0,
                    )),
              ],
            ),
            context,
          );
        } else if (info is WebImageInfo) {
          return _wrapInCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                child,
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: widget.onTap,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ImageWidget.fromCachedNet(CachedImageBuilder(
                      imageUrl: info.mediaUrl ?? "",
                      fit: BoxFit.cover,
                    )),
                  ),
                ),
              ],
            ),
            context,
          );
        } else if (info is WebAudioInfo) {
          return _wrapInCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                child,
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                AspectRatio(
                    aspectRatio: 16 / 9,
                    child: NetworkAudioPlayer(
                      info.mediaUrl,
                      messageId: widget.messageId,
                      artist: "",
                      albumName: "",
                      title: "",
                      duration: 0,
                    )),
              ],
            ),
            context,
          );
        }
        final WebInfo webInfo = info;
        // if (webInfo.redirectUrl != null) {
        //   if (webInfo.redirectUrl.contains("taptap.com/topic/")) {
        //     return _tapTap(info, context);
        //   }
        // }

        return _wrapInCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              child,
              if (WebAnalyzer.isNotEmpty(webInfo.title)) ...[
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: widget.onTap,
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: ImageWidget.fromCachedNet(CachedImageBuilder(
                            imageUrl: webInfo.icon ?? "",
                            imageBuilder: (context, imageProvider) => Image(
                                image: imageProvider,
                                fit: BoxFit.contain,
                                width: 30,
                                height: 30),
                            placeholder: (context, _) =>
                                _buildPlaceholder(context),
                            errorWidget: (context, _, error) =>
                                _buildPlaceholder(context),
                          ))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          webInfo.title,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyText2.copyWith(
                                fontSize: 16,
                                height: 1.25,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (WebAnalyzer.isNotEmpty(webInfo.description)) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                      onTap: widget.onTap, child: _buildDescription(webInfo)),
                ],
                if (WebAnalyzer.isNotEmpty(webInfo.mediaUrl)) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4)),
                        child: ImageWidget.fromCachedNet(
                          CachedImageBuilder(
                            imageUrl: webInfo.mediaUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ]
              ]
            ],
          ),
          context,
        );
      },
    );
  }

  ///构建 WebInfo 的 Description
  Widget _buildDescription(WebInfo webInfo) {
    final style = Theme.of(context)
        .textTheme
        .bodyText1
        .copyWith(fontSize: 14, height: 1.25);
    Widget getCircleWidget(WebCircleInfo webCircleInfo) {
      return ParsedText(
        style: style,
        text: webCircleInfo.description,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        parse: [
          ParsedTextExtension.matchCusEmoText(context, style.fontSize),
          ParsedTextExtension.matchAtText(
            context,
            textStyle: style,
            useDefaultColor: false,
            guildId: webCircleInfo.guildId,
            tapToShowUserInfo: false,
          ),
        ],
      );
    }

    if (webInfo is WebCircleInfo) {
      final resultWidget = getCircleWidget(webInfo);
      final idList = MessageUtil.getUserIdListInText(webInfo.description);
      if (idList.hasValue) {
        return UserInfo.getUserIdListWidget(idList, guildId: webInfo.guildId,
            builder: (c, _, __) {
          return resultWidget;
        });
      }
      return resultWidget;
    } else {
      if (webCircleInfoMap[webInfo?.redirectUrl] != null) {
        return getCircleWidget(webCircleInfoMap[webInfo?.redirectUrl]);
      }
      if (FanBookLinkPreview.isFanBookLink(webInfo?.redirectUrl)) {
        return sizedBox;
      }
      return Text(
        webInfo.description,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
  }

  Widget _buildPlaceholder(BuildContext context) =>
      const Icon(Icons.link, size: 16);

  Widget _buildMediaCard(
      BuildContext context, SupportedVideoLink videoLinkType, MeidaInfo info) {
    final title = info?.title;
    final url = info?.url;
    final aspectRatio = info?.aspectRatio;
    final thumb = info?.thumb;
    final artist = info?.artist;
    final albumName = info?.albumName;
    final duration = info?.duration;
    final type = info?.mediaType ?? 'video';
    final canPlay = info?.canPlay;
    final mediaIsEmpty = (thumb?.isEmpty ?? true) && (url?.isEmpty ?? true);
    if ((title?.isEmpty ?? true) && mediaIsEmpty) {
      return _buildCommonLink(widget.url, widget.child, context);
    }

    Widget getNativePlayer() {
      return type.contains('video')
          ? NetworkVideoPlayer(
              url,
              widget.messageId,
              widget.channelId,
              aspectRatio: aspectRatio,
              thumb: thumb,
              duration: duration,
            )
          : NetworkAudioPlayer(
              url,
              canPlay: canPlay,
              messageId: widget.messageId,
              artist: artist,
              albumName: albumName,
              title: title,
              thumb: thumb,
              duration: duration,
            );
    }

    final player = kIsWeb
        ? Container(
            color: Colors.black,
            child: WebVideoPlayer(
              videoUrl: url,
              thumbUrl: info?.thumb,
              duration: info?.duration,
              quoteL1: widget.quoteL1,
              messageId: widget.messageId,
            ),
          )
        : getNativePlayer();

    final videoItem = AspectRatio(
        aspectRatio: 16 / 9,
        child: info == null ? Container(color: Colors.black) : player);
    final card = _wrapInCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!widget.onlyLink || (title?.isEmpty ?? true)) ...[
            widget.child,
            const Divider(height: 24),
          ],
          if (title != null)
            GestureDetector(
              onTap: () => WebLinkHandler().handle(widget.url),
              child: Text(
                info.title,
                overflow: TextOverflow.ellipsis,
                maxLines: mediaIsEmpty ? 8 : 2,
                style: Theme.of(context)
                    .textTheme
                    .bodyText2
                    .copyWith(fontSize: 17, height: 1.25),
              ),
            ),
          if (!mediaIsEmpty) ...[
            const SizedBox(height: 12),
            if (OrientationUtil.portrait)
              videoItem
            else
              SizedBox(
                width: 360,
                child: videoItem,
              )
          ],
          const SizedBox(height: 8),
          _buildMeidaSiteRow(videoLinkType),
        ],
      ),
      context,
    );
    return canPlay ?? true
        ? card
        : GestureDetector(
            onTap: () => WebLinkHandler().handle(widget.url),
            child: card,
          );
  }

  Widget _buildMeidaSiteRow(SupportedVideoLink linkType) {
    String favicon;
    String siteName;

    switch (linkType) {
      case SupportedVideoLink.taptap:
        favicon = "https://www.taptap.com/favicon.ico";
        siteName = "TapTap";
        break;
      case SupportedVideoLink.bilibili:
        favicon = "https://b23.tv/favicon.ico";
        siteName = "哔哩哔哩".tr;
        break;
      case SupportedVideoLink.douyin:
        favicon =
            "https://sf1-dycdn-tos.pstatp.com/obj/eden-cn/kpchkeh7upepld/fe_app_new/favicon_v2.ico";
        siteName = "抖音".tr;
        break;
      case SupportedVideoLink.qqmusic:
        favicon = "https://c.y.qq.com/favicon.ico";
        siteName = "QQ音乐".tr;
        break;
      case SupportedVideoLink.neteasymusic:
        favicon = "https://y.music.163.com/favicon.ico";
        siteName = "网易云音乐".tr;
        break;
      case SupportedVideoLink.kuaishou:
        favicon = "https://v.kuaishou.com/favicon.ico";
        siteName = "快手".tr;
        break;
      case SupportedVideoLink.sinaweibo:
        favicon = "https://m.weibo.cn/favicon.ico";
        siteName = "新浪微博".tr;
        break;
      case SupportedVideoLink.xiaohongshu:
        favicon = "https://www.xiaohongshu.com/favicon.ico";
        siteName = "小红书".tr;
        break;
      case SupportedVideoLink.wechatarticle:
        favicon = "https://res.wx.qq.com/a/wx_fed/assets/res/NTI4MWU5.ico";
        siteName = "微信".tr;
        break;
      case SupportedVideoLink.feishudoc:
        favicon =
            "https://sf3-scmcdn2-cn.feishucdn.com/eesz/resource/bear/-favicon-v3.ico";
        siteName = "飞书".tr;
        break;
      case SupportedVideoLink.zhitongcaijing:
        favicon = "https://m.zhitongcaijing.com/favicon.ico";
        siteName = "智通财经".tr;
        break;
      case SupportedVideoLink.unsupoorted:
      default:
        favicon = "";
        siteName = "";
    }

    return Row(
      children: <Widget>[
        SizedBox(
            width: 16,
            height: 16,
            child: ImageWidget.fromCachedNet(CachedImageBuilder(
              imageUrl: favicon,
              imageBuilder: (context, imageProvider) {
                return Image(
                  image: imageProvider,
                  fit: BoxFit.contain,
                  width: 16,
                  height: 16,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholder(context),
                );
              },
            ))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            siteName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildTapTapCard(String url, Widget child, BuildContext context) {
    return _CachedLinkPreview(
      url: url,
      builder: (info) {
        if (info == null) return child;
        return _tapTap(info, context);
      },
    );
  }

  Widget _tapTap(InfoBase info, BuildContext context) {
    final WebInfo webInfo = info;
    return _wrapInCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!widget.onlyLink) ...[
            widget.child,
            const Divider(height: 24),
          ],
          if (WebAnalyzer.isNotEmpty(webInfo.title)) ...[
            Text(
              webInfo.title.replaceFirst(" | TapTap 发现好游戏".tr, ""),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: Theme.of(context)
                  .textTheme
                  .bodyText2
                  .copyWith(fontSize: 17, height: 1.25),
            ),
            if (!kIsWeb) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: widget.onTap,
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ImageWidget.fromCachedNet(CachedImageBuilder(
                    imageUrl: webInfo.mediaUrl,
                    fit: BoxFit.cover,
                    imageBuilder: (context, imageProvider) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                    placeholder: (context, _) => Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.black12),
                    ),
                  )),
                ),
              ),
            ],
            const SizedBox(height: 8),
            _buildSiteInfo(webInfo),
          ],
        ],
      ),
      context,
    );
  }

  Widget _buildSiteInfo(WebInfo webInfo) {
    final children = <Widget>[];
    if (!kIsWeb) {
      children.add(GestureDetector(
          onTap: widget.onTap,
          child: SizedBox(
              width: 16,
              height: 16,
              child: ImageWidget.fromCachedNet(CachedImageBuilder(
                imageUrl: webInfo.icon ?? "",
                imageBuilder: (context, imageProvider) {
                  return Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                    width: 16,
                    height: 16,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(context),
                  );
                },
              )))));
      children.add(const SizedBox(width: 8));
    }
    children.add(const Expanded(
      child: Text(
        "TapTap",
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12),
      ),
    ));
    return Row(children: children);
  }

  Widget _wrapInCard(Widget child, BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8)),
      child: child,
    );
  }
}

class _CachedLinkPreview extends StatefulWidget {
  final MessageEntity message;
  final String channelId;
  final String url;
  final Widget Function(InfoBase) builder;

  const _CachedLinkPreview(
      {this.message, this.channelId, this.url, this.builder, Key key})
      : super(key: key);

  @override
  __CachedLinkPreviewState createState() => __CachedLinkPreviewState();
}

class __CachedLinkPreviewState extends State<_CachedLinkPreview> {
  static WebInfo invalidInfo = WebInfo();
  static Box _box;
  InfoBase _info;

  @override
  void initState() {
    super.initState();
    _info = _getFromCache(widget.url);

    /// 即使本地缓存了数据，也需要拉取最新。
    /// 由于 WebAnalyzer.getInfo 有内存缓存
    /// 如果一个 URL 从有效变成无效1，下次启动 App 后才会看到卡片消失
    _getFromWeb(widget.url);
  }

  String _getKey(String url) {
    if (url.length <= 255) return url;
    return md5.convert(utf8.encode(url)).toString();
  }

  Future<void> _getFromWeb(String url) async {
    if (_box == null || !_box.isOpen) {
      _box = await Hive.openBox('webLinkCache17');
    }
    InfoBase info;
    if (!kIsWeb) {
      if (FanBookLinkPreview.isFanBookLink(url)) {
        final fbModel = await FanBookLinkPreview.getFanbookInfo(url);
        info = fbModel.info;
      } else {
        info = await WebAnalyzer.getInfo(url);
      }
    } else {
      final String html = await WebApi.relocationUrl(url, format: 'html')
          .timeout(const Duration(seconds: 3));
      if (html != null && html.isNotEmpty) {
        info = await LinkPreviewParse.getWebInfo(html);
      }
    }
    if (info is WebImageInfo) {
      unawaited(_box.put(_getKey(url), {"type": 1, "image": info.mediaUrl}));
    } else if (info is WebVideoInfo) {
      unawaited(_box.put(_getKey(url), {"type": 2, "image": info.mediaUrl}));
    } else if (info is WebAudioInfo) {
      unawaited(_box.put(_getKey(url), {"type": 4, "image": info.mediaUrl}));
    } else if (info is WebInfo) {
      unawaited(_box.put(_getKey(url), {
        "type": 0,
        "title": info.title,
        "icon": info.icon,
        "description": info.description,
        "image": info.mediaUrl,
        "redirectUrl": info.redirectUrl
      }));
    } else {
      /// 无效链接，不管
      unawaited(_box.put(_getKey(url), {"type": 3}));
    }

    if (mounted) {
      _info = info;
      setState(() {});
    }
  }

  InfoBase _getFromCache(String url) {
    if (_box == null || !_box.isOpen) return null;
    final json = _box.get(_getKey(url));
    InfoBase info;

    if (json != null) {
      final type = json["type"];
      if (type == 0) {
        info = WebInfo(
          title: json["title"],
          icon: json["icon"],
          description: json["description"],
          mediaUrl: json["image"],
          redirectUrl: json["redirectUrl"],
        );
      } else if (type == 1) {
        info = WebImageInfo(mediaUrl: json["image"]);
      } else if (type == 2) {
        info = WebVideoInfo(mediaUrl: json["image"]);
      } else if (type == 4) {
        info = WebAudioInfo(mediaUrl: json["image"]);
      } else if (type == 3) {
        return invalidInfo;
      } else if (type == 30) {
        info = invalidInfo;
      }
    }
    return info;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_info == invalidInfo ? null : _info);
  }
}
