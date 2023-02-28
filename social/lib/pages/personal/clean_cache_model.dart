import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_view/flutter_image_view.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/db/db.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/cos_file_download.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/im_utils/last_id_util.dart';
import 'package:im/utils/web_view_utils.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pedantic/pedantic.dart';

enum CleanCacheState {
  idle,
  calculating,
  calculated,
  cleaning,
}

class CleanCacheModel extends ChangeNotifier {
  CleanCacheState dataCacheState = CleanCacheState.idle;
  int dataSize = 0;

  CleanCacheState chatCacheState = CleanCacheState.idle;
  int chatSize = 0;

  void changeChatState(CleanCacheState state) {
    try {
      chatCacheState = state;
      notifyListeners();
    } catch (_) {}
  }

  Future<int> calcChatSpace() async {
    int size = 0;

    if (chatCacheState == CleanCacheState.idle) {
      changeChatState(CleanCacheState.calculating);
      chatSize = 0;
      try {
        final String path = await Db.getPath();
        if (File(path).existsSync()) {
          size = await _getTotalSizeOfFilesInDir(File(path));
          chatSize = size;
        }
        changeChatState(CleanCacheState.calculated);
      } catch (e) {
        changeChatState(CleanCacheState.calculated);
      }
    }
    return size;
  }

  ///清理聊天消息缓存
  Future cleanChatCache({bool isForce = false}) async {
    if (chatCacheState == CleanCacheState.calculated || isForce == true) {
      changeChatState(CleanCacheState.cleaning);
      try {
        await SpService.to.setBool(SP.isCleaningChatCache, true);
        await Db.cleanUserChatData();
        InMemoryDb.clear();
        LastIdUtil.clearLastMessageIds();
        GlobalState.selectedChannel.value = null;
        TextChannelUtil.clearAllTextChannelData();

        ///清理myGuild2和dmList2接口的参数
        unawaited(Db.userConfigBox.delete(UserConfig.dmList2Time));
        unawaited(Db.userConfigBox.delete(UserConfig.myGuild2Hash));
        unawaited(Db.userConfigBox.delete(UserConfig.dmList2ChannelIds));

        chatSize = 0;
        await SpService.to.setBool(SP.isCleaningChatCache, false);
        changeChatState(CleanCacheState.idle);
      } catch (e) {
        chatSize = 0;
        await SpService.to.setBool(SP.isCleaningChatCache, false);
        changeChatState(CleanCacheState.idle);
      }
    }
  }

  void changeDataCacheState(CleanCacheState state) {
    try {
      dataCacheState = state;
      // 如果页面已经退出，_listeners=null, 如果再调用notifyListeners()将报错
      notifyListeners();
    } catch (_) {}
  }

  Future<int> _calcManagerSpace(CacheManager manager) async {
    final baseDir = await getTemporaryDirectory();
    final path =
        p.join(baseDir.path, CustomCacheManager.instance.store.storeKey);
    if (path != null) {
      final d = Directory(path);
      return _getTotalSizeOfFilesInDir(d);
    }
    return 0;
  }

  Future<int> _calcTextureImageSpace() async {
    try {
      final baseDir = await FlutterImageView.cachedPath();
      if (baseDir != null) {
        final d = Directory(baseDir);
        return _getTotalSizeOfFilesInDir(d);
      }
    } catch (e) {
      logger.info(e.toString());
    }
    return 0;
  }

  //相册multi_image_pick压缩图片|视频文件
  Future<int> _calcImagePickSpace() async {
    try {
      final thumbPath = await MultiImagePicker.requestThumbDirectory();
      final dir = Directory(thumbPath ?? "");
      if (dir.existsSync()) {
        return _getTotalSizeOfFilesInDir(dir);
      }
    } catch (e) {
      logger.info(e.toString());
    }
    return 0;
  }

  //视频播放缓存
  Future<int> _calcVideoCacheSpace() async {
    try {
      final videoCahceDir = await MultiImagePicker.cachedVideoDirectory();
      final dir = Directory(videoCahceDir ?? "");
      if (dir.existsSync()) {
        return _getTotalSizeOfFilesInDir(dir);
      }
    } catch (e) {
      logger.info(e.toString());
    }
    return 0;
  }

  //文件下载目录
  Future<int> _calcFiledownSpace() async {
    try {
      final dir = await CosDownObject.fileDirectoryPath();
      if (dir.existsSync()) {
        return _getTotalSizeOfFilesInDir(dir);
      }
    } catch (e) {
      logger.info(e.toString());
    }
    return 0;
  }

  Future<int> calcDataCacheSpace() async {
    int size = 0;
    if (dataCacheState == CleanCacheState.idle) {
      dataSize = 0;
      changeDataCacheState(CleanCacheState.calculating);
      try {
        size += await _calcManagerSpace(CustomCacheManager.instance);
        size += await _calcManagerSpace(CircleCachedManager.instance);
        size += await _calcTextureImageSpace();
        size += await _calcImagePickSpace();
        size += await _calcVideoCacheSpace();
        size += await _calcFiledownSpace();
        dataSize = size;
        changeDataCacheState(CleanCacheState.calculated);
      } catch (e) {
        changeDataCacheState(CleanCacheState.calculated);
      }
    }
    return size;
  }

  //清空视频缓存
  Future<void> _cleanVideoCacheSpace() async {
    try {
      if (Platform.isIOS) {
        await MultiImagePicker.deleteCacheVideo();
        return;
      }
      final videoCahceDir = await MultiImagePicker.cachedVideoDirectory();
      final dir = Directory(videoCahceDir ?? "");

      if (dir.existsSync()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    } catch (e) {
      logger.info(e.toString());
    }
    return 0;
  }

  //清空压缩文件
  Future<void> _cleanImagePickSpace() async {
    try {
      final thumbPath = await MultiImagePicker.requestThumbDirectory();
      final dir = Directory(thumbPath ?? "");
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    } catch (e) {
      logger.info(e.toString());
    }
  }

  //清空用户下载文件缓存
  Future<void> _cleanFiledownSpace() async {
    try {
      final dir = await CosDownObject.fileDirectoryPath();
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    } catch (e) {
      logger.info(e.toString());
    }
  }

  Future cleanDataCache() async {
    if (dataCacheState == CleanCacheState.calculated) {
      changeDataCacheState(CleanCacheState.cleaning);
      try {
        await DefaultCacheManager().emptyCache();
        await CustomCacheManager.instance.emptyCache();
        await CircleCachedManager.instance.emptyCache();
        await FlutterImageView.cleanCache();
        await _cleanVideoCacheSpace();
        await _cleanImagePickSpace();
        await _cleanFiledownSpace();
      } catch (e, s) {
        logger.severe('清除缓存错误', e, s);
      } finally {
        unawaited(WebViewUtils.instance().deleteAll());
        dataSize = 0;
        changeDataCacheState(CleanCacheState.idle);
      }
    }
  }

  Future<int> _getTotalSizeOfFilesInDir(final FileSystemEntity file) async {
    if (file.existsSync() == false) return 0;

    if (file is File) {
      return await file.length() ?? 0;
    }
    if (file is Directory) {
      final List<FileSystemEntity> children = file.listSync();
      int total = 0;
      if (children != null)
        for (final FileSystemEntity child in children)
          total += await _getTotalSizeOfFilesInDir(child);
      return total;
    }
    return 0;
  }
}
