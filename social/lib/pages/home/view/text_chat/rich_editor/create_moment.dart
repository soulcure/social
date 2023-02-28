import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/circle/content/circle_post_image_item.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_io.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/abstract_rich_text_factory.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/topic_tag_text.dart';
import 'package:im/widgets/user_info/realtime_nick_name.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import 'package:tun_editor/tun_editor_toolbar.dart';
import 'package:tuple/tuple.dart';

import 'model/editor_model_tun.dart';

class TopicItem {
  final String id;
  final String name;

  const TopicItem(this.id, this.name);
}

final List<ToolbarMenu> circleToolbarMenu = [
  ToolbarMenu.at,
  ToolbarMenu.channel,
  ToolbarMenu.emoji,
  //
  ToolbarMenu.textType,
  ToolbarMenu.textTypeHeadline1,
  ToolbarMenu.textTypeHeadline2,
  ToolbarMenu.textTypeHeadline3,
  ToolbarMenu.textTypeListBullet,
  ToolbarMenu.textTypeListOrdered,
  ToolbarMenu.textTypeDivider,
  ToolbarMenu.textTypeQuote,
  ToolbarMenu.textTypeCodeBlock,
  //
  ToolbarMenu.textStyle,
  ToolbarMenu.textStyleBold,
  ToolbarMenu.textStyleItalic,
  ToolbarMenu.textStyleUnderline,
  ToolbarMenu.textStyleStrikeThrough,
  //
  ToolbarMenu.link
];

// 圈子新增和编辑页面
class CreateMomentPage extends StatefulWidget {
  final String guildId;
  final String channelId;
  final CircleTopicDataModel defaultTopic;
  final List<CircleTopicDataModel> optionTopics;
  final CirclePostInfoDataModel circleDraft;
  final List<CirclePostImageItem> assetList;

  const CreateMomentPage(
    this.guildId,
    this.channelId, {
    this.defaultTopic,
    this.optionTopics = const [],
    this.circleDraft,
    this.assetList = const [],
  });

  @override
  CreateMomentPageState createState() => CreateMomentPageState();
}

class CreateMomentPageState extends State<CreateMomentPage> {
  ValueNotifier<String> _selTopic;
  RichTunEditorModel _model;
  bool _needTopic;
  BehaviorSubject<String> _saveStream;
  StreamSubscription<String> _saveSubscription;
  BehaviorSubject<String> _showAtListStream;
  BehaviorSubject<String> _showChannelListStream;

  //记录进入该页面时的时间戳
  int _timeMillis;

  // 编辑模式需传postId
  bool _isEditMode;

  @override
  void initState() {
    super.initState();

    _timeMillis = DateTime.now().millisecondsSinceEpoch;

    _isEditMode = widget.circleDraft != null;

    final circleDraftMap = _loadDocument();

    _filterNoPermissionTopic();

    _needTopic = widget.optionTopics
        .where((element) => element.type != CircleTopicType.unknown)
        .isNotEmpty;

    final assetList = (widget.assetList == null || widget.assetList.isEmpty)
        ? circleDraftMap['assets']
        : widget.assetList;

    //文章
    _model = AbstractRichTextFactory.instance.createEditorModel(
      channel: ChatChannel(
        guildId: widget.guildId,
        id: widget.channelId,
        type: ChatChannelType.guildCircle,
      ),
      defaultTitle: circleDraftMap['title'],
      defaultDoc: circleDraftMap['content'],
      titlePlaceholder: '填写标题可能会获得很多赞哦~'.tr,
      editorPlaceholder: '分享你的新鲜事'.tr,
      titleLength: 30,
      // selTopics: [widget.defaultContent],
      optionTopics: widget.optionTopics,
      onSend: _sendDoc,
      assetList: assetList ?? [],
      toolbarItems: circleToolbarMenu,
    );

    if (circleDraftMap['mentionList'] != null)
      _model.mentionList = circleDraftMap['mentionList'];
    _model.requestMediaData();

    Get.put(_model);
    _showAtListStream = BehaviorSubject<String>()
      ..debounceTime(const Duration(milliseconds: 200)).listen((data) {
        toolbarCallback.showAtList(context, _model, fromInput: true);
      });
    _showChannelListStream = BehaviorSubject<String>()
      ..debounceTime(const Duration(milliseconds: 200)).listen((data) {
        toolbarCallback.showChannelList(context, _model, fromInput: true);
      });

    if (!_isEditMode) {
      _saveStream = BehaviorSubject<String>();
      _saveSubscription = _saveStream
          .debounceTime(const Duration(milliseconds: 500))
          .listen((data) {
        _saveDoc();
      });

      _onDocumentChange();
      _model.titleController.addListener(() {
        _saveStream.add('');
      });
    } else {
      _onDocumentChange();
    }
  }

  /// - 过滤掉没有发布权限的话题
  void _filterNoPermissionTopic() {
    if (PermissionUtils.isGuildOwner()) {
      return;
    }
    final GuildPermission gp = PermissionModel.getPermission(
        ChatTargetsModel.instance?.selectedChatTarget?.id);
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
      if (event.item3 == ChangeSource.REMOTE) return;
      final _controller = _model.editorController;
      if (!_isEditMode) _saveStream.add('');
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
      _model.updateArticleUser();
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
    final changeList = event.item2.toList();
    final o = changeList.firstWhere((element) => element.isInsert,
        orElse: () => null);
    if (o?.value == '@') {
      _showAtListStream.add('');
    } else if (o?.value == '#' && !GlobalState.isDmChannel) {
      _showChannelListStream.add('');
    }
  }

  @override
  void dispose() {
    if (!_isEditMode) _saveStream?.close();
    _showAtListStream?.close();
    _showChannelListStream?.close();
    _model.dispose();
    Get.delete<RichTunEditorModel>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_model == null) return const Center(child: CircularProgressIndicator());
    return WillPopScope(
      onWillPop: _onWillPop,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          _model.isEditMode.value = false;
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: appThemeData.backgroundColor,
          body: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder(
                    valueListenable: _model.isEditMode,
                    builder: (context, v, child) {
                      if (v) return sizedBox;
                      return Column(
                        children: [
                          CustomAppbar(
                            backgroundColor:
                                appThemeData.scaffoldBackgroundColor,
                            leadingIcon: IconFont.buffNavBarCloseItem,
                            leadingCallback: () async {
                              final res = await _onWillPop();
                              if (res) Get.back();
                            },
                          ),
                          // ResourceWidget()
                        ],
                      );
                    },
                  ),
                  AbstractRichTextFactory.instance.createRichEditor(_model),
                  GetBuilder<RichTunEditorModel>(
                      id: RichTunEditorModel.atListId,
                      builder: (controller) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: controller.showAtList
                                .map((e) => Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        color: appThemeData.primaryColor
                                            .withOpacity(0.1),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          RealtimeNickname(
                                            userId: e,
                                            prefix: "@",
                                            textScaleFactor: 1,
                                            showNameRule:
                                                ShowNameRule.remarkAndGuild,
                                            style: appThemeData
                                                .textTheme.bodyText2
                                                .copyWith(
                                                    color: appThemeData
                                                        .primaryColor),
                                            guildId: widget.guildId,
                                          ),
                                          if (controller.mentionList
                                              .contains(e)) ...[
                                            sizeWidth8,
                                            GestureDetector(
                                              onTap: () =>
                                                  controller.removeMention(e),
                                              child: Icon(
                                                IconFont.buffNavBarCloseItem,
                                                size: 14,
                                                color:
                                                    appThemeData.primaryColor,
                                              ),
                                            ),
                                          ]
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        );
                      }),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: SizedBox(
                      height: 28,
                      width: 85,
                      child: TextButton(
                        style: ButtonStyle(
                            padding: MaterialStateProperty.all(EdgeInsets.zero),
                            backgroundColor: MaterialStateProperty.all(
                                appThemeData.textTheme.headline2.color
                                    .withOpacity(0.1))),
                        onPressed: _model.appendMentionUser,
                        child: Text(
                          '@提醒谁看',
                          style: appThemeData.textTheme.bodyText2
                              .copyWith(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  divider,
                  _buildSelTopics(),
                  divider,
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        sizeWidth16,
                        Icon(
                          IconFont.buffCommonCheck,
                          color: appThemeData.primaryColor,
                          size: 16,
                        ),
                        sizeWidth4,
                        Text(
                          '发布后保存至相册',
                          style: appThemeData.textTheme.bodyText2
                              .copyWith(fontSize: 13),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AbstractRichTextFactory.instance
                    .createEditorToolbar(context, _model),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendDoc() async {
    if (_needTopic && _selTopic.value == null) {
      await _showTopicPopup();
      return;
    }
    final editorController = _model.editorController;
    final tempDoc = Document.fromDelta(editorController.document.toDelta());
    try {
      final str = tempDoc.toPlainText().replaceAll(RegExp(r"\n+| |\u200B"), '');
      if (str.runes.length > 5000) {
        showToast('内容长度超出限制'.tr);
        return;
      }

      if (!_isEditMode) _saveSubscription.pause();
      Loading.show(context);
      FocusScope.of(context).unfocus();
      _model.titleNativeController?.updateFocus(false);

      _saveDoc();
      Get.back();
      unawaited(CircleController.sendDynamic(
          timeMillis: _timeMillis,
          guildId: _model.channel.guildId,
          channelId: _model.channel.id));
    } catch (e, s) {
      logger.severe('圈子发送失败', e, s);
    } finally {
      Loading.hide();
    }
  }

  Document get defaultDoc =>
      Document.fromJson(jsonDecode(r'[{"insert":"\n"}]'));

  Map<String, dynamic> _loadDocument() {
    final circleDraft = Db.circleDraftBox.get(widget.channelId);
    // 非编辑模式和无草稿情况下, 返回默认初始化数据
    if (!_isEditMode && circleDraft == null) {
      _selTopic = ValueNotifier(widget.defaultTopic?.topicId);
      return {
        'title': '',
        'content': defaultDoc,
        'dynamicContentStr': '',
      };
    }

    String dynamicContentStr = '';
    String title = '';
    // 编辑模式
    if (_isEditMode) {
      final String selectedTopicId = widget.optionTopics
          .firstWhere(
              (element) => element.topicId == widget.circleDraft.topicId,
              orElse: () => null)
          ?.topicId;
      _selTopic = ValueNotifier(selectedTopicId);
      dynamicContentStr = widget.circleDraft.content ?? '';
      title = widget.circleDraft.title;
    } else {
      // 有缓存
      String selectedTopicId =
          circleDraft.topicId ?? widget.defaultTopic?.topicId;
      if (circleDraft.topicId != null) {
        selectedTopicId = widget.optionTopics
            .firstWhere((element) => element.topicId == circleDraft.topicId,
                orElse: () => null)
            ?.topicId;
      }
      _selTopic = ValueNotifier(selectedTopicId);
      dynamicContentStr = circleDraft.content ?? '';
      title = circleDraft.title;
    }

    // handler mention / video
    final List draftList = jsonDecode(dynamicContentStr);
    final List<Map> textList = [];
    List<String> mentions = [];
    final List<CirclePostImageItem> assets = [];
    // 处理@提及到的数据
    for (final Map map in draftList) {
      // 处理@提及到的数据
      if (map['mentions'] != null) {
        mentions = map['mentions'].cast<String>();
        continue;
      }
      // 处理图片视频资源数据
      final dynamic insertV = map['insert'] ?? '';
      if (insertV is Map) {
        final Map insertMap = insertV;
        final type = insertMap['_type'] ?? '';
        if (type == 'image' || type == 'video') {
          assets.add(CirclePostImageItem.fromJson(map['insert']));
          continue;
        }
      }
      // 把过滤掉的数据加到正文中
      textList.add(map);
    }

    return {
      'title': title,
      'content':
          dynamicContentStr.noValue ? defaultDoc : Document.fromJson(textList),
      'mentionList': mentions,
      'assets': assets,
      'dynamicContentStr': dynamicContentStr,
    };
  }

  bool get isEmptyDoc {
    return _model.editorController.document.isContentEmpty &&
        _model.titleController.text.trim().isEmpty;
  }

  String get textContent {
    final String _text = _model?.getContent();
    return _text;
  }

  String get titleText {
    final String _titleText = _model?.titleController?.text?.trim() ?? '';
    return _titleText;
  }

  void _saveDoc() {
    if (isEmptyDoc) {
      Db.circleDraftBox.delete(widget.channelId);
    } else {
      Db.circleDraftBox.put(
        widget.channelId,
        CirclePostInfoDataModel(
          guildId: widget.guildId,
          channelId: widget.channelId,
          topicId: _selTopic.value,
          title: titleText,
          postId: widget.circleDraft?.postId,
          postType: _model.isImage ? 'image' : 'video',
          content: isEmptyDoc ? null : textContent,
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (Loading.visible) return false;
    _hideSoftInput();
    if (isEmptyDoc) return true;
    if (!_isEditMode) {
      final bool = await _onWillPopCreateMode();
      _hideSoftInput();
      return bool;
    }
    _hideSoftInput();
    return _onWillPopEditMode();
  }

  Future<bool> _onWillPopCreateMode() async {
    _saveSubscription.pause();
    FocusScope.of(context).unfocus();
    final res = await showCustomActionSheet([
      Text(
        '保留'.tr,
        style: Theme.of(context).textTheme.bodyText2.copyWith(
              color: primaryColor,
            ),
      ),
      Text(
        '不保留'.tr,
        style: Theme.of(context).textTheme.bodyText2,
      )
    ], title: '是否保留此次编辑？'.tr);
    switch (res) {
      case 0:
        _saveDoc();
        return true;
        break;
      case 1:
        unawaited(Db.circleDraftBox.delete(widget.channelId));
        return true;
        break;
      default:
        _saveSubscription.resume();
        return false;
    }
  }

  Future<bool> _onWillPopEditMode() async {
    final topicChanged = widget.circleDraft.topicId != _selTopic.value;
    final titleChanged = widget.circleDraft.title != titleText;
    final String content = textContent;
    final contentChanged = widget.circleDraft.content != content;
    final changed = topicChanged || titleChanged || contentChanged;
    if (!changed) return true;
    final res = await showCustomActionSheet([
      Text(
        '退出'.tr,
        style: Theme.of(context).textTheme.bodyText2,
      )
    ], title: '内容已修改，放弃编辑并退出？'.tr);
    return res == 0;
  }

  Widget _buildSelTopics() {
    if (!_needTopic) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showTopicPopup,
            child: ValueListenableBuilder<String>(
              valueListenable: _selTopic,
              builder: (context, selTopic, child) {
                final topicName = widget.optionTopics
                        .firstWhere((element) => element.topicId == selTopic,
                            orElse: () => null)
                        ?.topicName ??
                    '';
                return Row(
                  children: [
                    ..._buildTopicPlaceholder(),
                    if (topicName.isEmpty)
                      Container()
                    else
                      TopicTagText([topicName]),
                    const MoreIcon()
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTopicPlaceholder() {
    return [
      Icon(
        IconFont.buffWenzipindaotubiao,
        color: Theme.of(context).textTheme.bodyText2.color,
        size: 16,
      ),
      const SizedBox(width: 2),
      Expanded(
        child: RichText(
          text: TextSpan(
              text: '选择圈子频道'.tr,
              style: Theme.of(context).textTheme.bodyText2.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    // height: 1.2,
                  ),
              children: const [
                TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: DefaultTheme.dangerColor,
                    // height: 1.2,
                  ),
                )
              ]),
        ),
      ),
    ];
  }

  Widget _buildTopicSelector(BuildContext context) {
    final topics = widget.optionTopics;
    if (topics.isEmpty) {
      return Center(
          child: Text('暂无圈子频道，请联系管理员创建'.tr,
              style: TextStyle(
                  color: CustomColor(context).disableColor, fontSize: 14)));
    }
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 5, 17, 17),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: Global.mediaInfo.size.height * 0.4),
              child: ValueListenableBuilder<String>(
                  valueListenable: _selTopic,
                  builder: (context, selTopic, child) {
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: topics.map((e) {
                        final isSelected = selTopic == e.topicId;
                        return ChoiceChip(
                          pressElevation: 1,
                          selectedColor: primaryColor,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(16))),
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                IconFont.buffPoundSign,
                                size: 14,
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyText2
                                        .color,
                              ),
                              const SizedBox(
                                width: 3,
                              ),
                              Text(
                                e.topicName,
                                style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyText2
                                            .color,
                                    fontSize: 14,
                                    height: 1.2),
                              ),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            _selTopic.value = e.topicId;
                            Routes.pop(context);
                          },
                        );
                      }).toList(),
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }

  void listenEditorFocus() {
    if (_model.editorFocusNode.hasFocus) {
      _model.editorFocusNode.unfocus();
    }
  }

  Future<void> _showTopicPopup() async {
    // 快速点击富文本编辑器区域再点击选择话题，由于flutter层面响应比较快，webview响应较慢，所以会导致键盘和话题弹窗同时出现
    // 所以在弹起选择话题后的500ms内监听编辑器焦点变化，不让其聚焦
    _model.editorFocusNode.addListener(listenEditorFocus);
    Future.delayed(const Duration(milliseconds: 500), () {
      _model.editorFocusNode.removeListener(listenEditorFocus);
    });
    await showBottomModal(
      context,
      builder: (c, s) => _buildTopicSelector(context),
      maxHeight: 0.5,
      backgroundColor: CustomColor(context).backgroundColor6,
      resizeToAvoidBottomInset: false,
      scrollSpec: const ScrollSpec(physics: AlwaysScrollableScrollPhysics()),
      headerBuilder: (c, s) => Column(
        children: [
          sizeHeight16,
          Text(
            '选择圈子频道'.tr,
            style: Theme.of(context)
                .textTheme
                .bodyText2
                .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          sizeHeight22,
        ],
      ),
    );
  }

  void _hideSoftInput() {
    // _model.titleNativeController?.updateFocus(false);
    // FbUtils.hideKeyboard();
    FocusScope.of(context).unfocus();
  }
}
