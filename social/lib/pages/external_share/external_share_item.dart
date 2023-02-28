import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/view/gallery/model/gallery_item.dart';
import 'package:im/pages/home/view/gallery/photo_view.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_builder.dart';
import 'package:im/utils/image_operator_collection/image_widget.dart';
import 'package:im/widgets/image.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../routes.dart';
import '../../svg_icons.dart';

class ExternalShareItem extends StatefulWidget {
  final ExternalShareEntity entity;
  final MessageEntity message;

  const ExternalShareItem({Key key, this.entity, this.message})
      : super(key: key);

  @override
  _ExternalShareItemState createState() => _ExternalShareItemState();
}

class _ExternalShareItemState extends State<ExternalShareItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          if (widget.entity.shareContentType == "link") {
            // 链接点击，进入落地页
            if (widget.entity.link.hasValue) {
              Routes.pushHtmlPage(context, widget.entity.link);
            }
          } else if (widget.entity.shareContentType == "image") {
            // 图片点击，全屏展示
            final filePath =
                File(widget.entity.imageLocalPath ?? "").existsSync()
                    ? widget.entity.imageLocalPath
                    : null;
            showImageDialog(context, items: [
              GalleryItem(
                url: widget.entity.imageUrl,
                filePath: filePath,
              )
            ]);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.entity.shareContentType == "link") _buildLinkContent(),
            if (widget.entity.shareContentType == "image") _buildImageContent(),
            sizeHeight6,
            _buildClientInfo(),
          ],
        ));
  }

  Widget _buildLinkContent() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: const Color(0xff8F959E).withOpacity(0.3), width: 0.5),
          borderRadius: const BorderRadius.all(Radius.circular(5))),
      width: 234,
      child: Column(
        children: [
          _buildFrom(),
          _buildDesc(),
          _buildImage(),
        ],
      ),
    );
  }

  Widget _imageWidget(
    ExternalShareEntity entity,
    double width,
    double height,
    BoxFit fit,
  ) {
    if (entity.imageBytes != null) {
      return _getRectImage(width, height, fit, MemoryImage(entity.imageBytes));
    } else if (!kIsWeb &&
        entity.imageLocalPath.hasValue &&
        File(entity.imageLocalPath).existsSync()) {
      return _getRectImage(
          width, height, fit, FileImage(File(entity.imageLocalPath)));
    } else if (entity.imageUrl?.toLowerCase()?.endsWith("gif") ?? false) {
      // gif 会频繁触发imageBuilder，如果把ClipRRect放到imageBuilder，会增加功耗和CPU
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        clipBehavior: Clip.hardEdge,
        child: NetworkImageWithPlaceholder(
          entity.imageUrl,
          fit: fit,
          width: width,
          height: height,
        ),
      );
    } else if (entity.imageUrl?.hasValue ?? false) {
      return NetworkImageWithPlaceholder(entity.imageUrl,
          fit: fit,
          width: width,
          height: height,
          imageBuilder: (context, imageProvider) =>
              _getRectImage(width, height, fit, imageProvider));
    } else {
      return Container(
        width: width ?? 120,
        height: height ?? 225,
        decoration: BoxDecoration(
          color: const Color.fromARGB(0xff, 0xf0, 0xf1, 0xf2),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }
  }

  Widget _getRectImage(
      double width, double height, BoxFit fit, ImageProvider image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: width,
        height: height,
        child: Image(image: image, fit: fit),
      ),
    );
  }

  Widget _buildImageContent() {
    return Container(
      width: 225,
      height: 120,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(4))),
      child: _imageWidget(widget.entity, 225, 120, BoxFit.cover),
    );
  }

  Widget _buildFrom() {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, top: 12),
      height: 20,
      child: Row(
        children: [
          // Avatar(
          //   url: widget.entity.appAvatar ?? "",
          //   radius: 10,
          // ),
          Container(
            clipBehavior: Clip.hardEdge,
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F8),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: ImageWidget.fromCachedNet(CachedImageBuilder(
                imageUrl: widget.entity.appAvatar,
                width: 20,
                height: 20,
                fit: BoxFit.cover,
                placeholder: (cxt, url) => WebsafeSvg.asset(
                      SvgIcons.defaultShareAppIcon,
                      width: 20,
                      height: 20,
                    ),
                cacheManager: CustomCacheManager.instance)),
          ),
          sizeWidth5,
          Text(
            widget.entity.appName.hasValue ? widget.entity.appName : "应用".tr,
            style: const TextStyle(
                fontSize: 12, height: 15.0 / 12.0, color: Color(0xFF8F959E)),
          ),
        ],
      ),
    );
  }

  Widget _buildDesc() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Text(
        widget.entity.desc ?? "",
        style: const TextStyle(
            fontSize: 16, height: 19.0 / 16.0, color: Color(0xFF363940)),
        maxLines: 2,
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 9),
      height: 168,
      width: 210,
      child: _imageWidget(widget.entity, 168, 210, BoxFit.cover),

      // ImageWidget.fromCachedNet(
      //   CachedImageBuilder(
      //       fit: BoxFit.cover,
      //       imageUrl: widget.entity.imageUrl,
      //       height: 168,
      //       placeholder: (ctx,url) {
      //         if(widget.entity.imageBytes != null && widget.entity.imageBytes.isNotEmpty){
      //           return Image.memory(widget.entity.imageBytes,fit: BoxFit.cover,);
      //         }else if(widget.entity.imageLocalPath != null && widget.entity.imageLocalPath.isNotEmpty){
      //           return Image.file(File(widget.entity.imageLocalPath),fit: BoxFit.cover,);
      //         }else{
      //           return Icon(IconFont.buffImgLoadFail,
      //               size: 28, color: const Color(0xFF8F959E).withOpacity(0.65));
      //         }
      //       },
      //       cacheManager: CustomCacheManager.instance),
      // ),
    );
  }

  Widget _buildClientInfo() {
    // if (!widget.entity.appName.hasValue || !widget.entity.appAvatar.hasValue)
    //   return const SizedBox();
    return Row(
      children: [
        Container(
          height: 24,
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(
              color: Color(0xFFF5F5F8),
              borderRadius: BorderRadius.all(Radius.circular(3))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                clipBehavior: Clip.hardEdge,
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F8),
                  // borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
                child: ImageWidget.fromCachedNet(CachedImageBuilder(
                    imageUrl: widget.entity.appAvatar,
                    width: 16,
                    height: 16,
                    fit: BoxFit.cover,
                    placeholder: (cxt, url) => WebsafeSvg.asset(
                          SvgIcons.defaultShareAppIcon,
                          width: 16,
                          height: 16,
                        ),
                    cacheManager: CustomCacheManager.instance)),
              ),
              sizeWidth5,
              Text(
                widget.entity.appName.hasValue
                    ? widget.entity.appName
                    : "应用".tr,
                style: const TextStyle(
                    fontSize: 12,
                    // backgroundColor: Colors.green,
                    height: 16.0 / 12.0,
                    // textBaseline: TextBaseline.ideographic,
                    color: Color(0xFF646A73)),
              ),
            ],
          ),
        ),
        const Expanded(
          child: SizedBox(
            width: 1,
          ),
        ),
      ],
    );
  }
}
