import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/app/routes/app_pages.dart' as get_pages;
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/pages/home/view/gallery/gallery_gesture_wrapper.dart';
import 'package:im/pages/home/view/gallery/gallery_gif_view_widget.dart';
import 'package:im/pages/tool/url_handler/link_handler_preset.dart';
import 'package:im/pages/topic/topic_page.dart';
import 'package:im/routes.dart';
import 'package:im/utils/cos_file_cache_index.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/disk_util.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/widgets/custom/custom_page_route_builder.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:pedantic/pedantic.dart';
import 'package:photo_view/photo_view.dart' hide CacheNetworkImage;
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../../../../global.dart';
import 'custom_page_scrollphysics.dart';
import 'future_memory_image.dart';
import 'gallery_extension.dart';
import 'message_extension.dart';
import 'model/gallery_item.dart';
import 'model/gallery_model.dart';
import 'video_view.dart' as video;

export 'model/gallery_item.dart';

/// 翁翔的话题列表逻辑
List<MessageEntity> quoteL1List(TextChannelController model, String quoteL1) {
  int index = 0;
  final List<MessageEntity> messages = [];
  final list = model.internalList.list;
  while (index < list.length) {
    final curMessage = list[index];
    if (curMessage.messageId == quoteL1 || curMessage.quoteL1 == quoteL1)
      messages.add(curMessage);
    index++;
  }

  /// 如果取不到数据，可能是因为楼主消息被删除了，从 internalList.get 中可以获取被删除的消息
  if (messages.isEmpty || messages.first.messageId != quoteL1) {
    messages.insert(0, model.internalList.getFromCache(quoteL1));
  }
  return messages;
}

/// 获取聊天页面的视频图片列表
List<MessageEntity> getChatMessages(List<MessageEntity> messages) {
  final Map<String, int> tags = {};
  final messageList = messages;
  return messageList.where((element) {
    // 过滤相同tag
    if (tags[element.heroTag] == 1)
      return false;
    else
      tags[element.heroTag] = 1;
    // 过滤 删除和撤回的数据
    if (element.deleted == 1 || element.isRecalled) return false;

    if (element.content.runtimeType == ImageEntity) {
      final image = element.content as ImageEntity;
      final url = image.url;
      final path = image.asset?.filePath;
      final identifier = image.asset?.identifier ?? image.localIdentify ?? '';
      bool inCache = false;
      if (identifier.isNotEmpty) {
        final byte = MultiImagePicker.fetchCacheThumbData(identifier) ?? [];
        inCache = byte.isNotEmpty;
      }
      return (url != null && url.isNotEmpty) ||
          (path != null && path.isNotEmpty) ||
          inCache;
    } else if (element.content.runtimeType == VideoEntity) {
      final video = element.content as VideoEntity;
      final url = video.url;
      final path = video.asset?.filePath;
      return (url != null && url.isNotEmpty) ||
          (path != null && path.isNotEmpty);
    } else if (element.content.runtimeType == RichTextEntity) {
      return (element.content as RichTextEntity)
          .document
          .toDelta()
          .toList()
          .any((o) => o.isMedia);
    } else {
      return false;
    }
  }).toList();
}

// 获取messages所有图片视频的数量
int getMediaNum(List<MessageEntity> messages) {
  int num = 0;
  messages.forEach((m) {
    if ([VideoEntity, ImageEntity].contains(m.content.runtimeType)) {
      num++;
    } else if (m.content is RichTextEntity) {
      final mediaNum = (m.content as RichTextEntity)
          .document
          .toDelta()
          .toList()
          .where((o) => o.isMedia)
          .length;
      num += mediaNum;
    }
  });
  return num;
}

Future<void> showGallery(String routeName, MessageEntity message,
    {String quoteL1,
    @required List<MessageEntity> messages,
    int offset = 0,
    bool isNeedLocation = true}) async {
  final imageList = getChatMessages(messages);

//  final messageIndex = imageList.indexOf(message);
//  // 初始位置 = 当前消息前面的所有消息包含的媒体数量 + 当前消息里面媒体的位置
//  final mediaIndex =
//      getMediaNum(imageList.sublist(0, messageIndex)) + offset;
  final items = imageList.fold<List<GalleryItem>>(
      [], (previousValue, e) => [...previousValue, ...GalleryItem.initWith(e)]);
  final mediaIndex =
      items.indexWhere((element) => element.id == message.heroTag) + offset;
  await Navigator.push(
    Global.navigatorKey.currentContext,
    CustomPageRouteBuilder((ctx, animation, secondaryAnimation) {
      return Gallery(
        items: items,
        chatContent: ctx,
        initialIndex: mediaIndex,
        quoteL1: quoteL1,
        maxLength: items.length,
        routeName: routeName,
        isNeedLocation: isNeedLocation,
      );
    }),
  );
}

class Gallery extends StatefulWidget {
  Gallery({
    this.items,
    this.loadingBuilder,
    this.backgroundDecoration,
    this.initialIndex = 0,
    this.maxLength,
    this.chatContent,
    this.quoteL1,
    this.scrollDirection = Axis.horizontal,
    this.routeName = '',
    this.isNeedLocation = true,
    this.showIndicator = false,
  }) : pageController = PageController(initialPage: initialIndex);

  final List<GalleryItem> items;
  final LoadingBuilder loadingBuilder;
  final Decoration backgroundDecoration;
  final int initialIndex;
  final int maxLength;
  final PageController pageController;
  final Axis scrollDirection;
  final BuildContext chatContent;
  final String quoteL1;
  final String routeName;
  final bool isNeedLocation;
  final bool showIndicator;

  @override
  State<StatefulWidget> createState() {
    return GalleryState();
  }
}

class GalleryState extends State<Gallery> with TickerProviderStateMixin {
  int currentIndex;
  final GalleryModel model = GalleryModel();
  Map<String, String> qrCodeCache = <String, String>{};
  StreamSubscription recallSubScription;
  bool loadResult = true;

  ///记录哪一个index的图片显示在屏幕上，处理缩小时有两张图的问题
  final Map<int, bool> hasInitial = {};

  @override
  void initState() {
    currentIndex = widget.initialIndex;
    model.setPlay(
        !widget.items[min(currentIndex, widget.items.length - 1)].isImage);
    // 监听撤回消息
    recallSubScription = TextChannelUtil.instance?.stream
        ?.where((e) => e is RecallMessageEvent)
        ?.cast<RecallMessageEvent>()
        ?.listen((e) async {
      if (e.id == widget.items[currentIndex].id) {
        await showConfirmDialog(
          title: '该消息已经被撤回'.tr,
          confirmText: '知道了'.tr,
          showCancelButton: false,
        );
        await Future.delayed(const Duration(milliseconds: 100));
        Get.back();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    recallSubScription?.cancel();
    qrCodeCache.clear();
    super.dispose();
  }

  void onPageChanged(int index) {
    changeInitialState(index + 1, false);
    changeInitialState(index - 1, false);
    refresh();
    model?.setPlay(false);
    currentIndex = index;
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void changeInitialState(int index, bool value) {
    hasInitial[index] = value;
  }

  bool hasIndexInitial(int index) => hasInitial[index] ?? false;

  Future<void> _onLongPress() async {
    final isPicture = widget.items[currentIndex].isImage ??
        widget.items[currentIndex].message.content.runtimeType == ImageEntity;

    final List<String> items = [];
    if (isPicture) {
      items.add('保存图片'.tr);
    } else {
      //1.浏览别人发送的视频，会缓存到cache/video-cache目录下
      final filePath = (await MultiImagePicker.cachedVideoPath(
              widget.items[currentIndex].url))
          .toString();
      //2.浏览自己发送的视频，multi_image_picker会缓存缩略视频
      final cachedPath =
          CosUploadFileIndexCache.cachePath(widget.items[currentIndex].url) ??
              "";
      if (File(filePath).existsSync() || File(cachedPath).existsSync())
        items.add('保存视频'.tr);
    }
    if (widget.isNeedLocation) items.add('定位到聊天位置'.tr);
    if (isPicture) items.add('识别图中二维码'.tr);
    if (items.isEmpty) return;

    final index = await showCustomActionSheet(items.map((e) {
      if (e == '识别图中二维码'.tr) {
        FutureOr<Widget> checkQrCode() async {
          /// todo 如果之前检查过，直接返回
          try {
            final file = await CustomCacheManager.instance
                .getSingleFile(widget.items[currentIndex].url);
            if (file != null && file.path != null) {
              String barcode = qrCodeCache[file.path];
              final qrCodeResult = await QRScanner.decodeImage(file.path);
              barcode ??= qrCodeResult.code;
              if (barcode != null && barcode != "") {
                qrCodeCache[file.path] = barcode;
                return Text(e, style: Theme.of(context).textTheme.bodyText2);
              } else {
                qrCodeCache[file.path] = ""; //识别过，但是未识别出来，缓存成空字符串
              }
            }
            // ignore: empty_catches
          } catch (e) {}
          return const SizedBox();
        }

        return checkQrCode();
      } else {
        return Text(e, style: Theme.of(context).textTheme.bodyText2);
      }
    }).toList());
    if (index == null) return;

    final indexItem = items[index];
    if (indexItem == '保存视频'.tr || indexItem == '保存图片'.tr) {
      // 保存图片
      if (await DiskUtil.availableSpaceGreaterThan(200)) {
        unawaited(saveGalleryImage(widget.items[currentIndex]));
      } else {
        // showToast('磁盘空间不足');
        final bool isConfirm = await showConfirmDialog(
          title: '存储空间不足，清理缓存可释放存储空间'.tr,
        );
        if (isConfirm != null && isConfirm == true) {
          unawaited(Routes.pushCleanCachePage(context));
        }
      }
    } else if (indexItem == '定位到聊天位置'.tr) {
      // 定位到聊天内容
      final message = widget.items[currentIndex].message;
      final model = TextChannelController.to(channelId: message.channelId);
      switch (widget.routeName) {
        case app_pages.Routes.HOME:
        case directChatViewRoute:
          // 主聊天页面中
          final index = model.messageList.indexWhere(
              (element) => element.heroTag == widget.items[currentIndex].id);
          if (index >= 0) model.jumpToIndex(index, alignment: 0);
          Get.back();
          break;
        case get_pages.Routes.TOPIC_PAGE:
          // 话题详情页
          final messageList = quoteL1List(model, widget.quoteL1);
          final index = messageList.indexWhere((element) =>
              element.heroTag ==
              widget.items[currentIndex].id.replaceAll('Topic_', ''));
          if (index >= 0) {
            TopicPage.proxyController?.jumpToIndex(index + 1);
          }
          Get.back();
          break;
        case pinListRoute:
          // pin列表
          await Future.delayed(const Duration(milliseconds: 300));
          Routes.backHome();
          final message = widget.items[widget.initialIndex].message;
          unawaited(model.gotoMessage(message.messageId));
          break;
        default:
      }
    } else if (indexItem == '识别图中二维码'.tr) {
      //识别二维码
      try {
        final file = await CustomCacheManager.instance
            .getSingleFile(widget.items[currentIndex].url);
        if (file != null) {
          final qrCodeResult = await QRScanner.decodeImage(file.path);
          final String barcode = qrCodeResult.code;
          if (barcode != null) {
            print("scan bar code $barcode");
            unawaited(LinkHandlerPreset.common.handle(barcode));
          }
        }
      } catch (e) {
        print("error");
      }
    }

    // switch (items[index]) {
    //   case '保存视频':
    //   case '保存图片': // 保存图片
    //     final diskSpace = await DiskSpace.getFreeDiskSpace;
    //     if (diskSpace > 200) {
    //       unawaited(saveGalleryImage(widget.items[currentIndex]));
    //     } else {
    //       // showToast('磁盘空间不足');
    //       final bool isConfirm = await showConfirmDialog(
    //         title: '存储空间不足，清理缓存可释放存储空间',
    //       );
    //       if (isConfirm != null && isConfirm == true) {
    //         unawaited(Routes.pushCleanCachePage(context));
    //       }
    //     }
    //     break;
    //   case '定位到聊天位置': // 定位到聊天内容
    //     final message = widget.items[currentIndex].message;
    //     final model = TextChannelController.to(channelId: message.channelId);
    //     switch (widget.routeName) {
    //       case homeRoute:
    //       case directChatViewRoute:
    //         // 主聊天页面中
    //         final index = model.messageList.indexWhere(
    //             (element) => element.heroTag == widget.items[currentIndex].id);
    //         if (index >= 0) model.jumpToIndex(index, alignment: 0);
    //         Navigator.of(context).pop();
    //         break;
    //       case get_pages.Routes.TOPIC_PAGE:
    //         // 话题详情页
    //         final messageList = quoteL1List(model, widget.quoteL1);
    //         final index = messageList.indexWhere((element) =>
    //             element.heroTag ==
    //             widget.items[currentIndex].id.replaceAll('Topic_', ''));
    //         if (index >= 0) {
    //           TopicPage.proxyController?.jumpToIndex(index + 1);
    //         }
    //         Navigator.of(context).pop();
    //         break;
    //       case pinListRoute:
    //         // pin列表
    //         await Future.delayed(const Duration(milliseconds: 300));
    //         Routes.backHome();
    //         final message = widget.items[widget.initialIndex].message;
    //         unawaited(model.gotoMessage(message.messageId));
    //         break;
    //       default:
    //     }
    //     break;
    //   case '识别图中二维码':
    //     {
    //       //识别二维码
    //       try {
    //         final file = await CustomCacheManager.instance
    //             .getSingleFile(widget.items[currentIndex].url);
    //         if (file != null) {
    //           print("path:${file.path}");
    //           final qrCodeResult = await QRScanner.decodeImage(file.path);
    //           final String barcode = qrCodeResult.code;
    //           if (barcode != null) {
    //             print("barcode:$barcode");
    //             if (await canLaunch(barcode)) {
    //               await launch(barcode,
    //                   forceWebView: false,
    //                   enableJavaScript: true,
    //                   forceSafariVC: true,
    //                   universalLinksOnly: true);
    //             } else if (barcode.startsWith("http")) {
    //               await Routes.pushHtmlPage(context, barcode);
    //             } else {
    //               await Routes.pushHtmlPage(context, barcode);
    //             }
    //           }
    //         }
    //       } catch (e) {
    //         print("error");
    //       }
    //     }
    //     break;
    // }
  }

  void _onScaleStart(context, details, delta, controllerValue) {
    galleryGestureWrapperKey.currentState
        .onScaleStart(context, details, delta, controllerValue);
  }

  void _onScaleUpdate(context, details, delta, controllerValue) {
    galleryGestureWrapperKey.currentState
        .onScaleUpdate(context, details, delta, controllerValue);
  }

  void _onScaleEnd(context, details, delta, controllerValue) {
    galleryGestureWrapperKey.currentState
        .onScaleEnd(context, details, delta, controllerValue);
  }

  @override
  Widget build(BuildContext context) {
    final child = ChangeNotifierProvider(
        create: (_) => model,
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: GestureDetector(
              onLongPress: _onLongPress,
              child: Container(
                constraints: BoxConstraints.expand(
                  height: MediaQuery.of(context).size.height,
                ),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: <Widget>[
                    PhotoViewGallery.builder(
                      builder: _buildItem,
                      onScaleStart: _onScaleStart,
                      onScaleUpdate: _onScaleUpdate,
                      onScaleEnd: _onScaleEnd,
                      itemCount: widget.items.length,
                      loadingBuilder: widget.loadingBuilder,
                      backgroundDecoration: widget.backgroundDecoration,
                      pageController: widget.pageController,
                      onPageChanged: onPageChanged,
                      scrollDirection: widget.scrollDirection,
                      scrollPhysics: const CustomPageScrollPhysics(),
                    ),
                    if (widget.showIndicator && widget.items.length > 1)
                      Positioned(
                        top: Get.mediaQuery.padding.top + 12,
                        left: 16,
                        child: _buildIndicator(),
                      ),
                  ],
                ),
              ),
            )));
    return GalleryGestureWrapper(
      key: galleryGestureWrapperKey,
      onDismiss: () {
        refresh();
        model?.setPlay(false);
      },
      child: child,
    );
  }

  Widget _buildIndicator() {
    return Container(
      decoration: BoxDecoration(
        color: appThemeData.textTheme.bodyText2.color.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        "${currentIndex + 1}/${widget.items.length}",
        style: appThemeData.textTheme.bodyText2.copyWith(
          color: appThemeData.backgroundColor,
          fontSize: 12,
          height: 1.25,
        ),
      ),
    );
  }

  PhotoViewGalleryPageOptions _buildImageItem(BuildContext context, int index) {
    final GalleryItem item = widget.items[index];
    ImageProvider provider;
    if (item.filePath != null && item.filePath.isNotEmpty)
      provider = FileImage(File(item.filePath));
    else if (item.url != null && item.url.isNotEmpty) {
      if (kIsWeb) {
        provider = NetworkImage(item.url);
      } else {
        //使用官方的 CachedNetworkImageProvider，原有的有缺陷(无法重新加载图片)
        provider = CachedProviderBuilder(item.url,
                cacheManager: CustomCacheManager.instance)
            .provider;
      }
    } else if (item.identifier != null && item.identifier.isNotEmpty)
      provider = FutureMemory(MultiImagePicker.fetchMediaThumbData(
          item.identifier,
          fileType: 'image'));
    else if (item.resource != null) provider = AssetImage(item.resource);

    //gif图片显示：背景色为白色, 不全屏
    if (item.url != null && item.url.toLowerCase().endsWith("gif")) {
      return PhotoViewGalleryPageOptions.customChild(
          backgroundDecoration: const BoxDecoration(color: Colors.transparent),
          childSize: const Size(100, 60),
          onTapUp: (context, _, value) {
            Get.back();
          },
          child: GalleryGifViewWidget(imageUrl: item.url),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.contained,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd);
    }

    final content = item.message?.content;
    int imageWidth;
    int imageHeight;
    if (content != null && content is ImageEntity) {
      imageWidth = content.width.round();
      imageHeight = content.height.round();
    }
    final screenSize = MediaQuery.of(context).size;
    final devicePixelRadio = MediaQuery.of(context).devicePixelRatio;
    final needResize = (imageWidth == null || imageHeight == null) ||
        (imageHeight / devicePixelRadio > screenSize.height &&
            imageWidth / devicePixelRadio > screenSize.width);
    final reSizeProvider = needResize
        ? ImageUtil().buildResizeProvider(
            context,
            provider,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
          )
        : provider;
    final isVerticalLongPhoto = (imageHeight ?? 1) / (imageWidth ?? 1) > 2.5;
    final hasInitial = hasIndexInitial(index);

    //其他图片背景为黑色
    return PhotoViewGalleryPageOptions(
        backgroundDecoration: hasInitial
            ? const BoxDecoration(color: Colors.transparent)
            : BoxDecoration(
                color: Colors.transparent,
                image: DecorationImage(
                  image: CachedProviderBuilder(item.holderUrl,
                          cacheManager: CustomCacheManager.instance)
                      .provider,
                  alignment: isVerticalLongPhoto
                      ? Alignment.topCenter
                      : Alignment.center,
                  fit: isVerticalLongPhoto ? BoxFit.fitWidth : BoxFit.contain,
                ),
              ),
        imageProvider: reSizeProvider,
        onTapUp: (context, _, value) {
          Get.back();
        },
        filterQuality: FilterQuality.high,

        ///这里处理缩小时，出现两张图的情况
        loadResultCallback: (result) {
          if (!result) {
            loadResult = false;
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              refresh();
            });
          }
          if (!hasIndexInitial(index) && currentIndex == index) {
            changeInitialState(index, true);

            ///延时刷新，在长图解析时避免黑屏
            Future.delayed(const Duration(milliseconds: 800), refresh);
          }
        },
        //占位符-缩略图
        holderWiget: item.holderUrl == null
            ? Container()
            : ImageWidget.fromCachedNet(CachedImageBuilder(
                cacheManager: CustomCacheManager.instance,
                imageUrl: item.holderUrl,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                alignment: isVerticalLongPhoto
                    ? Alignment.topCenter
                    : Alignment.center,
                fit: isVerticalLongPhoto ? BoxFit.fitWidth : BoxFit.contain,
              )),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd);
  }

  PhotoViewGalleryPageOptions _buildVideoItem(BuildContext context, int index) {
    final GalleryItem item = widget.items[index];
    return PhotoViewGalleryPageOptions.customChild(
      child: video.VideoView(
        thumbUrl: item.holderUrl,
        videoUrl: item.url,
        thumbHeight: item.thumbHeight,
        thumbWidth: item.thumbWidth,
        getFileFromCache: (url) async =>
            CustomCacheManager.instance.getSingleFile(url),
        saveFileToCache: (url, bytes) async => CustomCacheManager.instance
            .putFile(url, bytes,
                fileExtension: url.substring(url.lastIndexOf('.') + 1)),
        placeHolder: item.holderUrl == null
            ? Container()
            : ImageWidget.fromCachedNet(CachedImageBuilder(
                cacheManager: CustomCacheManager.instance,
                imageUrl: item.holderUrl,
                width: item.thumbWidth,
                height: item.thumbHeight,
                fit: BoxFit.contain,
              )),
        model: model,
        autoPlay: index == widget.initialIndex,
      ),
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      minScale: PhotoViewComputedScale.contained * 1.0,
      maxScale: PhotoViewComputedScale.contained * 1.0,
    );
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    final GalleryItem item = widget.items[index];
    if (item == null)
      return PhotoViewGalleryPageOptions.customChild(child: Container());
    if (item.isImage) {
      return _buildImageItem(context, index);
    } else {
      return _buildVideoItem(context, index);
    }
  }
}
