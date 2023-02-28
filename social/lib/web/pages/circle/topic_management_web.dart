import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/web/extension/state_extension.dart';
import 'package:im/web/extension/widget_extension.dart';
import 'package:im/widgets/custom_inputbox_web.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';

import '../../../icon_font.dart';
import 'model/topics_model.dart';

class WebTopicManagement extends StatefulWidget {
  final String guildId;
  final String channelId;

  const WebTopicManagement(this.guildId, this.channelId);

  @override
  _WebTopicManagementState createState() => _WebTopicManagementState();
}

class _WebTopicManagementState extends State<WebTopicManagement> {
  TopicsModel _topicsModel;
  ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();
    _topicsModel = TopicsModel(
      context,
      widget.channelId,
      widget.guildId,
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      formDetectorModel.setCallback(
          onReset: _topicsModel.onReset, onConfirm: _topicsModel.onConfirm);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _topicsModel,
      child: Consumer<TopicsModel>(
        builder: (context, model, child) {
          return CustomScrollView(
            controller: _topicsModel.scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildTopicAll(context)),
              SliverToBoxAdapter(
                child: ReorderableColumn(
                  scrollController: _scrollController,
                  onReorder: _topicsModel.onReorder,
                  needsLongPressDraggable: false,
                  children: _topicsModel.topics
                      .map((e) => _TopicItem(
                            topic: e,
                            index: _topicsModel.topics.indexOf(e),
                            onDelete: _topicsModel.deleteTopic,
                            onChange: _topicsModel.renameTopic,
                          ))
                      .toList(),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 12,
                ),
              ),
              SliverToBoxAdapter(child: _buildAddTopic(context))
            ],
          ).addWebPaddingBottom();
        },
      ),
    );
  }

  Widget _buildAddTopic(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 42),
        Expanded(
          child: GestureDetector(
              onTap: _topicsModel.addTopic,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: DottedDecoration(
                  shape: Shape.box,
                  color: Theme.of(context).disabledColor,
                  strokeWidth: 0.3,
                  borderRadius: BorderRadius.circular(
                      4), //remove this to get plane rectange
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: DottedDecoration(
                        shape: Shape.box,
                        color: Theme.of(context).disabledColor,
                        strokeWidth: 0.2,
                        dash: const [3, 3],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 16,
                        color: Color(0xFF6179F2),
                      ),
                    ),
                    sizeWidth10,
                    Text(
                      "创建圈子频道".tr,
                      style: TextStyle(
                          fontSize: 14, color: Theme.of(context).disabledColor),
                    )
                  ],
                ),
              )),
        ),
        const SizedBox(width: 42),
      ],
    );
  }

  /// - 顶部固定'全部'圈子频道
  Widget _buildTopicAll(BuildContext context) {
    if (_topicsModel.theAllTopic == null) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 42),
          Expanded(
            child: WebCustomInputBox(
              controller: TextEditingController(
                  text: _topicsModel.theAllTopic.topicName ?? '全部'.tr),
              fillColor: Theme.of(context).backgroundColor,
              maxLength: 6,
              readOnly: true,
            ),
          ),
          const SizedBox(width: 42),
        ],
      ),
    );
  }
}

typedef TopicItemDeleteCallback = void Function(int);
typedef TopicItemModifyCallback = void Function(int, String);

class _TopicItem extends StatefulWidget {
  final CircleTopicDataModel topic;
  final int index;
  final TopicItemDeleteCallback onDelete;
  final TopicItemModifyCallback onChange;

  _TopicItem({this.topic, this.index, this.onDelete, this.onChange})
      : super(key: Key(topic.hashCode.toString()));

  @override
  __TopicItemState createState() => __TopicItemState();
}

class __TopicItemState extends State<_TopicItem> {
  TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.topic.topicName ?? '');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            child: Icon(
              IconFont.buffChannelMoveEditLarge,
              size: 20,
              color: CustomColor(context).disableColor,
            ),
          ),
          sizeWidth12,
          Expanded(
            child: WebCustomInputBox(
              controller: _controller,
              fillColor: Theme.of(context).backgroundColor,
              hintText: '请输入圈子频道名称'.tr,
              maxLength: 6,
              onChange: (val) => widget.onChange?.call(widget.index, val),
            ),
          ),
          sizeWidth12,
          SizedBox(
            width: 30,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 20,
              icon: const Icon(
                IconFont.buffCommonDeleteRed,
                color: Color(0xFFF24848),
              ),
              onPressed: () => widget.onDelete?.call(widget.index),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
