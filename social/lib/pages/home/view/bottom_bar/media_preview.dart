import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/check_radio_box.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

typedef MediaPreviewDidSelectCallBack = void Function(
    List<String> assets, bool origin);
typedef MediaPreviewDidRequestMoreCallBack = Future<Map<String, dynamic>>
    Function(String defaultSelectAsset, List<String> selectAssets, bool thumb);

class MediaPreviewTab extends StatefulWidget {
  final MediaPreviewDidSelectCallBack selectCallBack;
  final MediaPreviewDidRequestMoreCallBack moreCallBack;
  final String confirmBtnText;
  final FBMediaShowType showType;

  const MediaPreviewTab(this.selectCallBack, this.moreCallBack,
      {this.confirmBtnText = '发送', this.showType = FBMediaShowType.all});

  @override
  State<StatefulWidget> createState() => _MediaPreviewTab();
}

class _MediaPreviewTab extends State<MediaPreviewTab>
    with WidgetsBindingObserver {
  final List<Asset> _photos = [];
  final List<String> _selectPhotos = [];

  // 是否选择原图
  bool _originPhoto = false;

  // 是否正在后台获取相册图片
  bool _isLoadingMedia = false;

  // 防抖,是否已经进入全屏相册选择模式
  bool _didEnterPickerMode = false;

  // APP是否已经进入后台
  bool _didEnterBackground = false;

  // 从相册一次性获取图片数量,不能一次性全部获取,这样做loading时间太长.采用2*limit分步加载
  int _limit = 5;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_fetchMediaThumbInfo());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_didEnterPickerMode) {
      switch (state) {
        case AppLifecycleState.resumed:
          if (_didEnterBackground) {
            _didEnterBackground = false;
            MultiImagePicker.fetchMediaInfo(-1, -1, showType: widget.showType)
                .then((value) {
              // 防止这次还没刷新，又进入后台了
              if (_didEnterBackground) return;
              if (_selectPhotos.isNotEmpty) {
                // 防止进入后台前选择则了图片,进入后台后图片被删.
                final List<String> needRemoveSelectPhotos = [];
                for (final selectPhoto in _selectPhotos) {
                  final exist = value.firstWhere(
                      (element) => element.identifier == selectPhoto,
                      orElse: () => null);
                  if (exist == null) needRemoveSelectPhotos.add(selectPhoto);
                }
                _selectPhotos.removeWhere(needRemoveSelectPhotos.contains);
              }
              _photos.clear();
              _photos.addAll(value);
              setState(() {});
            });
          }
          break;
        case AppLifecycleState.paused:
          _didEnterBackground = true;
          break;
        default:
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => {},
      behavior: HitTestBehavior.opaque,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[_imageListView(), _operationContentView()]),
    );
  }

  Future _fetchMediaThumbInfo() async {
    try {
      _isLoadingMedia = true;
      // _offset: 起始位置， _limit：步长
      final medias = await MultiImagePicker.fetchMediaInfo(_offset, _limit,
          showType: widget.showType);
      if (medias.isNotEmpty) {
        _photos.addAll(medias);
        _offset += _limit;
        _limit *= 2;
        unawaited(_loadingMediaThumb());
      }
      _isLoadingMedia = false;
      if (mounted) setState(() {});
    } catch (e) {
      _isLoadingMedia = false;
    }
  }

  Future<void> _enterPickerMode(
      String defaultAsset, List<String> selectAssets, bool thumb) async {
    _didEnterPickerMode = true;
    final result = await widget.moreCallBack(defaultAsset, selectAssets, thumb);
    _didEnterPickerMode = false;
    if (result != null && result['assets'] is List && result['thumb'] is bool) {
      _selectPhotos.clear();
      _originPhoto = !(result['thumb'] as bool);
      final items = result['assets'] as List;
      for (final item in items) _selectPhotos.add(item['identify'].toString());
      setState(() {});
    }
  }

  Future<void> _loadingMediaThumb() async {
    //MultiImagePicker.fetchMediaInfo 对于不支持的文件类型可能会获取失败，导致medias <= _limit-_offset
    final medias = await MultiImagePicker.fetchMediaInfo(_offset, _limit,
        showType: widget.showType);
    if (medias.isNotEmpty && mounted) {
      _photos.addAll(medias);
      setState(() {});

      //取下一页媒体
      _offset += _limit;
      _limit *= 2;
      await _loadingMediaThumb();
    }
  }

  Widget _operationContentView() {
    final int selectCount = _selectPhotos.length;
    final _theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Container(
          width: 60,
          height: 32,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                  color: const Color(0xff8F959E).withOpacity(0.3), width: 0.5)),
          margin: const EdgeInsets.only(left: 12),
          child: TextButton(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.transparent),
                padding: MaterialStateProperty.all(const EdgeInsets.all(0))),
            onPressed: () {
              if (_didEnterPickerMode) return;
              final List<String> selectMedias = [];
              if (_selectPhotos.isNotEmpty) selectMedias.addAll(_selectPhotos);
              _enterPickerMode(null, selectMedias, !_originPhoto);
            },
            child: Text('相册'.tr,
                style: _theme.textTheme.bodyText2.copyWith(fontSize: 14)),
          ),
        ),
        SizedBox(
          height: 44,
          child: GestureDetector(
            onTap: () {
              _originPhoto = !_originPhoto;
              setState(() {});
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckRadioBox(
                    value: _originPhoto, selectColor: _theme.primaryColor),
                sizeWidth8,
                Text(
                  '原图'.tr,
                  style: TextStyle(
                      fontSize: 14, color: _theme.textTheme.bodyText2.color),
                )
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          width: 60,
          height: 32,
          child: TextButton(
            style: ButtonStyle(
                padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                )),
                backgroundColor: MaterialStateProperty.all(selectCount > 0
                    ? _theme.primaryColor
                    : _theme.primaryColor.withAlpha(125))),
            onPressed: () {
              if (selectCount <= 0) return;
              if (_selectPhotos.isNotEmpty)
                widget.selectCallBack(_selectPhotos, _originPhoto);
            },
            child: selectCount > 0
                ? Text('${widget.confirmBtnText.tr}($selectCount)',
                    style: const TextStyle(fontSize: 14, color: Colors.white))
                : Text(widget.confirmBtnText.tr,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.white54)),
          ),
        )
      ],
    );
  }

  Widget _imageListView() {
    if (_photos.isEmpty) {
      if (_isLoadingMedia) {
        return Expanded(
          child: Container(
              alignment: Alignment.center,
              child: const CircularProgressIndicator()),
        );
      } else {
        return Expanded(
          child: Container(
              alignment: Alignment.center, child: Text('本地相册暂无图片与视频，快去拍摄吧'.tr)),
        );
      }
    } else {
      return Expanded(
          child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _photos.length,
        itemBuilder: (context, i) => _thumbWidget(_photos[i]),
      ));
    }
  }

  Widget _thumbItem(Asset entity, Uint8List data) {
    final _theme = Theme.of(context);
    Widget cover;
    if (!_canSelectAsset(entity, toast: false))
      cover = GestureDetector(
          onTap: () => _canSelectAsset(entity),
          child: Container(color: Colors.black54));
    final selectIndex = _selectPhotos.indexOf(entity.identifier) + 1;
    if (entity.fileType.contains("video")) {
      final min = entity.duration ~/ 60;
      final minStr = min < 10 ? "0$min" : "$min";
      final sec = (entity.duration % 60).toInt();
      final secStr = sec < 10 ? "0$sec" : "$sec";
      return Container(
        width: 150,
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        child: Stack(
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: GestureDetector(
                onTap: () {
                  if (_didEnterPickerMode) return;
                  final List<String> selectMedias = [];
                  if (_selectPhotos.isNotEmpty)
                    selectMedias.addAll(_selectPhotos);
                  _enterPickerMode(
                      entity.identifier, selectMedias, !_originPhoto);
                },
                child: Image.memory(data,
                    fit: BoxFit.cover, gaplessPlayback: true),
              ),
            ),
            Container(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => _selectMedia(entity),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: <Widget>[
                      Container(
                        color: Colors.transparent,
                        width: 75,
                        height: 75,
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: selectIndex > 0
                              ? _theme.primaryColor
                              : Colors.black12,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: TextButton(
                          style: ButtonStyle(
                            padding: MaterialStateProperty.all(
                                const EdgeInsets.all(0.5)),
                            backgroundColor:
                                MaterialStateProperty.all(Colors.transparent),
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                              side: BorderSide(
                                  color: selectIndex > 0
                                      ? _theme.primaryColor
                                      : Colors.white),
                            )),
                          ),
                          onPressed: () => _selectMedia(entity),
                          child: Text(
                            selectIndex > 0 ? '$selectIndex' : '',
                            style: _theme.textTheme.bodyText2
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.videocam, color: Colors.white),
                  label: Text(
                    "$minStr:$secStr",
                    style: _theme.textTheme.bodyText2
                        .copyWith(color: Colors.white),
                  ),
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          const Color.fromRGBO(0, 0, 0, 0.4)),
                      shape: MaterialStateProperty.all(const StadiumBorder())),
                )),
            if (cover != null) cover else const SizedBox(height: 0, width: 0)
          ],
        ),
      );
    } else {
      return Container(
        width: 150,
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        child: Stack(
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: GestureDetector(
                onTap: () {
                  if (_didEnterPickerMode) return;
                  final List<String> selectMedias = [];
                  if (_selectPhotos.isNotEmpty)
                    selectMedias.addAll(_selectPhotos);
                  _enterPickerMode(
                      entity.identifier, selectMedias, !_originPhoto);
                },
                child: Image.memory(data, fit: BoxFit.cover),
              ),
            ),
            Container(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => _selectMedia(entity),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: <Widget>[
                    Container(color: Colors.transparent, width: 75, height: 75),
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selectIndex > 0
                            ? _theme.primaryColor
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () => _selectMedia(entity),
                        style: ButtonStyle(
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.all(0.5)),
                          backgroundColor:
                              MaterialStateProperty.all(Colors.black12),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                              side: BorderSide(
                                color: selectIndex > 0
                                    ? _theme.primaryColor
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        child: Text(
                          selectIndex > 0 ? '$selectIndex' : '',
                          style: _theme.textTheme.bodyText2
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (entity.fileType.contains("gif"))
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  height: 30,
                  width: 60,
                  margin: const EdgeInsets.fromLTRB(0, 0, 8, 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: const Color.fromRGBO(0, 0, 0, 0.4),
                  ),
                  alignment: Alignment.center,
                  child:
                      const Text("GIF", style: TextStyle(color: Colors.white)),
                ),
              )
            else
              const SizedBox(height: 0, width: 0),
            if (cover != null) cover else const SizedBox(height: 0, width: 0)
          ],
        ),
      );
    }
  }

  Future _selectMedia(Asset entity) async {
    if (!_canSelectAsset(entity)) return;
    if (_selectPhotos.contains(entity.identifier))
      _selectPhotos.remove(entity.identifier);
    else
      _selectPhotos.add(entity.identifier);
    setState(() {});
  }

  bool _canSelectAsset(Asset entity, {bool toast = true}) {
    if (_selectPhotos.length >= 9) {
      if (toast) showToast("最多选择9个媒体".tr);
      return false;
    }
    return true;
  }

  Widget _thumbWidget(Asset entity) {
    if (MultiImagePicker.containCacheData(entity.identifier))
      return _thumbItem(
          entity, MultiImagePicker.fetchCacheThumbData(entity.identifier));
    else
      return FutureBuilder(
        future: MultiImagePicker.fetchMediaThumbData(entity.identifier,
            fileType: entity.fileType),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data != null) {
              return _thumbItem(entity, snapshot.data);
            } else {
              return _errorWidget();
            }
          } else {
            return Container(width: 150);
          }
        },
      );
  }

  Widget _errorWidget() {
    final _theme = Theme.of(context);
    return Container(
      width: 150,
      color: _theme.scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconFont.buffCommonImageError,
            color: const Color(0xFF8F959E).withOpacity(0.3),
          ),
          sizeHeight16,
          Text(
            '不支持的文件格式'.tr,
            style: _theme.textTheme.bodyText2
                .copyWith(color: const Color(0xFF8F959E), fontSize: 10),
          )
        ],
      ),
    );
  }
}
