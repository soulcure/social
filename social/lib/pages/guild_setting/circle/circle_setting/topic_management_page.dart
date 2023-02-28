import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/link_tile.dart';

import 'model/circle_management_model.dart';

/// - 话题管理
class TopicManagementPage extends StatefulWidget {
  final TopicsModel topicsModel;

  const TopicManagementPage(this.topicsModel, {Key key}) : super(key: key);

  @override
  _TopicManagementPageState createState() => _TopicManagementPageState();
}

class _TopicManagementPageState extends State<TopicManagementPage> {
  final double _itemHeight = 52;

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF0F1F2);
    return Scaffold(
      appBar: CustomAppbar(
        title: '圈子频道管理'.tr,
        elevation: 0.5,
        backgroundColor: bgColor,
        actions: [
          AppbarCustomButton(
            child: StreamBuilder<bool>(
              stream: widget.topicsModel.hasTopicStream,
              builder: (context, snapshot) {
                return Visibility(
                  visible: snapshot.data ?? false,
                  child: AppbarTextButton(
                    // 编辑话题 (删除 / 排序)
                    onTap: () =>
                        Routes.pushTopicEditorPage(context, widget.topicsModel),
                    text: '编辑'.tr,
                  ),
                );
              },
            ),
          )
        ],
      ),
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildAddTopic(context),
          sizeHeight16,
          Expanded(child: _buildTopicsList(context)),
        ],
      ),
    );
  }

  // 话题列表
  Widget _buildTopicsList(BuildContext context) {
    return StreamBuilder<List<CircleTopicDataModel>>(
        stream: widget.topicsModel.topicsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final topicsCount = snapshot?.data?.length ?? 0;
          return ListView.builder(
            itemCount: topicsCount,
            itemBuilder: (context, index) {
              final t = widget.topicsModel.topics[index];
              return Container(
                color: Colors.white,
                alignment: Alignment.centerLeft,
                child: LinkTile(
                  context,
                  Text(
                    t.topicName,
                    style: const TextStyle(fontSize: 17),
                  ),
                  // 修改话题名称
                  onTap: () => Routes.pushTopicNameEditorPage(
                    context,
                    widget.topicsModel,
                    topicIndex: index,
                  ),
                  height: _itemHeight,
                ),
              );
            },
          );
        });
  }

  // 创建话题按钮
  Widget _buildAddTopic(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeBackgroundButton(
          height: _itemHeight,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // 创建新的话题
          onTap: () => Routes.pushTopicNameEditorPage(
              context, widget.topicsModel,
              isCreateTopic: true),
          tapDownBackgroundColor:
              Theme.of(context).backgroundColor.withOpacity(0.5),
          child: Row(
            children: [
              Icon(
                Icons.add,
                size: 26,
                color: Get.theme.primaryColor,
              ),
              sizeWidth10,
              Text(
                '创建圈子频道'.tr,
                style: const TextStyle(fontSize: 17),
              )
            ],
          ),
        ),
      ],
    );
  }
}
