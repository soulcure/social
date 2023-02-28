import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/sticker_bean.dart';
import 'package:im/api/sticker_api.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/view/text_chat/items/sticker_item.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/dark_theme.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/utils/sticker_util.dart';
import 'package:im/web/extension/state_extension.dart';
import 'package:im/web/utils/image_picker/image_picker.dart' as pickermoreimage;
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:im/web/widgets/button/web_hover_button.dart';
import 'package:im/web/widgets/web_form_detector/web_form_detector_model.dart';
import 'package:im/widgets/custom_inputbox_web.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';

import 'container_image.dart';

class GuildEmoPage extends StatefulWidget {
  final String guildId;

  const GuildEmoPage(this.guildId, {Key key}) : super(key: key);

  @override
  _GuildEmoPageState createState() => _GuildEmoPageState();
}

class _GuildEmoPageState extends State<GuildEmoPage> {
  List<StickerBean> stickersList = [];
  List<StickerBean> reStickersList = [];
  bool isEditing = false;
  ScrollController controller;

  @override
  void initState() {
    super.initState();
    getStickers();
    controller = ScrollController();
    checkFormChanged();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      formDetectorModel.setCallback(onReset: _onReset, onConfirm: _onConfirm);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void checkFormChanged() {
    Provider.of<WebFormDetectorModel>(context, listen: false)
        .toggleChanged(formChanged);

    final bool disable = stickersList.any((e) {
      return (e.name.trim().isEmpty) || (e.name.trim().characters.length > 6);
    });
    formDetectorModel.confirmEnabled(!disable);
  }

  bool get formChanged {
    if (reStickersList.length != stickersList.length) {
      return true;
    }
    for (var i = 0; i < stickersList.length; i++) {
      if (reStickersList[i].name != stickersList[i].name ||
          reStickersList[i].avatar != stickersList[i].avatar) {
        return true;
      }
    }
    return false;
  }

  // 取消重置数据
  Future<void> _onReset() async {
    await getStickers();
    checkFormChanged();
  }

  // 确认提交
  Future<void> _onConfirm() async {
    final bool _bool = stickersList
        .map((e) {
          return e.toJson();
        })
        .toList()
        .any((e) => e['name'] == '');
    if (_bool) {
      showToast('请输入名称'.tr);
      return;
    }
    await postStickers();
  }

  // 上传到服务器
  Future postStickers() async {
    await StickerUtil.instance
        .setStickers(widget.guildId, stickers: stickersList, onSuccess: () {
      reStickersList =
          stickersList.map((e) => StickerBean.fromMap(e.toJson())).toList();
      checkFormChanged();
    }, onError: () {
      showToast('上传失败'.tr);
    });
  }

  Future getStickers() async {
    final res = await StickerApi.getStickers(widget.guildId);
    setState(() {
      stickersList = res;
      reStickersList = res.map((ele) {
        return StickerBean.fromMap(ele.toJson());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scrollbar(
      child: SingleChildScrollView(
        child: Column(
          children: [
            headerEmoNav(),
            if (stickersList.isNotEmpty) tipChildren(),
            if (stickersList.isEmpty && reStickersList.isEmpty)
              Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: emptyWidget(theme)),
            if (stickersList.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.only(left: 56, top: 24, bottom: 13),
                    child: Text(
                      '表情'.tr,
                      style: const TextStyle(
                          color: Color(0xFF8F959E), fontSize: 12),
                    ),
                  ),
                  const SizedBox(
                    width: 80,
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 24, bottom: 13),
                    child: Text(
                      '名称'.tr,
                      style: const TextStyle(
                          color: Color(0xFF8F959E), fontSize: 12),
                    ),
                  )
                ],
              ),
              dragListWidget(theme, stickersList),
              const SizedBox(height: 100),
            ]
          ],
        ),
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
        ],
      ),
    );
  }

  Widget headerEmoNav() {
    return Row(children: [
      SizedBox(
        width: 514,
        child: Text(
            '添加最多100个表情到该服务器，作为服务器专用表情，表情名称在1-6个字符之间，默认取第一个，添加的表情缩略图所为整套表情的角标，建议上传240*240像素的图片'
                .tr,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8F959E),
            )),
      ),
      GestureDetector(
        onTap: () async {
          final bool _formChanged = formChanged;

          /// 编辑表情包禁止上传
          if (_formChanged && isEditing) {
            return;
          }
          final List originFiles = await pickermoreimage.ImagePicker.pickFile2(
              accept: 'image/*,video/*', multiple: true);
          final uploadFiles = originFiles
              .where((element) => element.size < 1024 * 1024 * 8)
              .toList();
          final bool overFileSize = uploadFiles.length != originFiles.length;
          final res = await Future.wait(originFiles.map(webUtil.getAssetInfo));
          if (overFileSize) {
            showToast('只能上传大小小于8m的文件'.tr);
            return;
          }
          if (res.length > 9) {
            showToast('每次最多只能上传9张图片'.tr);
            return;
          }
          if (stickersList.length + res.length > 100) {
            // showToast('最多只能选择${100 - stickersList.length}个表情');
            showToast('最多只能选择100个表情'.tr);
            return;
          }

          await Future.wait(
            res.map(
              (asset) async {
                Uint8List uploadFileBytes;
                uploadFileBytes =
                    await PickedFile(asset.filePath).readAsBytes();
                String url;
                try {
                  // url = await uploadFileIfNotExist(
                  //     bytes: uploadFileBytes,
                  //     filename: asset.name,
                  //     fileType: "image");
                  url = await CosFileUploadQueue.instance
                      .onceForBytes(uploadFileBytes, CosUploadFileType.image);
                  final emoIndex = stickersList.length + 1;
                  stickersList.add(StickerBean(
                      url, '表情%s'.trArgs([emoIndex.toString()]),
                      width: asset.originalWidth,
                      height: asset.originalHeight));
                } on Exception catch (e) {
                  logger.severe('图片上传失败', e?.toString() ?? '');
                }
              },
            ),
          );

          setState(() {
            stickersList = stickersList;
          });
          unawaited(postStickers());
        },
        child: Container(
          height: 32,
          width: 100,
          margin: const EdgeInsets.only(left: 40),
          decoration: BoxDecoration(
              color: const Color(0xFF6179F2),
              borderRadius: BorderRadius.circular(4)),
          alignment: Alignment.center,
          child: Text(
            '上传表情'.tr,
            style: const TextStyle(fontSize: 14, color: Color(0xFFFFFFFF)),
          ),
        ),
      )
    ]);
  }

  Widget tipChildren() {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 24),
      width: double.maxFinite,
      child: Text(
        '已上传表情'.tr,
        style: const TextStyle(color: Color(0xFF1F2125), fontSize: 14),
      ),
    );
  }

  Widget dragListWidget(ThemeData theme, List<StickerBean> stickers) {
    return ReorderableColumn(
      scrollController: controller,
      needsLongPressDraggable: false,
      onReorder: (oldIndex, newIndex) async {
        final old = stickers.removeAt(oldIndex);
        if (newIndex > stickers.length) {
          stickers.add(old);
        } else {
          stickers.insert(newIndex, old);
        }

        setState(() {
          stickersList = stickers;
        });
        checkFormChanged();
//        await postStickers();
      },
      children: List.generate(stickers.length, (index) {
        return emoItem(index, theme, stickers[index]);
      }),
    );
  }

  Widget emoItem(int index, ThemeData theme, StickerBean sticker) {
    final color1 = darkTheme.textTheme.bodyText1.color;
    final dividerColor = const Color(0xFFDEE0E3).withOpacity(0.5);
    Border border;
    if (index == 0) {
      border = Border(
          top: BorderSide(color: dividerColor),
          bottom: BorderSide(color: dividerColor));
    } else {
      border = Border(bottom: BorderSide(color: dividerColor));
    }
    return WebHoverButton(
      key: ValueKey(index),
      onTap: () {},
      border: border,
      hoverColor: const Color(0xFFDEE0E3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      builder: (isHover, context) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: isHover ? 1 : 0,
              child: SizedBox(
                  // width: 100,
                  child: Icon(
                IconFont.buffChannelMoveEditLarge,
                size: 24,
                color: color1,
              )),
            ),
            const SizedBox(
              width: 16,
            ),
            emoPic(sticker),
            const SizedBox(
              width: 48,
            ),
            Expanded(child: stickerNameWidget(sticker, index, isHover)),
            Opacity(
              opacity: isHover ? 1 : 0,
              child: SizedBox(
                width: 100,
                child: GestureDetector(
                  onTap: () async {
                    stickersList.removeAt(index);
                    setState(() {
                      stickersList = stickersList;
                    });
                    checkFormChanged();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: const Icon(
                      IconFont.buffCommonDeleteRed,
                      size: 20,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 1,
              decoration: const BoxDecoration(
                color: Color(0xFFDEE0E3),
              ),
            )
          ],
        );
      },
    );
  }

  Widget emoPic(StickerBean sticker) {
    final url = spliceGif(sticker.avatar);
    return GestureDetector(
      child: ContainerImage(
        url,
        fit: BoxFit.cover,
        radius: 4,
        width: 40,
      ),
    );
  }

  Widget stickerNameWidget(StickerBean sticker, int index, bool isHover) {
    if (isHover) {
      return WebCustomInputBox(
        controller: TextEditingController(text: sticker.name ?? ''),
        fillColor: const Color(0xFFFFFFFF),
        hintText: '请输入表情名称'.tr,
        maxLength: 6,
        onChange: (val) {
          sticker.name = val.trim();
          isEditing = true;
          checkFormChanged();
        },
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(left: 12),
        child: Text(
          sticker.name ?? '',
          style: const TextStyle(fontSize: 17, color: Color(0xff1F2125)),
        ),
      );
    }
  }
}
