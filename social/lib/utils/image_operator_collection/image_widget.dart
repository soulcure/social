import 'package:flutter/material.dart';
import 'cached_image_refresher.dart';
import 'image_builder.dart';
import 'provider_builder.dart';

class ImageWidget extends StatelessWidget {
  ImageWidget.fromCachedNet(CachedImageBuilder imageBuilder)
      : imageWidget = CachedImageRefresher(
          url: imageBuilder.imageUrl,
          cacheManager: imageBuilder.cacheManager,
          onConnectWidget: (file, context) async {
            final cachedImBuilder = imageBuilder.imageBuilder;
            if (cachedImBuilder != null)
              return imageBuilder.imageBuilder.call(context,
                FileProviderBuilder(file).provider
              );
            return FileImageBuilder.fromCachedBuilder(imageBuilder, file)
                .buildWidget;
          },
          child: buildImage(imageBuilder),
        );

  ImageWidget.fromNetWork(NetworkImageBuilder imageBuilder)
      : imageWidget = buildImage(imageBuilder);

  ImageWidget.fromAsset(AssetImageBuilder imageBuilder)
      : imageWidget = buildImage(imageBuilder);

  ImageWidget.fromFile(FileImageBuilder imageBuilder)
      : imageWidget = buildImage(imageBuilder);

  ImageWidget.fromMemory(MemoryImageBuilder imageBuilder)
      : imageWidget = buildImage(imageBuilder);

  final Widget imageWidget;

  @override
  Widget build(BuildContext context) => imageWidget;

  static Widget buildImage(ImageBuilder imageBuilder) =>
      imageBuilder.buildWidget;
}

class ImageProviderProxy {
  ImageProviderProxy.fromCacheNet(CachedProviderBuilder providerBuilder)
      : provider = buildProvider(providerBuilder);

  ImageProviderProxy.fromNetwork(NetworkProviderBuilder providerBuilder)
      : provider = buildProvider(providerBuilder);

  ImageProviderProxy.fromAsset(AssetProviderBuilder providerBuilder)
      : provider = buildProvider(providerBuilder);

  ImageProviderProxy.fromFile(FileProviderBuilder providerBuilder)
      : provider = buildProvider(providerBuilder);

  ImageProviderProxy.fromMemory(MemoryProviderBuilder providerBuilder)
      : provider = buildProvider(providerBuilder);

  final ImageProvider provider;

  static ImageProvider buildProvider(ProviderBuilder providerBuilder) =>
      providerBuilder.provider;
}

enum ImageWidgetType {
  cacheNetworkImage,
  networkImage,
  assetImage,
  fileImage,
  memoryImage
}
