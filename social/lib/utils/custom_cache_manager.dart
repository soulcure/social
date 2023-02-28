import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// ignore: implementation_imports
import 'package:flutter_cache_manager/src/storage/file_system/file_system_io.dart';

// ignore: implementation_imports
import 'package:flutter_cache_manager/src/storage/file_system/file_system_web.dart';
import 'package:im/const.dart';

class CustomCacheManager {
  static const key = 'customCacheKey';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 365 * 10),
      maxNrOfCacheObjects: int32MaxValue,
      // ignore: avoid_redundant_argument_values
      repo: kIsWeb ? null : JsonCacheInfoRepository(databaseName: key),
      // ignore: avoid_redundant_argument_values
      fileSystem: kIsWeb ? MemoryCacheSystem() : IOFileSystem(key),
      // fileService: HttpFileService(),
    ),
  );
}

class CircleCachedManager {
  static const key = 'circleCacheKey';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: int32MaxValue,
      // ignore: avoid_redundant_argument_values
      repo: kIsWeb ? null : JsonCacheInfoRepository(databaseName: key),
      // ignore: avoid_redundant_argument_values
      fileSystem: kIsWeb ? MemoryCacheSystem() : IOFileSystem(key),
      // fileService: HttpFileService(),
    ),
  );
}

/*
  判定资源是否已经缓存，缓存的话，就不要显示fadein 动画
   */
Future<bool> isResCached(BaseCacheManager manager, String url) async {
  if (manager is CacheManager) {
    final cacheObject = await manager.store.retrieveCacheData(url);
    return cacheObject != null;
  }
  return false;
}
