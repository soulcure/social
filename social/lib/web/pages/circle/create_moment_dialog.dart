import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_io.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/abstract_rich_text_factory.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/web/utils/confirm_dialog/confirm_dialog.dart';
import 'package:oktoast/oktoast.dart';
import 'package:tuple/tuple.dart';

class TopicItem {
  final String id;
  final String name;

  const TopicItem(this.id, this.name);
}

class CreateMomentDialog extends StatefulWidget {
  final String guildId;
  final String channelId;
  final List<CircleTopicDataModel> optionTopics;
  final CircleTopicDataModel defaultTopic;

  const CreateMomentDialog(this.guildId, this.channelId,
      {this.optionTopics = const [], this.defaultTopic});

  @override
  CreateMomentDialogState createState() => CreateMomentDialogState();
}

class CreateMomentDialogState extends State<CreateMomentDialog> {
  ValueNotifier<String> _selTopic;
  ValueNotifier<bool> _disableConfirm;
  ValueNotifier<bool> _confirmLoading;
  RichEditorModel _model;
  bool _needTopic;

  @override
  void initState() {
    super.initState();
    // 必须先过滤掉没有发布权限的话题
    _filterNoPermissionTopic();

    _needTopic = widget.optionTopics
        .where((element) => element.type != CircleTopicType.unknown)
        .isNotEmpty;
    _selTopic = ValueNotifier(widget.defaultTopic?.topicId);
    _confirmLoading = ValueNotifier(false);
    _disableConfirm = ValueNotifier(true);
    _model = AbstractRichTextFactory.instance.createEditorModel(
      channel: ChatChannel(
        guildId: widget.guildId,
        id: widget.channelId,
        type: ChatChannelType.guildCircle,
      ),
      titlePlaceholder: '填写标题可能会获得很多赞哦~'.tr,
      editorPlaceholder: '分享你的新鲜事'.tr,
      titleLength: 30,
      showScrollbar: true,
      optionTopics: widget.optionTopics,
    );

    _onDocumentChange();
  }

  /// - 过滤掉没有发布权限的话题
  void _filterNoPermissionTopic() {
    if (PermissionUtils.isGuildOwner()) {
      return;
    }
    final GuildPermission gp = PermissionModel.getPermission(widget.guildId);
    if (gp == null) {
      return;
    }

    final newTopics = widget.optionTopics.where((element) {
      return PermissionUtils.oneOf(gp, [Permission.CIRCLE_POST],
          channelId: element.topicId);
    }).toList();
    widget.optionTopics.clear();
    widget.optionTopics.addAll(newTopics);
  }

  void _onDocumentChange() {
    _model.editorController.document.changes.listen((event) {
      setDisableConfirm();

      if (event.item3 == ChangeSource.REMOTE) return;
      final _controller = _model.editorController;
      // if (!_isEditMode) _saveStream.add('');
      final changeList = event.item2.toList();
      bool isAt = false;
      bool isChannel = false;
      try {
        isAt = Document.fromDelta(event.item1)
            .collectStyle(max(_controller.selection.end, 0), 0)
            .containsKey(AtAttribute(null).key);
        isChannel = Document.fromDelta(event.item1)
            .collectStyle(max(_controller.selection.end, 0), 0)
            .containsKey(ChannelAttribute(null).key);
      } catch (e) {
        // logger.severe('富文本 collectStyle', e);
      }
      if (changeList.any((element) => element.isDelete) &&
          (isAt || isChannel)) {
        onDelete(event);
      } else if (changeList.any((element) => element.isInsert)) {
        onInsert(event);
      }
    });
  }

  void onDelete(Tuple3<Delta, Delta, ChangeSource> event) {
    final _controller = _model.editorController;

    final changeList = event.item2.toList();
    final delPosition = changeList.first.length;
    final int oIndex =
        RichEditorUtils.getOperationIndex(event.item1, delPosition);
    final lenBeforeOperation =
        RichEditorUtils.getLenBeforeOperation(event.item1, oIndex);
    if (oIndex != -1) {
      final Delta change = Delta()
        ..retain(lenBeforeOperation)
        ..delete(event.item1.elementAt(oIndex).length - 1);
      final nextOperation =
          RichEditorUtils.getNextOperation(event.item1, oIndex);
      // 是否嵌入节点
      final isEmbedObject = nextOperation != null && nextOperation.isEmbed;
      final isLast = RichEditorUtils.isLastOperation(event.item1, oIndex);
      // 特殊情况需插入换行符
      if (isLast || isEmbedObject) {
        change.insert('\n');
      }
      _controller.document.compose(change, ChangeSource.REMOTE);
      _controller.updateSelection(
          TextSelection.collapsed(offset: lenBeforeOperation),
          ChangeSource.LOCAL);
    }
  }

  void onInsert(Tuple3<Delta, Delta, ChangeSource> event) {
    final _controller = _model.editorController;

    final changeList = event.item2.toList();
    final after = _controller.document.toDelta();
    final oIndex =
        RichEditorUtils.getOperationIndex(after, _controller.selection.end - 1);
    if (oIndex == -1) return;
    // 在@和#中间插入字符
    final current = after.elementAt(oIndex);
    if (current.isAt || current.isChannel) {
      final start = RichEditorUtils.getLenBeforeOperation(after, oIndex);
      _controller.formatText(start, after.elementAt(oIndex).length,
          current.isAt ? AtAttribute(null) : ChannelAttribute(null));
      return;
    }
    final o = changeList.firstWhere((element) => element.isInsert,
        orElse: () => null);
    if (o?.value == '@') {
      toolbarCallback.showAtList(context, _model, fromInput: true);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    _disableConfirm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_model == null) return const Center(child: CircularProgressIndicator());
    return WebConfirmDialog2(
      title: '发布动态'.tr,
      height: (Get.window.physicalSize.height / Get.pixelRatio * 0.9)
          .floorToDouble(),
      disableConfirm: _disableConfirm,
      showSeparator: true,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child:
                    AbstractRichTextFactory.instance.createRichEditor(_model),
              ),
              AbstractRichTextFactory.instance
                  .createEditorToolbar(context, _model),
              // 2.0.0版本后有个现象，页面只有一个scrollview时富文本上下左右键updateEditingValue无法收到回调，
              // 可能是焦点处理有问题导致，0或者两个以上scrollview是正常的，故加多一个scrollview暂时解决这个问题
              // const SizedBox(
              //   height: 0,
              //   child: SingleChildScrollView(
              //     child: SizedBox(),
              //   ),
              // ),
              _buildTopicSelector(),
              divider,
              _footer(),
            ],
          ),
        ],
      ),
      hideFooter: true,
      // onConfirm: _sendDoc,
    );
  }

  Future<void> _sendDoc() async {
    final editorController = _model.editorController;
    final title = _model.titleController?.text ?? '';
    try {
      final str = editorController.document
          .toPlainText()
          .replaceAll(RegExp(r"\n+| |\u200B"), '');
      final deltaList = editorController.document.toDelta().toList();
      final imgNum = deltaList.where((element) => element.isImage).length;
      final videoNum = deltaList.where((element) => element.isVideo).length;

      if (imgNum + videoNum > _model.maxMediaNum) {
        showToast('最多只能发%s个文件'.trArgs([_model.maxMediaNum.toString()]));
        return;
      }
      if (str.runes.length > 5000) {
        showToast('内容长度超出限制'.tr);
        return;
      }

      Loading.show(context);
      FocusScope.of(context).unfocus();
      // await RichEditorUtils.uploadFileInDoc(editorController.document);
      bool uploadFlag = true;
      String textAssets = '';
      for (final d in deltaList) {
        if (d.isImage || d.isVideo) {
          final source =
              RichEditorUtils.getEmbedAttribute(d, 'source') as String;
          final isLocalAsset = source.startsWith('blob:');
          if (!isLocalAsset) continue;
          final uploadRes = _model.getUploadCache(source);
          if (uploadRes.first.contains('reject')) {
            showToast('内容包含违规视频或图片'.tr);
            uploadFlag = false;
            break;
          } else if (uploadRes == null) {
            showToast('请先上传文件'.tr);
            uploadFlag = false;
            break;
          } else {
            if (d.isImage) {
              d.value['source'] = uploadRes.first;
            } else {
              d.value['source'] = uploadRes.first;
              d.value['thumbUrl'] = uploadRes[1];
            }
          }
        } else {
          textAssets += d.value?.toString()?.trim() ?? '';
        }
      }

      if (textAssets.isNotEmpty) {
        const textChannel = TextChannelType.FB_CIRCLE_POST_TEXT;
        final textRes = await CheckUtil.startCheck(
            TextCheckItem(title + textAssets, textChannel,
                checkType: CheckType.circle),
            toastError: false);
        if (!textRes) {
          showToast(defaultErrorMessage);
          Loading.hide();
          throw CheckTypeException(defaultErrorMessage);
        }
      }

      if (!uploadFlag) return;

      /// 富文本对象
      final richTextEntity = RichTextEntity(
          title: title,
          document: Document.fromDelta(editorController.document.toDelta()));

      ///保存最近艾特过的用户
      if (richTextEntity.mentions?.item2 != null) {
        ChannelUtil.instance
            .addGuildAtUserId(widget.guildId, richTextEntity.mentions.item2);
      }
      await CircleApi.createCircle(
          widget.guildId, widget.channelId, _selTopic.value, null,
          title: _model.titleController.text.trim(),
          contentV2: jsonEncode(editorController.document.toDelta()),
          postType: CirclePostDataType.article,
          mentions: richTextEntity.mentions.item2);
      // 发送成功返回true
      Routes.pop<List<String>>(context, [_selTopic.value]);
    } catch (e) {
      logger.severe(e);
      Loading.hide();
    } finally {
      Loading.hide();
    }
  }

  Widget _buildTopicSelector() {
    final topics = widget.optionTopics;
    Widget child;
    if (topics.isEmpty) {
      child = Center(
          child: Text('暂无话题，请联系管理员创建'.tr,
              style: TextStyle(
                  color: CustomColor(context).disableColor, fontSize: 14)));
    }
    child = Container(
      constraints: const BoxConstraints(maxHeight: 200),
      width: double.infinity,
      height: 100,
      padding: const EdgeInsets.fromLTRB(17, 5, 17, 17),
      child: Scrollbar(
        child: SingleChildScrollView(
          controller: ScrollController(),
          child: ValueListenableBuilder<String>(
              valueListenable: _selTopic,
              builder: (context, selTopic, child) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: topics.map((e) {
                    final isSelected = selTopic == e.topicId;
                    return Material(
                      child: ChoiceChip(
                        pressElevation: 1,
                        selectedColor: primaryColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(14))),
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        label: Text(
                          e.topicName,
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).textTheme.bodyText2.color,
                              fontSize: 14),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          _selTopic.value = e.topicId;
                          setDisableConfirm();
                        },
                      ),
                    );
                  }).toList(),
                );
              }),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: RichText(
            text: TextSpan(children: [
              const TextSpan(
                text: '*',
                style: TextStyle(color: DefaultTheme.dangerColor),
              ),
              TextSpan(
                text: '选择话题（必选）'.tr,
                style: Theme.of(context)
                    .textTheme
                    .bodyText2
                    .copyWith(fontSize: 16, fontWeight: FontWeight.normal),
              ),
            ]),
          ),
        ),
        child
      ],
    );
  }

  void setDisableConfirm() {
    final isContentE = _model.editorController.document.isContentEmpty;

    final isContentEmpty = isContentE ?? true;
    _disableConfirm.value = isContentEmpty ||
        (!isContentEmpty && _needTopic && _selTopic.value == null);
  }

  Widget _footer() {
    final _theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(
            width: 88,
            height: 32,
            child: ValueListenableBuilder<bool>(
                valueListenable: _disableConfirm,
                builder: (context, disableConfirm, child) {
                  return TextButton(
                      onPressed: disableConfirm
                          ? null
                          : () async {
                                try {
                                  _confirmLoading.value = true;
                                  await _sendDoc();
                                  _confirmLoading.value = false;
                                } catch (e) {
                                  _confirmLoading.value = false;
                                }
                              } ??
                              () => Navigator.of(context).pop(true),
                      child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: disableConfirm
                                ? const Color(0xFF6179f2).withOpacity(0.4)
                                : _theme.primaryColor,
                          ),
                          alignment: Alignment.center,
                          child: ValueListenableBuilder(
                            valueListenable: _confirmLoading,
                            builder: (context, loading, child) {
                              return loading
                                  ? const SizedBox(
                                      height: 15,
                                      width: 15,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          backgroundColor: Colors.white),
                                    )
                                  : Text(
                                      '确定'.tr,
                                      style: _theme.textTheme.bodyText2
                                          .copyWith(color: Colors.white),
                                    );
                            },
                          )));
                }),
          ),
          sizeWidth16,
          SizedBox(
            width: 88,
            height: 32,
            child: TextButton(
                onPressed: Get.back,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: Theme.of(context).dividerTheme.color),
                    color: _theme.backgroundColor,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '取消'.tr,
                    style: _theme.textTheme.bodyText2,
                  ),
                )),
          ),
        ],
      ),
    );
  }
}
