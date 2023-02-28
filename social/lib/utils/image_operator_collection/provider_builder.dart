import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart'
    as image_provider;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_util.dart';

abstract class ProviderBuilder {
  ImageProvider get provider;
}

class CachedProviderBuilder extends ProviderBuilder {
  final BaseCacheManager cacheManager;

  final String url;

  final double scale;

  final Map<String, String> headers;

  CachedProviderBuilder(this.url,
      {this.cacheManager, this.scale = 1.0, this.headers});

  @override
  ImageProvider<image_provider.CachedNetworkImageProvider> get provider =>
      image_provider.CachedNetworkImageProvider(url,
          scale: scale,
          headers: headers,
          cacheManager: cacheManager, errorListener: () {
        ImageUtil().addErrorUrl(url);
      });
}

class NetworkProviderBuilder extends ProviderBuilder {
  final String url;

  final double scale;

  final Map<String, String> headers;

  NetworkProviderBuilder(this.url, {this.scale = 1.0, this.headers});

  @override
  ImageProvider<NetworkImage> get provider =>
      NetworkImage(url, scale: scale, headers: headers);
}

class AssetProviderBuilder extends ProviderBuilder {
  final String assetName;

  final AssetBundle bundle;

  final String package;

  AssetProviderBuilder(this.assetName, {this.bundle, this.package});

  @override
  ImageProvider<AssetBundleImageKey> get provider =>
      AssetImage(assetName, bundle: bundle, package: package);
}

class FileProviderBuilder extends ProviderBuilder {
  final File file;

  final double scale;

  FileProviderBuilder(this.file, {this.scale = 1.0});

  @override
  ImageProvider<FileImage> get provider => FileImage(file, scale: scale);
}

class MemoryProviderBuilder extends ProviderBuilder {
  final Uint8List bytes;

  final double scale;

  MemoryProviderBuilder(this.bytes, {this.scale = 1.0});

  @override
  ImageProvider<MemoryImage> get provider => MemoryImage(bytes, scale: scale);
}
