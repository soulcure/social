import 'package:flutter/material.dart';
import 'package:im/core/config.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';

class ContainerImage extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final double quality;
  final String url;
  final BoxFit fit;
  final int thumbHeight;

  const ContainerImage(
    this.url, {
    Key key,
    this.fit,
    this.width,
    this.height,
    this.thumbHeight = 445,
    this.radius = 0.0,
    this.quality = 1.5,
  }) : super(key: key);

  @override
  _ContainerImageState createState() => _ContainerImageState();
}

class _ContainerImageState extends State<ContainerImage> {
  String url;
  bool hasError = false;

  @override
  void initState() {
    url = widget.url;
    if (!_errorUrls.contains(url))
      url = transformToThumb(url);
    else
      hasError = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final hasSize = widget.width != null || widget.height != null;
    if (hasSize)
      return buildBody(widget.width, widget.height);
    else
      return LayoutBuilder(builder: (ctx, constraints) {
        return buildBody(constraints.maxWidth, constraints.maxHeight);
      });
  }

  Widget buildBody(double width, double height) {
    if (hasError)
      return buildResizeImage(width, height);
    else
      return buildSizedBox(widget.width, widget.height);
  }

  Widget buildSizedBox(double width, double height) {
    if (hasError)
      ResizedImage(
        url,
        width: width,
        height: height,
        quality: widget.quality,
        fit: widget.fit,
      );

    ///使用decoration展示的图片需要设置一个宽高，否则无法展示图片。
    ///外层再套用一个父容器，是为了处理图片大小自适应的一个情况，参考聊天列表里的根据高度自适应和表情包tab里的根据size自适应
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        height: width,
        width: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
          image: DecorationImage(
              image: CachedProviderBuilder(url,
                      cacheManager: CustomCacheManager.instance)
                  .provider,
              fit: widget.fit ?? BoxFit.contain,
              onError: (exception, stackTrace) {
                if (hasError) return;
                hasError = true;
                url = widget.url;
                _errorUrls.add(widget.url);
                refresh();
              }),
        ),
      ),
    );
  }

  Widget buildResizeImage(double width, double height) => ResizedImage(
        url,
        width: width,
        height: height,
        quality: widget.quality,
        fit: widget.fit,
      );

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant ContainerImage oldWidget) {
    if (!_errorUrls.contains(widget.url)) {
      if (hasError) {
        url = widget.url;
      } else {
        url = transformToThumb(widget.url);
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  String transformToThumb(String url) {
    if (url.endsWith('gif')) return url;
    return '$url?imageMogr2${Config.webpPath}/thumbnail/x${widget.thumbHeight}';
  }
}

///保存所有有问题的url
final Set<String> _errorUrls = {};

//
class ResizedImage extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final double quality;
  final String url;
  final BoxFit fit;

  const ResizedImage(
    this.url, {
    Key key,
    this.fit,
    this.width,
    this.height,
    this.radius = 0.0,
    this.quality = 1.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasSize = width != null || height != null;
    if (hasSize)
      return buildSizedBox(width, height);
    else
      return LayoutBuilder(builder: (ctx, constraints) {
        return buildSizedBox(constraints.maxWidth, constraints.maxHeight);
      });
  }

  Widget buildSizedBox(double width, double height) {
    int rH;
    int rW;
    if (height != null) rH = (height.toInt() * quality).toInt();
    if (width != null) rH = (width.toInt() * quality).toInt();
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        height: width,
        width: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          image: DecorationImage(
            image: ResizeImage(
                CachedProviderBuilder(url,
                        cacheManager: CustomCacheManager.instance)
                    .provider,
                width: rW,
                height: rH),
            fit: fit ?? BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
