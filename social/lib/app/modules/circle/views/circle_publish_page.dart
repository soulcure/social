import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_publish_controller.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/db/db.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/circle/circle_post_entity.dart';
import 'package:im/pages/circle/content/circle_post_image_item.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/bottom_bar/keyboard_container2.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/resource_widget.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/text_field/native_input.dart';
import 'package:pedantic/pedantic.dart';

import 'portrait/widgets/portrait_toolbar_circle_publish.dart';
import 'widgets/circle_publish_textfield.dart';

class CirclePublishPage extends StatefulWidget {
  final String guildId;
  final String channelId;
  final CircleTopicDataModel defaultTopic;
  final List<CircleTopicDataModel> optionTopics;
  final CirclePostInfoDataModel circleDraft;
  final List<CirclePostImageItem> assetList;
  final CirclePostType
      circleType; // 因为用户编辑时可以改变类型，准确的值以_dynamicModel.circleType为准

  const CirclePublishPage(
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
  _CirclePublishPageState createState() => _CirclePublishPageState();
}

class _CirclePublishPageState extends State<CirclePublishPage> {
  CirclePublishController _controller;

  // 编辑模式需传postId
  bool _isEditMode;

  // 正文的焦点
  bool _focus = false;

  void contentFocusChange(bool focus) {
    _focus = focus;

    /// MediaQuery.of(context).viewInsets.bottom == 0的时候，
    /// 通过键盘弹出的rebuild去构建页面能优化页面更新效果，不要使用setState和ValueListenerBuilder，不然卡顿会特别严重
    if (MediaQuery.of(context).viewInsets.bottom != 0 && mounted)
      setState(() {});
  }

  void titleFocusChange() {
    setState(() {});
  }

  void unFocus() {
    if (_controller.titleFocusNode.hasFocus) {
      _controller.titleFocusNode.unfocus();
      return;
    }
    if (!_focus) return;
    FocusScope.of(context).unfocus();
    contentFocusChange(false);
    if (_controller.expand.value == KeyboardStatus.extend_keyboard) {
      _controller.expand.value = KeyboardStatus.hide;
    }
  }

  @override
  void initState() {
    super.initState();

    _isEditMode = widget.circleDraft != null;

    _controller = CirclePublishController(
      channel: ChatChannel(
        guildId: widget.guildId,
        id: widget.channelId,
        type: ChatChannelType.guildCircle,
      ),
      defaultTopicId: widget.defaultTopic?.topicId,
      editedData: widget.circleDraft,
      assets: widget.assetList,
    );

    _controller.titleFocusNode.addListener(titleFocusChange);
  }

  @override
  void dispose() {
    _controller.titleFocusNode?.removeListener(titleFocusChange);
    _controller.titleFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null)
      return const Center(child: CircularProgressIndicator());
    return WillPopScope(
      onWillPop: _onWillPop,
      child: GestureDetector(
        onTap: unFocus,
        onVerticalDragStart: (_) => unFocus(),
        child: GetBuilder<CirclePublishController>(
            init: _controller,
            builder: (controller) {
              return Scaffold(
                backgroundColor: appThemeData.backgroundColor,
                resizeToAvoidBottomInset: false,
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    LayoutBuilder(builder: (context, box) {
                      return NotificationListener<ScrollStartNotification>(
                        onNotification: (notification) {
                          if (notification.depth == 0) unFocus();
                          return true;
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                    minHeight: box.maxHeight -
                                        44 -
                                        getBottomViewInset() -
                                        8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_focus)
                                      _disableHideFocusGesture(
                                          child: SizedBox(
                                        height: 16 + getTopViewInset(),
                                      ))
                                    else
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CustomAppbar(
                                            backgroundColor: appThemeData
                                                .scaffoldBackgroundColor,
                                            leadingIcon:
                                                IconFont.buffNavBarCloseItem,
                                            leadingCallback: () async {
                                              final content =
                                                  _controller.getContent();
                                              print(content);
                                              final res = await _onWillPop();
                                              if (res) Get.back();
                                            },
                                          ),
                                          ResourceWidget(),
                                          Container(
                                            alignment: Alignment.center,
                                            height: 52,
                                            child: _buildDynamicTitle(),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16),
                                            child: divider,
                                          ),
                                          sizeHeight8,
                                        ],
                                      ),
                                    CirclePublishTextField(
                                      focusChange: contentFocusChange,
                                    ),
                                    buildTXDocument(controller),
                                    _disableHideFocusGesture(
                                      child:
                                          GetBuilder<CirclePublishController>(
                                        id: CirclePublishController.atListId,
                                        builder: (controller) {
                                          if (controller.showAtList.isNotEmpty)
                                            return buildAtList(controller);
                                          else
                                            return sizeHeight8;
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 10),
                                      child: SizedBox(
                                        height: 28,
                                        width: 85,
                                        child: TextButton(
                                          style: ButtonStyle(
                                              padding:
                                                  MaterialStateProperty.all(
                                                      EdgeInsets.zero),
                                              backgroundColor:
                                                  MaterialStateProperty.all(
                                                appThemeData
                                                    .scaffoldBackgroundColor,
                                              )),
                                          onPressed:
                                              _controller.appendMentionUser,
                                          child: Text(
                                            '@提醒谁看',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    appThemeData.primaryColor),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 16),
                                      child: divider,
                                    ),
                                    _buildSelTopics(),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 16),
                                      child: divider,
                                    ),
                                    ObxValue((needSaveToAlbum) {
                                      return GestureDetector(
                                        onTap: () => _controller.needSaveToAlbum
                                            .value = !needSaveToAlbum.value,
                                        behavior: HitTestBehavior.translucent,
                                        child: SizedBox(
                                          height: 48,
                                          child: Row(
                                            textDirection: TextDirection.rtl,
                                            children: [
                                              sizeWidth16,
                                              Text(
                                                '发布后保存至相册',
                                                style: TextStyle(
                                                  color: needSaveToAlbum.value
                                                      ? appThemeData.textTheme
                                                          .bodyText2.color
                                                      : appThemeData
                                                          .dividerColor
                                                          .withOpacity(1),
                                                  fontSize: 13,
                                                ),
                                              ),
                                              sizeWidth4,
                                              if (needSaveToAlbum.value)
                                                Icon(
                                                  IconFont
                                                      .buffCirclePublishCheckin,
                                                  size: 18,
                                                  color:
                                                      appThemeData.primaryColor,
                                                )
                                              else
                                                Container(
                                                  width: 16,
                                                  height: 16,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                          color: appThemeData
                                                              .textTheme
                                                              .headline2
                                                              .color)),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }, _controller.needSaveToAlbum),
                                    sizeHeight24,
                                  ],
                                ),
                              ),
                              if (MediaQuery.of(context).viewInsets.bottom <=
                                      getBottomViewInset() &&
                                  !_focus)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                      16, 0, 16, getBottomViewInset() + 8),
                                  child: FadeBackgroundButton(
                                    onTap: _controller.sendDynamicDoc,
                                    borderRadius: 5,
                                    backgroundColor: appThemeData.primaryColor,
                                    tapDownBackgroundColor:
                                        appThemeData.dividerColor,
                                    child: Container(
                                        height: 44,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '立即发布'.tr,
                                          style: appThemeData
                                              .textTheme.bodyText2
                                              .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500),
                                        )),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (controller.titleFocusNode.hasFocus ||
                        _focus ||
                        controller.expand.value ==
                            KeyboardStatus.extend_keyboard)
                      Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: CirclePublishToolbar(
                            context,
                            onTap: unFocus,
                          )),
                  ],
                ),
              );
            }),
      ),
    );
  }

  Widget buildAtList(CirclePublishController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: controller.showAtList
            .map((e) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: appThemeData.primaryColor.withOpacity(0.1),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RealtimeNickname(
                        userId: e,
                        prefix: "@",
                        textScaleFactor: 1,
                        showNameRule: ShowNameRule.remarkAndGuild,
                        style: appThemeData.textTheme.bodyText2
                            .copyWith(color: appThemeData.primaryColor),
                        guildId: widget.guildId,
                      ),
                      if (controller.mentionList.contains(e)) ...[
                        sizeWidth8,
                        GestureDetector(
                          onTap: () => controller.removeMention(e),
                          child: Icon(
                            IconFont.buffNavBarCloseItem,
                            size: 14,
                            color: appThemeData.primaryColor,
                          ),
                        ),
                      ]
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget buildTXDocument(CirclePublishController controller) {
    final _delDocButton = GestureDetector(
      onTap: controller.removeTCDoc,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 20,
        width: 20,
        alignment: Alignment.center,
        child: Icon(
          IconFont.buffNavBarCloseItem,
          size: 16,
          color: appThemeData.disabledColor,
        ),
      ),
    );
    return GetBuilder<CirclePublishController>(
      id: controller.circleDynamicDocumentIdentifier,
      builder: (_) {
        if (controller.docItem != null) {
          //在二次编辑时可能存在文档被删除了,所以加上判断
          if (controller.docItem.fileId != null)
            return GestureDetector(
              onTap: controller.editTCDoc,
              child: Container(
                decoration: BoxDecoration(
                  color: appThemeData.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                width: double.infinity,
                height: 96,
                margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Row(
                          children: [
                            controller.docItem.getDocIcon(),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                controller.docItem.title ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    const TextStyle(height: 1.25, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _delDocButton,
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Divider(
                        height: .5,
                        color: appThemeData.dividerColor,
                      ),
                    ),
                    Container(
                      height: 32,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        '所有人可阅读'.tr,
                        style: TextStyle(
                          color: appThemeData.disabledColor,
                          fontSize: 12,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          else
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: appThemeData.scaffoldBackgroundColor,
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: appThemeData.backgroundColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Icon(IconFont.buffDocDel,
                        size: 24,
                        color: appThemeData.dividerColor.withOpacity(1)),
                  ),
                  sizeWidth12,
                  Text(
                    '文档已被删除'.tr,
                    style: appThemeData.textTheme.bodyText1.copyWith(
                        fontSize: 14,
                        color: appThemeData.dividerColor.withOpacity(1)),
                  ),
                  const Spacer(),
                  _delDocButton,
                ],
              ),
            );
        } else
          return const SizedBox();
      },
    );
  }

  Widget _buildDynamicTitle() {
    return NativeInput(
      controller: _controller.titleController,
      focusNode: _controller.titleFocusNode,
      onSubmitted: (string) async {
        if (_controller.textFieldFocusNode.canRequestFocus) {
          _controller.titleFocusNode.unfocus();
          await Future.delayed(const Duration(milliseconds: 100));
          _controller.textFieldFocusNode.requestFocus();
        }
      },
      style: appThemeData.textTheme.bodyText2
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
            fontSize: 16, color: appThemeData.iconTheme.color.withOpacity(0.4)),
        hintText: '填写标题可能会获得很多赞哦~',
      ),
    );
  }

  Widget _disableHideFocusGesture({Widget child}) {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.translucent,
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }

  Future<bool> _onWillPop() async {
    if (Loading.visible) return false;
    FocusScope.of(context).unfocus();
    if (_controller.isEmptyDoc) return true;
    if (!_isEditMode) {
      return _onWillPopCreateMode();
    }
    return _onWillPopEditMode();
  }

  Future<bool> _onWillPopCreateMode() async {
    final res = await showCustomActionSheet([
      Text(
        '保留'.tr,
        style: appThemeData.textTheme.bodyText2.copyWith(
          color: primaryColor,
        ),
      ),
      Text(
        '不保留'.tr,
        style: appThemeData.textTheme.bodyText2,
      )
    ], title: '是否保留此次编辑？'.tr);
    switch (res) {
      case 0:
        DLogManager.getInstance().customEvent(
            actionEventId: 'post_issue_click',
            actionEventSubId: 'click_save_issue',
            actionEventSubParam: '0',
            extJson: {"guild_id": widget.guildId});
        _controller.saveDoc();
        return true;
        break;
      case 1:
        DLogManager.getInstance().customEvent(
            actionEventId: 'post_issue_click',
            actionEventSubId: 'click_save_issue',
            actionEventSubParam: '1',
            extJson: {"guild_id": widget.guildId});
        unawaited(Db.circleDraftBox.delete(widget.channelId));
        return true;
        break;
      default:
        return false;
    }
  }

  Future<bool> _onWillPopEditMode() async {
    final topicChanged =
        widget.circleDraft.topicId != _controller.selectedTopicId.value;
    final String titleText = _controller.titleController?.text?.trim() ?? '';
    final titleChanged = widget.circleDraft.title != titleText;
    final String content = _controller.getContent();
    final contentChanged = widget.circleDraft.content != content;
    final changed = topicChanged || titleChanged || contentChanged;
    if (!changed) return true;
    final res = await showCustomActionSheet([
      Text(
        '退出'.tr,
        style: appThemeData.textTheme.bodyText2,
      )
    ], title: '内容已修改，放弃编辑并退出？'.tr);
    return res == 0;
  }

  Widget _buildSelTopics() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _controller.showTopicPopup,
        child: ObxValue<RxString>((selectedTopicId) {
          final topicName = widget.optionTopics
                  .firstWhere(
                      (element) => element.topicId == selectedTopicId.value,
                      orElse: () => null)
                  ?.topicName ??
              '';
          return Row(
            children: [
              ..._buildTopicPlaceholder(),
              Expanded(
                child: Text(
                  topicName.isNotEmpty ? topicName : '请选择'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: appThemeData.textTheme.headline2
                      .copyWith(fontSize: 15, height: 1.25),
                ),
              ),
              sizeWidth4,
              const MoreIcon()
            ],
          );
        }, _controller.selectedTopicId),
      ),
    );
  }

  List<Widget> _buildTopicPlaceholder() {
    return [
      Icon(
        IconFont.buffWenzipindaotubiao,
        color: appThemeData.textTheme.bodyText2.color,
        size: 16,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: RichText(
          text: TextSpan(
              text: '选择频道'.tr,
              style: appThemeData.textTheme.bodyText2.copyWith(height: 1.25),
              children: const [
                TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: DefaultTheme.dangerColor,
                    height: 1.25,
                  ),
                )
              ]),
        ),
      ),
    ];
  }
}
