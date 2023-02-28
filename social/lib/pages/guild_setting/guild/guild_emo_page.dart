import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/sticker_bean.dart';
import 'package:im/api/sticker_api.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/view/text_chat/items/sticker_item.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/dark_theme.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/utils/sticker_util.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/primary_button.dart';
import 'package:im/widgets/tap_edit_text.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:oktoast/oktoast.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../svg_icons.dart';
import 'container_image.dart';

class GuildEmoPage extends StatefulWidget {
  final String guildId;

  const GuildEmoPage(this.guildId, {Key key}) : super(key: key);

  @override
  _GuildEmoPageState createState() => _GuildEmoPageState();
}

class _GuildEmoPageState extends State<GuildEmoPage> {
  final _StateDelegate _stateDelegate = _StateDelegate();
  GuildEmoModel _model;

  @override
  void initState() {
    _stateDelegate._refreshCallback = _refresh;
    _model = GuildEmoModel(_stateDelegate);
    _model.guildId = widget.guildId;
    _model.initState();
    super.initState();
  }

  @override
  void dispose() {
    _stateDelegate._refreshCallback = null;
    _model.dispose();
    _model = null;
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = _model;
    final logic = model.logic;
    model.context ??= context;
    return Scaffold(
      appBar: CustomAppbar(
        title: '管理服务器表情'.tr,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leadingBuilder: (icon) {
          return IconButton(
              icon: icon,
              onPressed: () {
                if (model.isEditing) {
                  model.isEditing = false;
                  model.tempStickers.clear();
                  model.tempStickers
                      .addAll(StickerBean.copyFromList(model.copyStickers));
                  model.refresh();
                } else {
                  Get.back();
                }
              });
        },
        actions: [logic.editButton(theme)],
      ),
      body: Column(
        children: [
          Expanded(
            child: logic.buildLayout(theme),
          ),
          logic.uploadButton(theme),
        ],
      ),
    );
  }
}

class GuildEmoModel {
  final _StateDelegate stateDelegate;
  GuildEmoLogic logic;

  bool isEditing = false;
  bool isLoading = false;
  bool isUploading = false;

  String guildId;
  ScrollController controller;
  BuildContext context;
  double curOff = 0;
  final List<StickerBean> tempStickers = [];

  final List<StickerBean> copyStickers = [];

  ///用于判断能否点击确认修改名字
  final Set<String> urls = {};

  GuildEmoModel(this.stateDelegate) {
    logic = GuildEmoLogic(this);
  }

  void initState() {
    logic.getStickers();
    initialController();
  }

  void dispose() {
    disposeController();
    controller = null;
    tempStickers.clear();
    copyStickers.clear();
    urls.clear();
    context = null;
    logic.dispose();
    logic = null;
  }

  void _updateOff() => curOff = controller.offset;

  void initialController() {
    controller = ScrollController(initialScrollOffset: curOff);
    controller.addListener(_updateOff);
  }

  void disposeController() {
    controller.removeListener(_updateOff);
    controller.dispose();
  }

  bool get isEmpty => tempStickers?.isEmpty ?? true;

  bool get canUpload => (tempStickers?.length ?? 0) < emoLimit;

  void refresh() => stateDelegate?.refresh();
}

class GuildEmoLogic {
  GuildEmoModel _model;

  GuildEmoLogic(this._model);

  void dispose() {
    _model = null;
  }

  Widget buildLayout(ThemeData theme) {
    if (_model.isLoading && _model.isEmpty) return loadingWidget();
    if (_model.isEmpty && !_model.isEditing) return emptyWidget(theme);
    return listLayout(theme);
  }

  Widget loadingWidget() {
    if (!_model.isLoading) return const SizedBox();
    return Container(
      color: bgColor,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          if (_model.isEmpty) Text('表情上传中...'.tr)
        ],
      ),
    );
  }

  Widget emptyWidget(ThemeData theme) {
    final color1 = theme.textTheme.bodyText1.color;
    final color2 = darkTheme.textTheme.bodyText1.color;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color2.withOpacity(0.15)),
            alignment: Alignment.center,
            child: Icon(
              IconFont.buffChatEmoji,
              size: 40,
              color: color2,
            ),
          ),
          sizeHeight12,
          Text(
            '暂无表情符号，赶快添加吧'.tr,
            style: TextStyle(color: color1, fontSize: 18),
          ),
          sizeHeight6,
          tipText(color2, const EdgeInsets.only(left: 24, right: 24)),
        ],
      ),
    );
  }

  Widget tipText(Color textColor, EdgeInsetsGeometry margin) {
    return Container(
        margin: margin,
        child: Text(
          '添加最多%s个表情到该服务器，作为服务器专属表情。表情名称在1-5个字符之间。默认取第一个添加的表情缩略图作为整套表情的角标。建议上传240*240像素的图片，单个图片限制在20M以内。'
              .trArgs([emoLimit.toString()]),
          style: TextStyle(color: textColor, fontSize: 14),
        ));
  }

  Widget listLayout(ThemeData theme) {
    return _model.isEditing
        ? dragListWidget(theme, _model.tempStickers)
        : listWidget(theme, _model.tempStickers);
  }

  List<Widget> tipChildren(ThemeData theme) {
    final color1 = theme.textTheme.bodyText1.color;
    return [
      Container(
          margin: const EdgeInsets.only(top: 16),
          child: tipText(color1, const EdgeInsets.only(left: 16, right: 16))),
      Container(
          margin: const EdgeInsets.only(top: 20, left: 16, bottom: 8),
          width: double.maxFinite,
          child: Text(
            '已上传表情'.tr,
            style: TextStyle(color: color1, fontSize: 14),
          )),
    ];
  }

  Widget dragListWidget(ThemeData theme, List<StickerBean> stickers) {
    return ReorderableListView(
      scrollController: _model.controller,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tipChildren(theme),
      ),
      onReorder: (oldIndex, newIndex) {
        final old = _model.tempStickers.removeAt(oldIndex);
        if (newIndex > _model.tempStickers.length) {
          _model.tempStickers.add(old);
        } else {
          _model.tempStickers
              .insert(newIndex > oldIndex ? newIndex - 1 : newIndex, old);
        }
        _model.refresh();
      },
      children: List.generate(stickers.length, (index) {
        return emoItem(index, theme, stickers[index]);
      }),
    );
  }

  Widget listWidget(ThemeData theme, List<StickerBean> stickers) {
    return SingleChildScrollView(
      controller: _model.controller,
      child: Column(
        children: [
          ...tipChildren(theme),
          ListView.builder(
            itemBuilder: (ctx, index) {
              return emoItem(index, theme, stickers[index]);
            },
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stickers.length,
            padding: EdgeInsets.zero,
          ),
          ...[loadingWidget()]
        ],
      ),
    );
  }

  Widget emoItem(int index, ThemeData theme, StickerBean sticker) {
    final color1 = darkTheme.textTheme.bodyText1.color;

    final isEditing = _model.isEditing;
    return Container(
      height: 64,
      key: ValueKey(index),
      color: Colors.white,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 0, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isEditing)
              GestureDetector(
                  onTap: () {
                    final sticker = _model.tempStickers.removeAt(index);
                    final url = spliceGif(sticker.avatar);
                    _model.urls.remove(url);
                    _model.refresh();
                  },
                  child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: const Icon(
                        IconFont.buffCommonDeleteRed,
                        color: Colors.red,
                      ))),
            emoPic(sticker),
            sizeWidth12,
            Expanded(child: stickerNameWidget(sticker, index)),
            if (isEditing)
              Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Icon(
                    IconFont.buffChannelMoveEditLarge,
                    size: 20,
                    color: color1,
                  )),
          ],
        ),
      ),
    );
  }

  Widget stickerNameWidget(StickerBean sticker, int index) {
    final url = spliceGif(sticker.avatar);
    if (_model.isEditing)
      return SizedBox(
        height: 17,
        child: TabEditText(
          key: ValueKey(url),
          initialText: sticker.name ?? '',
          onChanged: (text) {
            if (text.isEmpty || text.replaceAll(' ', '') == '') {
              _model.urls.add(url);
              return;
            } else
              _model.urls.remove(url);
            _model.tempStickers[index].name = text.trim();
          },
        ),
      );
    return Text(
      sticker.name ?? '',
      style: const TextStyle(fontSize: 17, color: Color(0xff1F2125)),
    );
  }

  Widget emoPic(StickerBean sticker) {
    final url = spliceGif(sticker.avatar);
    return GestureDetector(
      onTap: () {
        final context = _model.context;
        showDialog(
            context: context,
            builder: (ctx) {
              return GestureDetector(
                onTap: Get.back,
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Container(
                    margin: const EdgeInsets.only(left: 28, right: 28),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8))),
                          width: 305,
                          height: 305,
                          child: Stack(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.only(top: 16, right: 16),
                                alignment: Alignment.topRight,
                                child: WebsafeSvg.asset(SvgIcons.svgTabClose,
                                    width: 24, height: 24),
                              ),
                              Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(40),
                                child: ContainerImage(
                                  url,
                                  fit: BoxFit.scaleDown,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            });
      },
      child: ContainerImage(
        url,
        fit: BoxFit.cover,
        radius: 4,
        width: 40,
      ),
    );
  }

  AppbarButton editButton(ThemeData theme) {
    if (_model.isEmpty && !_model.isEditing) return const AppbarNullButton();
    final isEditing = _model.isEditing;
    return AppbarTextButton(
      text: isEditing ? '完成'.tr : '编辑'.tr,
      onTap: () async {
        if (isEditing) {
          if (_model.urls.isNotEmpty) {
            showToast('表情名字不能为空'.tr);
            return;
          }

          if (_model.tempStickers.isNotEmpty) {
            final name = _model.tempStickers[0].name;
            //审核文字
            final textRes = await CheckUtil.startCheck(
                TextCheckItem(name, TextChannelType.CHANNEL_NAME),
                toastError: false);
            if (!textRes) {
              showToast('此内容包含违规信息,请修改后重试'.tr);
              return;
            }
          }

          await StickerUtil.instance.setStickers(_model.guildId,
              stickers: _model.tempStickers, onSuccess: () {
            StickerUtil.instance
                .setStickerById(_model.guildId, _model.tempStickers);
            _model.copyStickers.clear();
            _model.copyStickers
                .addAll(StickerBean.copyFromList(_model.tempStickers));
          }, onError: () {
            showToast('上传失败'.tr);
          });
        }
        _model.disposeController();
        _model.initialController();
        _model.isEditing = !isEditing;
        _model.refresh();
      },
    );
  }

  Widget uploadButton(ThemeData theme) {
    if (_model.isEditing) return sizedBox;
    final canUpload = _model.canUpload && !_model.isLoading;
    return SafeArea(
      child: Container(
        width: double.infinity,
        color: canUpload ? theme.scaffoldBackgroundColor : Colors.white,
        child: Container(
          width: double.infinity,
          height: 64,
          color: theme.scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: PrimaryButton(
            enabled: canUpload,
            onPressed: () async {
              if (_model.isUploading) return;
              _model.isUploading = true;
              if (canUpload) await pickStickers();
              _model.isUploading = false;
            },
            label: '上传表情'.tr,
          ),
        ),
      ),
    );
  }

  Future getStickers() async {
    final guildId = _model.guildId;
    _model.tempStickers.addAll(StickerUtil.instance.getStickerById(guildId));
    final res = await StickerApi.getStickers(guildId);
    if (res != null) {
      StickerUtil.instance.setStickerById(guildId, res);
      _model.tempStickers.clear();
      _model.tempStickers.addAll(res);
      _model.copyStickers.clear();
      _model.copyStickers.addAll(StickerBean.copyFromList(res));
      _model.refresh();
    }
  }

  Future pickStickers() async {
    final context = _model.context;
    final guildId = _model.guildId;
    final curStickers = _model.tempStickers;
    final length = curStickers.length;
    if (length >= emoLimit) {
      showToast('最多只能选择%s个表情'.trArgs([emoLimit.toString()]));
      return;
    }
    Map<dynamic, dynamic> result;
    try {
      result = await MultiImagePicker.pickImages(
          maxImages: emoLimit - length > 9 ? 9 : emoLimit - length,
          defaultAsset: null,
          mediaSelectType: FBMediaSelectType.image,
          doneButtonText: '上传'.tr,
          selectedAssets: [],
          cupertinoOptions: CupertinoOptions(
              takePhotoIcon: "chat",
              selectionStrokeColor:
                  "#${Theme.of(context).primaryColor.value.toRadixString(16)}",
              selectionFillColor:
                  "#${Theme.of(context).primaryColor.value.toRadixString(16)}"),
          materialOptions: MaterialOptions(
            allViewTitle: "所有图片".tr,
            selectCircleStrokeColor:
                "#${Theme.of(context).primaryColor.value.toRadixString(16)}",
          ));
    } on Exception catch (e) {
      print('error:$e');
    }
    if (result == null) return;
    final assetList = await MultiImagePicker.requestMediaData(
        thumb: false,
        selectedAssets: (result['identifiers'] as List).cast<String>());

    String failAssets = '';
    String failImagesForTooBig = '';

    final List<StickerBean> stickers = [];

    _model.isLoading = true;
    _model.refresh();
    await Future.forEach(assetList, (asset) async {
      if (!asset.fileType.startsWith('image')) return;
      final file = File(asset.filePath);
      if (!file.existsSync()) {
        failImagesForTooBig += '${asset.name} ';
        return;
      }
      final fileSize = file.lengthSync();
      if (fileSize > 1024 * 1024 * 20) {
        failImagesForTooBig += '${asset.name} ';
      } else {
        // Uint8List uploadFileBytes;
        // if (kIsWeb)
        //   uploadFileBytes = await PickedFile(asset.filePath).readAsBytes();
        // else
        //   uploadFileBytes = await File(asset.filePath).readAsBytes();
        String url;
        try {
          // url = await uploadFileIfNotExist(
          //     bytes: uploadFileBytes, filename: asset.name, fileType: "image");
          url = await CosFileUploadQueue.instance
              .onceForPath(asset.filePath, CosUploadFileType.image);
          final emoIndex = stickers.length + length + 1;
          stickers.add(StickerBean(url, '表情%s'.trArgs([emoIndex.toString()]),
              width: asset.originalWidth, height: asset.originalHeight));
        } on Exception catch (_) {
          failAssets += '${asset.name}、';
        }
      }
    });

    if (failImagesForTooBig.isNotEmpty) showToast('图片过大，上传失败'.tr);
    if (failAssets.isNotEmpty) showToast('网络异常，上传失败'.tr);
    final List<StickerBean> requestList = List.from(_model.tempStickers);
    requestList.addAll(stickers);
    await StickerUtil.instance.setStickers(guildId, stickers: requestList,
        onSuccess: () {
      StickerUtil.instance
          .addStickers(guildId, StickerBean.copyFromList(stickers));
      _model.tempStickers.addAll(stickers);
      _model.isLoading = false;
      _model.refresh();
      _model.copyStickers.clear();
      _model.copyStickers.addAll(StickerBean.copyFromList(_model.tempStickers));
    }, onError: () {
      showToast('上传失败'.tr);
      _model.isLoading = false;
      _model.refresh();
    });
    // for (var i = 0; i < assetList.length; ++i) {
    //   final asset = assetList[i];
    //   if (!asset.fileType.startsWith('image')) continue;
    //   final file = File(asset.filePath);
    //   if(!file.existsSync()) continue;
    //   final fileSize = file.lengthSync();
    //   if (fileSize > 1024 * 1024 * 20) {
    //     failImagesForTooBig += '${asset.name} ';
    //     if (i == assetList.length - 1) {
    //       if (failImagesForTooBig.isNotEmpty)
    //         showToast('表情: $failImagesForTooBig 上传失败');
    //     } else
    //       continue;
    //   } else {
    //     Uint8List uploadFileBytes;
    //     if (kIsWeb) {
    //       uploadFileBytes = await PickedFile(asset.filePath).readAsBytes();
    //     } else {
    //       uploadFileBytes = await File(asset.filePath).readAsBytes();
    //     }
    //     String url;
    //     try {
    //       url = await uploadFileIfNotExist(
    //           bytes: uploadFileBytes, filename: asset.name, fileType: "image");
    //       final emoIndex = stickers.length + length + 1;
    //       stickers.add(StickerBean(url, '表情%s'.trArgs([emoIndex.toString()]), Global.user.id,
    //           width: asset.originalWidth, height: asset.originalHeight));
    //     } on Exception catch (e) {
    //       logger.severe('图片上传失败', e?.toString() ?? '');
    //       failAssets += '${asset.name}、';
    //     }
    //   }
    //   if (i == assetList.length - 1) {
    //     if (failAssets.isNotEmpty) showToast('网络异常，上传失败'.tr);
    //     final List<StickerBean> requestList = List.from(_model.tempStickers);
    //     requestList.addAll(stickers);
    //     await StickerUtil.instance.setStickers(guildId, stickers: requestList,
    //         onSuccess: () {
    //       StickerUtil.instance
    //           .addStickers(guildId, StickerBean.copyFromList(stickers));
    //       _model.tempStickers.addAll(stickers);
    //       _model.isLoading = false;
    //       _model.refresh();
    //       _model.copyStickers.clear();
    //       _model.copyStickers
    //           .addAll(StickerBean.copyFromList(_model.tempStickers));
    //     }, onError: () {
    //       showToast('上传失败'.tr);
    //       _model.isLoading = false;
    //       _model.refresh();
    //     });
    //   }
  }
}

class _StateDelegate {
  VoidCallback _refreshCallback;

  void refresh() => _refreshCallback?.call();
}

const bgColor = Color(0xffF0F1F2);
const emoLimit = 100;
