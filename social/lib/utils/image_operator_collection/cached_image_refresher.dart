import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:im/services/connectivity_service.dart';
import 'package:im/utils/image_operator_collection/image_util.dart';

import '../../loggers.dart';
import '../custom_cache_manager.dart';

class CachedImageRefresher extends StatefulWidget {
  final Widget child;
  final String url;
  final CallbackWidgetWithFile onConnectWidget;
  final CacheManager cacheManager;

  const CachedImageRefresher({
    @required this.child,
    this.onConnectWidget,
    @required this.url,
    this.cacheManager,
  });

  @override
  _CachedImageRefresherState createState() => _CachedImageRefresherState();
}

class _CachedImageRefresherState extends State<CachedImageRefresher> {
  StreamSubscription _netSubscription;
  Widget _newWidget;
  bool _isChecking = false;

  @override
  void initState() {
    checkIfImageExist();
    _netSubscription = Get.find<ConnectivityService>()
        .onConnectivityChanged
        .listen((result) async {
      ///TODO：目前存在wifi与mobile切换也会调用这里的问题，后续可以考虑优化
      if (result != ConnectivityResult.none) {
        await checkImage();
      }
    });
    super.initState();
  }

  Future checkImage({bool isInitial = false}) async {
    try {
      final url = widget.url;
      final manager = widget.cacheManager ?? CustomCacheManager.instance;
      if (_loadedImage.contains(url)) {
        final file = await manager.getFileFromCache(url);
        if (file?.file?.existsSync() ?? false) {
          _newWidget = await widget.onConnectWidget?.call(file.file, context);
          refresh();
        }
        return;
      }
      if (isInitial && !ImageUtil().hasError(url)) return;
      if (_isChecking) return;
      _isChecking = true;
      final file = await manager.getFileFromCache(url);
      final isFileExist = file != null && file.file.existsSync();
      if (!isFileExist) {
        final newFile = await manager.downloadFile(url);
        if (newFile.file.existsSync()) _loadedImage.add(url);
        _newWidget = await widget.onConnectWidget?.call(newFile.file, context);
        refresh();
      }
    } catch (e) {
      logger.finer('图片处理出错:$e');
    } finally {
      _isChecking = false;
    }
  }

  Future checkIfImageExist() async {
    final value = await Connectivity().checkConnectivity();
    if (value == ConnectivityResult.none) return;
    await checkImage(isInitial: true);
  }

  @override
  void dispose() {
    _netSubscription?.cancel();
    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _newWidget ?? widget.child;
  }
}

Set<String> _loadedImage = {};

void addLoadedImage(String url) {
  _loadedImage.add(url);
}

bool isLoadedImage(String url) {
  return _loadedImage.contains(url);
}

typedef CallbackWidgetWithFile = Future<Widget> Function(
    File file, BuildContext context);
