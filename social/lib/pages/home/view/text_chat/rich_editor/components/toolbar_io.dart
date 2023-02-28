import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/pages/home/view/bottom_bar/keyboard_container2.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/abstract_rich_text_factory.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_tun.dart';
import 'package:tun_editor/controller.dart';
import 'package:tun_editor/tun_editor_toolbar.dart';

import '../../../../../../icon_font.dart';

final toolbarCallback =
    AbstractRichTextFactory.instance.createToolbarCallback();

class RichTunEditorToolbar extends ToolbarBase {
  final BuildContext context;

  final RichTunEditorModel model;

  RichTunEditorToolbar(this.context, this.model);

  @override
  ToolbarBase editorToolbar(BuildContext context) =>
      RichTunEditorToolbar(context, model);

  @override
  _RichTunEditorToolbarState createState() => _RichTunEditorToolbarState();
}

class _RichTunEditorToolbarState extends State<RichTunEditorToolbar> {
  TunEditorController get editorController => _model.editorController;

  ValueNotifier<bool> get isEditorFocus => _model.isEditorFocus;

  ValueNotifier<bool> get canSend => _model.canSend;
  SubToolbar _showingSubToolbar = SubToolbar.none;

  // bool _readOnly = false;
  RichTunEditorModel _model;

  @override
  void initState() {
    // _model = Provider.of<RichTunEditorModel>(context, listen: false);
    _model = Get.find<RichTunEditorModel>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<bool>(
            valueListenable: _model.isEditorFocus,
            builder: (context, hasFocus, child) {
              return TunEditorToolbar(
                controller: _model.editorController,
                showingSubToolbar: _showingSubToolbar,
                disabledMenu: hasFocus ? [] : List.from(defaultToolbarMenu),
                menu: _model.toolbarItems,
                onSubToolbarChange: (subToolbar) {
                  if (subToolbar == SubToolbar.at) {
                    toolbarCallback.showAtList(context, _model);
                  } else if (subToolbar == SubToolbar.channel) {
                    toolbarCallback.showChannelList(context, _model);
                  } else if (subToolbar == SubToolbar.image) {
                    toolbarCallback.pickImages(context, _model);
                    editorController.blur();
                  } else if (subToolbar == SubToolbar.emoji) {
                    toolbarCallback.showEmojiTab(context, _model);
                    editorController.blur();
                  }

                  setState(() {
                    _showingSubToolbar = subToolbar;
                    // _readOnly = _showingSubToolbar == SubToolbar.emoji;
                  });
                },
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // buildTextTypeToolbar(),
                        ValueListenableBuilder<bool>(
                          valueListenable: canSend,
                          builder: (context, canSend, child) {
                            return GestureDetector(
                              onTap: !canSend ? null : _model.onSend,
                              child: Container(
                                width: 44,
                                height: 36,
                                padding: const EdgeInsets.fromLTRB(11, 6, 9, 6),
                                decoration: ShapeDecoration(
                                    color: canSend
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context)
                                            .scaffoldBackgroundColor,
                                    shape: const StadiumBorder()),
                                child: Icon(
                                  IconFont.buffTabSend,
                                  color: canSend
                                      ? Colors.white
                                      : const Color(0xFFC2C5CC),
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
        _buildKeyboardContainer(_model),
      ],
    );
  }
}

Widget _buildKeyboardContainer(RichTunEditorModel model) {
  return ValueListenableBuilder(
      valueListenable: model.tabIndex,
      builder: (context, tabIndex, child) {
        Widget child;
        switch (tabIndex) {
          case ToolbarMenu.emoji:
            child = AbstractRichTextFactory.instance
                .createRichEditorEmoji(model.editorController);
            break;
          default:
            child = const SizedBox();
        }
        return KeyboardContainer2(
          expand: model.expand,
          childHeight: 300,
          titleFocusNode: model.titleFocusNode,
          editorFocusNode: model.editorFocusNode,
          editorController: model.editorController,
          builder: (context) {
            return child;
          },
        );
      });
}

typedef GestureContextCallback = void Function(
    BuildContext, RichEditorModelBase);

class RichEditorToolbarItem {
  final IconData icon;
  final GestureContextCallback onPressed;

  const RichEditorToolbarItem({@required this.icon, @required this.onPressed});
}

// Future<void> showAtList(BuildContext context, RichEditorModel model,
//     {bool fromInput = false}) async {
//   FocusScope.of(context).unfocus();
//   model.tabIndex.value = null;
//   model.expand.value = KeyboardStatus.hide;
//   final controller = model.editorController;
//   final List res = await Routes.pushRichEditorAtListPage(context);
//   if (res == null || res.isEmpty) {
//     // model.editorFocusNode.requestFocus();
//     return;
//   }
//   if (fromInput) {
//     final d = Delta()
//       ..retain(controller.selection.end - 1)
//       ..delete(1);
//     controller.compose(d);
//   }
//   res.forEach((e) {
//     String atId = '';
//     String atMark = '';
//     if (e is Role) {
//       atId = TextEntity.getAtString(e.id, true);
//       atMark = '@${e.name}';
//     } else if (e is UserInfo) {
//       atId = TextEntity.getAtString(e.userId, false);
//       atMark = '@${e.nickname}';
//     }
//     final start = controller.selection.end;
//     final offset = start + atMark.length;
//     final isEmbed = RichEditorUtils.isEmbedEnd(
//         controller.document.toDelta(), controller.selection.end);
//     final d = Delta()..retain(controller.selection.end);
//     if (isEmbed) d.insert('\n');
//     d.insert(atMark, {'at': atId});
//     controller
//       ..document.compose(d, ChangeSource.remote)
//       ..updateSelection(
//           TextSelection.collapsed(offset: offset + (isEmbed ? 1 : 0)));
//   });
//   // 插入空格
//   controller
//     ..document.insert(controller.selection.end, ' ')
//     ..updateSelection(
//         TextSelection.collapsed(offset: controller.selection.end + 1));
//   // 切换普通样式
//   controller.formatText(
//       controller.selection.end - 1, 1, NotusAttribute.at.unset);
// }

// Future<void> showChannelList(
//     BuildContext context, RichEditorModel model) async {
//   FocusScope.of(context).unfocus();
//   model.tabIndex.value = null;
//   model.expand.value = KeyboardStatus.hide;
//
//   final controller = model.editorController;
//   final ChatChannel channel =
//       await Routes.pushRichEditorChannelListPage(context);
//   if (channel == null) {
//     // model.editorFocusNode.requestFocus();
//     return;
//   }
//   final d1 = Delta()
//     ..retain(controller.selection.end - 1)
//     ..delete(1);
//   controller.compose(d1);
//   // }
//   final String channelId = TextEntity.getChannelLinkString(channel.id);
//   final String channelMark = '#${channel.name}';
//   final start = controller.selection.end;
//   final offset = start + channelMark.length;
//   final isEmbed = RichEditorUtils.isEmbedEnd(
//       controller.document.toDelta(), controller.selection.end);
//   final d = Delta()..retain(controller.selection.end);
//   if (isEmbed) d.insert('\n');
//   d.insert(channelMark, {'channel': channelId});
//   controller
//     ..document.compose(d, ChangeSource.remote)
//     ..updateSelection(
//         TextSelection.collapsed(offset: offset + (isEmbed ? 1 : 0)));
//   // 插入空格
//   controller
//     ..document.insert(controller.selection.end, ' ')
//     ..updateSelection(
//         TextSelection.collapsed(offset: controller.selection.end + 1));
//   // 切换普通样式
//   controller.formatText(
//       controller.sepickImageslection.end - 1, 1, NotusAttribute.channel.unset);
// }

// void showEmojiTab(BuildContext context, RichEditorModel model) {
//   model.editorFocusNode.unfocus();
//   model.expand.value = KeyboardStatus.extend_keyboard;
//   model.tabIndex.value = toolbarType.emoji;
// }

// Future pickImages(BuildContext context, RichEditorModel model) async {
//   try {
//     model.editorFocusNode.unfocus();
//     final controller = model.editorController;
//     final mediaNum = controller.document
//         .toDelta()
//         .toList()
//         .where((element) => element.isImage || element.isVideo)
//         .length;
//     if (model.maxMediaNum - mediaNum <= 0) {
//       showToast('最多只能上传$mediaNum个文件');
//       return;
//     }
//     model.tabIndex.value = null;
//     model.expand.value = KeyboardStatus.hide;
//     final maxNum = min(9, model.maxMediaNum - mediaNum);
//     final result = await MultiImagePicker.pickImages(
//         maxImages: maxNum,
//         thumb: false,
//         doneButtonText: '确定'.tr,
//         cupertinoOptions: CupertinoOptions(
//             takePhotoIcon: "chat",
//             selectionStrokeColor:
//                 "#${Theme.of(context).primaryColor.value.toRadixString(16)}",
//             selectionFillColor:
//                 "#${Theme.of(context).primaryColor.value.toRadixString(16)}"),
//         materialOptions: MaterialOptions(
//           allViewTitle: "所有图片".tr,
//           selectCircleStrokeColor:
//               "#${Theme.of(context).primaryColor.value.toRadixString(16)}",
//         ));
//     final List<String> identifiers = [];
//     for (final item in result['identifiers']) {
//       identifiers.add(item.toString());
//     }
//     // await delay(() => {}, 1000);
//     // model.editorFocusNode.requestFocus();
//     unawaited(
//       insertImage(context, (result['identifiers'] as List).cast<String>(),
//           controller, !(result['thumb'] ?? false), model),
//     );
//   } on Exception catch (e) {
//     if (e is PlatformException) {
//       if (e.code == "PERMISSION_PERMANENTLY_DENIED") {
//         await checkSystemPermissions(
//           context: context,
//           permissions: [
//             if (UniversalPlatform.isIOS) Permission.photos,
//             if (UniversalPlatform.isAndroid) Permission.storage,
//           ],
//         );
//       } else if (e.code == "CANCELLED") {
//         // model.editorFocusNode.requestFocus();
//       }
//     }
//   }
// }
//
// Future<void> insertImage(BuildContext context, List<String> assets,
//     ZefyrController controller, bool isOrigin, RichEditorModel model) async {
//   Loading.show(context);
//   List<Asset> assetList;
//   List<String> fileSizeList;
//   final List<String> bigFileList = [];
//   try {
//     assetList = await MultiImagePicker.requestMediaData(
//         thumb: !isOrigin, selectedAssets: assets);
//     fileSizeList = await Future.wait(
//         assetList.map((e) => MultiImagePicker.requestFileSize(e.identifier)));
//     Loading.hide();
//   } catch (e) {
//     Logger.error('富文本获取媒体失败', e);
//     Loading.hide();
//   }
//   for (int i = 0; i < assetList.length; i++) {
//     final e = assetList[i];
//     final fileSize = double.parse(fileSizeList[i] ?? '0');
//     if (fileSize > 1024 * 1024 * 300) {
//       bigFileList.add(e.name);
//       continue;
//     }
//     final size = await _getMediaSize(e);
//     if (e?.filePath != null && e.fileType.startsWith('image/')) {
//       controller.document.insert(
//           controller.selection.end,
//           BlockEmbed('image', data: {
//             'source': e.name,
//             'width': size.item1,
//             'height': size.item2
//           }));
//     }
//
//     if (e?.filePath != null && e.fileType.startsWith('video')) {
//       controller.document.insert(
//           controller.selection.end,
//           BlockEmbed('video', data: {
//             'source': e.name,
//             'width': size.item1,
//             'height': size.item2,
//             'fileType': e.fileType,
//             'duration': e.duration == null ? 0 : e.duration.toInt(),
//             'thumbUrl': e.thumbName,
//           }));
//     }
//
//     controller.updateSelection(
//         TextSelection.collapsed(offset: controller.selection.end + 2));
//     // 最后一张换行
//
//     if (e == assetList.last) {
//       controller.document.insert(controller.selection.end, '\n');
//       controller.updateSelection(
//         TextSelection.collapsed(offset: controller.selection.end + 1),
//         source: ChangeSource.local,
//       );
//     }
//   }
//   if (bigFileList.isNotEmpty) {
//     showToast('文件: ${bigFileList.join('、'.tr)} 超出大小限制');
//   }
// }
