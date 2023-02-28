import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_text_field/flutter_text_field.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/circle/circle_post_entity.dart';
import 'package:im/pages/circle/content/circle_post_image_item.dart';
import 'package:im/pages/circle/model/circle_dynamic_data_controller.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_item.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/bottom_bar/keyboard_container2.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/images_grid_view.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/abstract_rich_text_factory.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/text_field/native_input.dart';
import 'package:im/widgets/topic_tag_text.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rich_input/rich_input.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

class CreateDynamicMoment extends StatefulWidget {
  final String guildId;
  final String channelId;
  final CircleTopicDataModel defaultTopic;
  final List<CircleTopicDataModel> optionTopics;
  final CirclePostInfoDataModel circleDraft;
  final List<CirclePostImageItem> assetList;
  final CirclePostType
      circleType; // 因为用户编辑时可以改变类型，准确的值以_dynamicModel.circleType为准

  const CreateDynamicMoment(
    this.guildId,
    this.channelId, {
    this.defaultTopic,
    this.optionTopics = const [],
    this.circleDraft,
    this.assetList,
    this.circleType = CirclePostType.CirclePostTypeImage,
    Key key,
  }) : super(key: key);

  @override
  _CreateDynamicMomentState createState() => _CreateDynamicMomentState();
}

class _CreateDynamicMomentState extends State<CreateDynamicMoment> {
  ValueNotifier<String> _selTopic;
  CircleDynamicDataController _dynamicModel;
  bool _needTopic;
  BehaviorSubject<String> _saveStream;
  StreamSubscription<String> _saveSubscription;

  //记录进入该页面时的时间戳
  int _timeMillis;

  // 编辑模式需传postId
  bool _isEditMode;

  String _postType;

  /// 高度计算
  bool _focus = false;
  final double emojiHeight = 300 + getBottomViewInset(); // emoji 键盘高度
  double _keyboardHeight = 0; //键盘高度
  double _scrollStartPosition = -1; // 用于安卓输入框滚动计算
  int _androidKey = 0; // 安卓输入框是通过ConstrainedBox包裹，如果不用key刷新的话，就会造成内部滚动导致外部无法滚动

  void _shouldUpdateKeyboardHeight() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    _keyboardHeight = bottomInset == 0 ? _keyboardHeight : bottomInset;
  }

  double get inputTextFieldMaxHeight {
    /// 无焦点的情况，让输入框自由拓展高度
    if (!_focus) return 9999;

    /// 有焦点的时候，需要根据屏幕的整体高度，去计算输入框的合适大小
    final height = Global.mediaInfo.size.height -
        getTopViewInset() -
        getBottomViewInset() -
        50 - // 输入框切换栏
        80 - // 半漏图片的padding
        8;
    if (_dynamicModel.tabIndex.value == ToolbarIndex.emoji) {
      // emoji键盘高度去做计算
      return height - emojiHeight;
    }
    return height - _keyboardHeight;
  }

  Future<void> _nativeTextFieldFocusChange() async {
    // 键盘有焦点 = textFieldFocus + emoji + at
    final bool hasFocus = _dynamicModel.textFieldFocusNode.hasFocus ||
        _dynamicModel.tabIndex.value == ToolbarIndex.emoji ||
        _dynamicModel.tabIndex.value == ToolbarIndex.at;
    if (_focus != hasFocus) {
      if (hasFocus && _dynamicModel.scrollController.position.pixels != 0) {
        // 如果是从无焦点到有焦点，需要将整个列表滚到顶部
        await _dynamicModel.scrollController.animateTo(0,
            duration: const Duration(milliseconds: 1), curve: Curves.bounceIn);
      }
      _focus = hasFocus;

      /// MediaQuery.of(context).viewInsets.bottom == 0的时候，
      /// 通过键盘弹出的rebuild去构建页面能优化页面更新效果，不要使用setState和ValueListenerBuilder，不然卡顿会特别严重
      if (MediaQuery.of(context).viewInsets.bottom != 0 && mounted)
        setState(() {
          if (UniversalPlatform.isAndroid) _androidKey += 1;
        });
    }
  }

  @override
  void initState() {
    super.initState();

    _timeMillis = DateTime.now().millisecondsSinceEpoch;
    _isEditMode = widget.circleDraft != null;

    _dynamicModel = AbstractRichTextFactory.instance.createDynamicController(
      channel: ChatChannel(
        guildId: widget.guildId,
        id: widget.channelId,
        type: ChatChannelType.guildCircle,
      ),
      assetList: widget.assetList,
      circleType: widget.circleType,
      maxImages:
          (widget.circleType == CirclePostType.CirclePostTypeVideo) ? 1 : 9,
      onSend: _sendDynamicDoc,
    );
    Get.put(_dynamicModel);

    unawaited(_dynamicModel.requestMediaData());

    final circleDraftMap = _loadDocument();
    _dynamicModel.titleController.text = circleDraftMap['title'];
    _dynamicModel.setContent(circleDraftMap['dynamicContentStr'] ?? '');

    _filterNoPermissionTopic();

    _needTopic = widget.optionTopics
        .where((element) => element.type != CircleTopicType.unknown)
        .isNotEmpty;

    if (!_isEditMode) {
      _saveStream = BehaviorSubject<String>();
      _saveSubscription = _saveStream
          .debounceTime(const Duration(milliseconds: 500))
          .listen((data) {
        _saveDoc();
      });
    }

    _dynamicModel.textFieldFocusNode.addListener(_nativeTextFieldFocusChange);
  }

  /// - 过滤掉没有发布权限的圈子频道
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

  @override
  void dispose() {
    _dynamicModel.textFieldFocusNode
        .removeListener(_nativeTextFieldFocusChange);
    if (!_isEditMode) _saveStream?.close();
    Get.delete<CircleDynamicDataController>();
    super.dispose();
  }

  Widget _buildDynamicTitle() {
    if (!_dynamicModel.needTitle) return const SizedBox();
    return NativeInput(
      controller: _dynamicModel.titleController,
      focusNode: _dynamicModel.titleFocusNode,
      onSubmitted: (string) async {
        if (_dynamicModel.textFieldFocusNode.canRequestFocus) {
          _dynamicModel.titleFocusNode.unfocus();
          await Future.delayed(const Duration(milliseconds: 100));
          _dynamicModel.textFieldFocusNode.requestFocus();
        }
      },
      style: Theme.of(context)
          .textTheme
          .bodyText2
          .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
      keyboardType: TextInputType.multiline,
      inputFormatters: [LengthLimitingTextInputFormatter(30)],
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        isDense: true,
        counterText: "",
        border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(20),
            gapPadding: 0),
        hintStyle: TextStyle(
            fontSize: 16,
            color: CustomColor(context).disableColor.withOpacity(0.75)),
        hintText: _dynamicModel.titlePlaceholder,
      ),
    );
  }

  Widget _nativeTextField() {
    return RichTextField(
      minHeight: 72,
      maxHeight: inputTextFieldMaxHeight,
      controller: _dynamicModel.inputController.rawIosController,
      focusNode: _dynamicModel.textFieldFocusNode,
      text: _dynamicModel.inputController.data,
      textStyle: Theme.of(context)
          .textTheme
          .bodyText2
          .copyWith(fontSize: 16, height: 1.25),
      needEagerGesture: _focus,
      cursorColor: primaryColor,
      placeHolder: '分享你的新鲜事'.tr,
      placeHolderStyle: TextStyle(
          fontSize: 16,
          height: 1.25,
          color: CustomColor(context).disableColor.withOpacity(0.75)),
      scrollFromBottomTop: () {
        // 从iOS原生，顶部在滑上，底部再滑下的滚动回调事件 【仿微信、小红书的操作】
        _dynamicModel.textFieldFocusNode.unfocus();
      },
    );
  }

  Widget _flutterTextField() {
    final child = RichInput(
      minLines: 3,
      enableSuggestions: false,
      controller: _dynamicModel.inputController.rawFlutterController,
      focusNode: _dynamicModel.textFieldFocusNode,
      keyboardType: TextInputType.multiline,
      maxLines: null,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        hintText: '分享你的新鲜事'.tr,
        hintStyle: TextStyle(
            fontSize: 16,
            height: 1.25,
            color: CustomColor(context).disableColor.withOpacity(0.75)),
        border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(20),
            gapPadding: 0),
      ),
    );
    return ConstrainedBox(
      key: ValueKey(_androidKey),
      constraints: BoxConstraints(
        maxHeight: inputTextFieldMaxHeight,
        minHeight: 44,
      ),
      child: child,
    );
  }

  List<Widget> _sliverDynamicWidgets() {
    return [
      SliverToBoxAdapter(
          child: Visibility(
        visible: !_focus,
        child: Column(
          children: [
            _buildSelTopics(),
            Container(
              alignment: Alignment.center,
              height: 44,
              child: _buildDynamicTitle(),
            ),
            divider,
            sizeHeight16,
          ],
        ),
      )),
      SliverToBoxAdapter(
        child: _dynamicModel.inputController.useNativeInput
            ? _nativeTextField()
            : _flutterTextField(),
      ),
      //九宫格
      const ImagesGridView(),
    ];
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    switch (notification.runtimeType) {
      // 下面3个case的代码是安卓输入框实现iOS同等功能的逻辑, 顶部在滑上，底部再滑下的滚动处理逻辑 【仿微信、小红书的操作】
      case ScrollStartNotification:
        if (notification.depth == 0) {
          // 外层列表滚动则隐藏输入框
          if (MediaQuery.of(context).viewInsets.bottom != 0)
            FocusScope.of(context).unfocus();
          if (_dynamicModel.tabIndex.value == ToolbarIndex.emoji) {
            setState(() {
              _focus = false;
            });
            _dynamicModel.expand.value = KeyboardStatus.hide;
          }
          return false;
        } else if (notification.depth == 1 && UniversalPlatform.isAndroid) {
          // 记录内部输入框一开始滚动的位置
          _scrollStartPosition = notification.metrics.pixels;
        }
        break;
      case OverscrollNotification: //
        final _notification = notification as OverscrollNotification;
        if (notification.depth == 1 && UniversalPlatform.isAndroid) {
          if (_scrollStartPosition == 0 && _notification.overscroll < 0) {
            // 如果起始位置在顶部，并向顶部继续滚动的话，隐藏键盘
            FocusScope.of(context).unfocus();
          } else if (_scrollStartPosition > 0 &&
              _notification.metrics.pixels == _scrollStartPosition &&
              _notification.overscroll > 0) {
            // 如果起始位置在底部，并向底部继续滚动的话，隐藏键盘
            FocusScope.of(context).unfocus();
          }
        }
        break;
      case ScrollEndNotification: // 清空位置记录
        if (notification.depth == 1 && UniversalPlatform.isAndroid)
          _scrollStartPosition = -1;
        break;
      default:
        break;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    _shouldUpdateKeyboardHeight();
    if (_dynamicModel == null)
      return const Center(child: CircularProgressIndicator());
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            Visibility(
              visible: !_focus,
              child: CustomAppbar(
                title: '发布动态'.tr,
                backgroundColor: Theme.of(context).backgroundColor,
                leadingIcon: IconFont.buffNavBarCloseItem,
                leadingCallback: () async {
                  final res = await _onWillPop();
                  if (res) Get.back();
                },
              ),
            ),
            Visibility(
                visible: _focus,
                child: SizedBox(
                  height: 16 + getTopViewInset(),
                )),
            Expanded(
              child: NotificationListener(
                onNotification: _handleScrollNotification,
                child: Container(
                  color: Get.theme.backgroundColor,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _dynamicModel.scrollController,
                    slivers: _sliverDynamicWidgets(),
                  ),
                ),
              ),
            ),
            AbstractRichTextFactory.instance
                .createDynamicEditorToolbar(context),
          ],
        ),
      ),
    );
  }

  Future<void> _sendDynamicDoc() async {
    if (_needTopic && _selTopic.value == null) {
      _showTopicPopup();
      return;
    }

    FocusScope.of(context).unfocus();
    if (_dynamicModel.inputController.data.runes.length > 5000) {
      showToast('内容长度超出限制'.tr);
      return;
    }

    try {
      Loading.show(context);

      //将标题和内容，进行内容审核
      final titleAndContent = _dynamicModel.titleController.data.trim() +
          _dynamicModel.inputController.data.trim();
      if (titleAndContent.isNotEmpty) {
        const textChannel = TextChannelType.FB_CIRCLE_POST_TEXT;
        final textRes = await CheckUtil.startCheck(
            TextCheckItem(titleAndContent, textChannel,
                checkType: CheckType.circle),
            toastError: false);
        if (!textRes) {
          Loading.hide();
          showToast(defaultErrorMessage);
          throw CheckTypeException(defaultErrorMessage);
        }
      }

      //mentions: @人的用户id
      await _dynamicModel.uploadFile();
      final String contentStr = _dynamicModel.getContent();

      final String hashStr =
          '${_dynamicModel.titleController.data.trim()}$contentStr$_timeMillis';
      final String hashV = generateMd5(hashStr);

      final res = await CircleApi.createCircle(widget.guildId, widget.channelId,
          _selTopic.value, _isEditMode ? widget.circleDraft.postId : null,
          title: _dynamicModel.titleController.data,
          contentV2: contentStr,
          postType: _dynamicModel.getType(),
          mentions: _dynamicModel.atSelectorModel.atList,
          hash: hashV);

      final model = CirclePostInfoDataModel.fromJson(res);
      Loading.hide();

      if (!_isEditMode) {
        unawaited(Db.circleDraftBox.delete(widget.channelId));
        Routes.pop(context, model);
      } else {
        /// 更新聊天列表-circle_share_item的缓存
        if (postInfoMap[widget.circleDraft.postId] != null) {
          postInfoMap[widget.circleDraft.postId].titleListener.value =
              _dynamicModel.titleController.data;
          postInfoMap[widget.circleDraft.postId].contentListener.value =
              contentStr;
        }
        Routes.pop(context, model);
      }
    } catch (e, s) {
      logger.severe('圈子发送失败', e, s);
    } finally {
      Loading.hide();
    }
  }

  Document get defaultDoc =>
      Document.fromJson(jsonDecode(r'[{"insert":"\n"}]'));

  Map<String, dynamic> _loadDocument() {
    String dynamicContentStr = '';
    // 编辑模式
    if (_isEditMode) {
      final String selectedTopicId = widget.optionTopics
          .firstWhere(
              (element) => element.topicId == widget.circleDraft.topicId,
              orElse: () => null)
          ?.topicId;
      _selTopic = ValueNotifier(selectedTopicId);
      Document document;
      if (widget.circleDraft.content == null) {
        document = defaultDoc;
      } else {
        try {
          document = Document.fromJson(jsonDecode(widget.circleDraft.content));
          dynamicContentStr = widget.circleDraft.content ?? '';
        } catch (e) {
          document = defaultDoc;
          logger.severe('圈子动态格式错误', e);
        }
      }
      return {
        'title': widget.circleDraft.title,
        'content': document,
        'dynamicContentStr': dynamicContentStr ?? '',
      };
    }
    // 新增模式
    // 无缓存
    final circleDraft = Db.circleDraftBox.get(widget.channelId);
    if (circleDraft == null) {
      _selTopic = ValueNotifier(widget.defaultTopic?.topicId);
      return {
        'title': '',
        'content': defaultDoc,
        'dynamicContentStr': '',
      };
    }
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

    Document document;
    try {
      document = Document.fromJson(jsonDecode(circleDraft.content));
    } catch (e) {
      document = defaultDoc;
      logger.severe('圈子动态格式错误', e);
    }

    return {
      'title': circleDraft.title,
      'content': circleDraft.content == null ? defaultDoc : document,
      'dynamicContentStr': dynamicContentStr,
    };
  }

  bool get isEmptyDoc {
    return _dynamicModel.getContent().isEmpty &&
        _dynamicModel.titleController.text.trim().isEmpty;
  }

  String get textContent {
    final String _text = _dynamicModel.getContent();
    return _text;
  }

  String get titleText {
    final String _titleText =
        _dynamicModel?.titleController?.text?.trim() ?? '';
    return _titleText;
  }

  void _saveDoc() {
    if (isEmptyDoc) {
      Db.circleDraftBox.delete(widget.channelId);
    } else {
      if (_dynamicModel.circleType == CirclePostType.CirclePostTypeVideo) {
        _postType = 'video';
      } else {
        _postType = 'image';
      }

      Db.circleDraftBox.put(
        widget.channelId,
        CirclePostInfoDataModel(
          guildId: widget.guildId,
          channelId: widget.channelId,
          topicId: _selTopic.value,
          title: titleText,
          postType: _postType,
          content: isEmptyDoc ? null : textContent,
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (Loading.visible) return false;
    FocusScope.of(context).unfocus();
    if (isEmptyDoc) return true;
    if (!_isEditMode) {
      return _onWillPopCreateMode();
    }
    return _onWillPopEditMode();
  }

  Future<bool> _onWillPopCreateMode() async {
    _saveSubscription.pause();
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
      const SizedBox(width: 8),
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

  void _showTopicPopup() {
    FocusScope.of(context).unfocus();
    _dynamicModel.expand.value = KeyboardStatus.hide;
    _dynamicModel.tabIndex.value = null;
    showBottomModal(
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
}
