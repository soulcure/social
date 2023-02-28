import 'package:characters/characters.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/theme/app_colors.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/pages/guild_setting/circle/circle_setting/model/circle_management_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/link_tile.dart';
import 'package:im/widgets/text_field/native_input.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

Future jumpToCircleSettingPage(
    BuildContext context, String guildId, String channelId) async {
  Loading.show(context);
  String circleId;
  final result = await CircleApi.circlePostInfo(guildId);
  final List circleList = result['list'];
  if (circleList.isNotEmpty) {
    circleId = circleList[0]['channel_id'].toString() ?? '';
  }
  if (circleId == null) {
    Loading.hide();
    return;
  }
  final model = TopicsModel(
    circleId,
    guildId,
  );
  await model.fetchTopics();
  Loading.hide();
  final topicIndex =
      model.topics.indexWhere((element) => element.topicId == channelId);
  if (topicIndex >= 0) {
    return Routes.pushTopicNameEditorPage(
      context,
      model,
      topicIndex: topicIndex,
    );
  }
}

/// - 圈子频道设置-页面
class TopicNameEditorPage extends StatefulWidget {
  final TopicsModel topicsModel; // 圈子频道数据源
  final int topicIndex; // 修改圈子频道时的索引
  final bool isCreateTopic; // 是否为创建圈子频道

  const TopicNameEditorPage(
      {this.topicIndex, this.topicsModel, this.isCreateTopic = false, Key key})
      : super(key: key);

  @override
  _TopicNameEditorPageState createState() => _TopicNameEditorPageState();
}

class _TopicNameEditorPageState extends State<TopicNameEditorPage> {
  final _total = 30; // 最多可以输入字符数
  TextEditingController _textEditController; // 圈子频道输入框
  final _textFocus = FocusNode();

  String _name = ""; // 圈子频道名称
  int _listDisplay;
  CircleTopicDataModel topic; //当前圈子频道

  // 获取当前圈子频道标题长度
  int get _currentCount {
    if (_name.noValue)
      return 0;
    else
      return Characters(_name.trim()).length;
  }

  // 是否可以保存
  bool get _canSave {
    return _name.trim().isNotEmpty &&
        Characters(_name.trim()).length <= _total &&
        !_isAllTopic;
  }

  /// - 是否是 '全部' 圈子频道
  bool get _isAllTopic => topic != null && topic.channelId == topic.topicId;

  @override
  void initState() {
    super.initState();

    // 修改状态下,如果圈子频道数据源为空的情况
    if (widget.topicsModel.topics.length <= widget.topicIndex &&
        !widget.isCreateTopic) {
      // topicIndex非法
      return;
    }

    if (!widget.isCreateTopic) {
      topic = widget.topicsModel.topics[widget.topicIndex];
      _name = topic.topicName.trim();
      _listDisplay = topic.listDisplay ?? 0;
    }

    _textEditController = TextEditingController.fromValue(
      TextEditingValue(text: _name.trim()),
    );
  }

  @override
  void dispose() {
    _textEditController?.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: FbAppBar.custom(
          '圈子频道设置'.tr,
          backgroundColor: appThemeData.scaffoldBackgroundColor,
          leadingBlock: () {
            _textFocus.unfocus();
            Get.back();
            return true;
          },
          actions: [
            if (!_isAllTopic)
              AppBarTextPrimaryActionModel('保存'.tr,
                  isEnable: _canSave, actionBlock: _editTopicName),
          ],
        ),
        resizeToAvoidBottomInset: false,
        backgroundColor: appThemeData.scaffoldBackgroundColor,
        body: (topic == null && !widget.isCreateTopic)
            ? Container(
                height: 56,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(child: Text('该圈子频道不存在'.tr)),
              )
            : _buildPage(),
      ),
    );
  }

  Widget _buildPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.fromLTRB(16, 16, 0, 6),
            child: Text(
              "频道名称".tr,
              style: appThemeData.textTheme.headline2.copyWith(fontSize: 14),
            ),
          ),
          Container(
              height: 52,
              decoration: BoxDecoration(
                  color: appThemeData.backgroundColor,
                  borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _isAllTopic
                        ? Text(
                            '全部'.tr,
                            style: appThemeData.textTheme.bodyText2
                                .copyWith(fontSize: 17),
                          )
                        : NativeInput(
                            style: appThemeData.textTheme.bodyText2
                                .copyWith(fontSize: 17),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              counterText: "",
                            ),
                            controller: _textEditController,
                            focusNode: _textFocus,
                            onChanged: (value) {
                              setState(() => _name = value);
                            },
                            maxLength: _total,
                            maxLengthEnforcement: MaxLengthEnforcement.none,
                          ),
                  ),
                  sizeWidth8,
                  if (!_isAllTopic)
                    RichText(
                      text: TextSpan(
                          text: '$_currentCount',
                          style: Theme.of(context).textTheme.bodyText1.copyWith(
                                fontSize: 14,
                                color: _currentCount > _total
                                    ? Theme.of(context).errorColor
                                    : const Color(0xFF8F959E),
                              ),
                          children: [
                            TextSpan(
                              text: '/$_total',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8F959E),
                              ),
                            )
                          ]),
                    ),
                ],
              )),
          managerWidget,
          sizeHeight24,
          viewShowChannelWidget,
          sizeHeight24,
          deleteChannelWidget,
        ],
      ),
    );
  }

  /// - 圈子频道管理的入口控件
  Widget get managerWidget {
    return hasManagerPermission(Permission.MANAGE_ROLES)
        ? Column(
            children: [
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.fromLTRB(16, 26, 0, 6),
                child: Text(
                  "频道设置".tr,
                  style:
                      appThemeData.textTheme.headline2.copyWith(fontSize: 14),
                ),
              ),
              LinkTile(
                context,
                Text(
                  '圈子频道权限管理'.tr,
                  style: appThemeData.textTheme.bodyText2,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: 6,
                onTap: () async {
                  //iOS端进入频道权限页面，自动让输入框失去焦点，修复页面返回时原生输入获得焦点和返回动画同时进行导致视觉卡顿
                  final hasFocus = _textFocus.hasFocus;
                  if (UniversalPlatform.isIOS && hasFocus) _textFocus.unfocus();

                  final channel = ChatChannel(
                    id: topic?.topicId,
                    type: ChatChannelType.guildCircleTopic,
                    name: _name,
                    guildId: topic.guildId,
                  );
                  await Routes.pushChannelPermissionPage(context, channel);
                  if (UniversalPlatform.isIOS && hasFocus)
                    Future.delayed(const Duration(milliseconds: 200),
                        _textFocus.requestFocus);
                },
                height: 52,
              ),
            ],
          )
        : Container();
  }

  /// - 分类浏览样式入口控件
  Widget get viewStyleWidget {
    return hasManagerPermission(Permission.MANAGE_CIRCLES)
        ? Column(
            children: [
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.fromLTRB(16, 16, 0, 6),
                child: Text(
                  "自定义角色与此频道互动的方式。".tr,
                  style:
                      appThemeData.textTheme.headline2.copyWith(fontSize: 14),
                ),
              ),
              LinkTile(
                context,
                Text(
                  '在频道列表展示'.tr,
                  style: appThemeData.textTheme.bodyText2,
                ),
                borderRadius: 8,
                onTap: () {
                  ChatChannel(
                    id: topic?.topicId,
                    type: ChatChannelType.guildCircleTopic,
                    name: _name,
                    guildId: topic.guildId,
                  );
                  Routes.pushCircleViewStylePage(
                      context, widget.topicsModel, widget.topicIndex);
                },
                height: 52,
              ),
            ],
          )
        : const SizedBox();
  }

  /// - 分类浏览样式入口控件
  Widget get viewShowChannelWidget {
    return hasManagerPermission(Permission.MANAGE_CIRCLES) && !_isAllTopic
        ? Column(
            children: [
              sizeHeight20,
              LinkTile(
                context,
                Text(
                  '在频道列表展示'.tr,
                ),
                borderRadius: 6,
                showTrailingIcon: false,
                trailing: Transform.scale(
                  scale: 0.9,
                  alignment: Alignment.centerRight,
                  child: CupertinoSwitch(
                      activeColor: Get.theme.primaryColor,
                      value: _listDisplay == 1,
                      onChanged: (v) {
                        setState(() => _listDisplay = v ? 1 : 0);
                      }),
                ),
                height: 52,
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.fromLTRB(16, 12, 0, 6),
                child: Text("开启后，该圈子频道将会展示在服务器列表中".tr,
                    style: Get.textTheme.bodyText1.copyWith(fontSize: 12)),
              ),
            ],
          )
        : const SizedBox();
  }

  /// - 分类浏览样式入口控件
  Widget get deleteChannelWidget {
    // 除了全部之外，如果只有一个自定义tab，是不可以删除的
    return hasManagerPermission(Permission.MANAGE_CIRCLES) && !_isAllTopic
        ? FadeBackgroundButton(
            tapDownBackgroundColor: appThemeData.dividerColor,
            backgroundColor: appThemeData.backgroundColor,
            height: 52,
            onTap: _deleteChannel,
            borderRadius: 6,
            child: Text(
              '删除频道'.tr,
              style: appThemeData.textTheme.bodyText2
                  .copyWith(color: Colors.redAccent, height: 1.25),
            ),
          )
        : const SizedBox();
  }

  /// - 是否有可以编辑用户、角色的管理权限
  bool hasManagerPermission(Permission permission) {
    // 圈子频道为空代表当前圈子频道为创建圈子频道，还没有圈子频道ID信息
    if (topic == null || widget.isCreateTopic) {
      return false;
    }
    if (PermissionUtils.isGuildOwner()) {
      return true;
    }
    final GuildPermission gp =
        PermissionModel.getPermission(widget.topicsModel.guildId);
    if (gp == null) {
      return true;
    }
    return PermissionUtils.oneOf(gp, [permission]);
  }

  Future<void> _deleteChannel() async {
    // 如果topics只剩下一个自定义topic，就不能删除
    if (widget.topicsModel.topics.length <= 2) {
      unawaited(showConfirmDialog(
        title: "至少保留一个圈子频道哦".tr,
        confirmText: '',
        cancelText: '知道啦',
        cancelStyle: appThemeData.textTheme.bodyText2
            .copyWith(color: appThemeData.primaryColor),
        showCancelButton: false,
      ));
      return;
    }

    // 删除话题确认弹窗
    final isDelete = await showConfirmDialog(
      title: "删除后，该话题下的所有动态都会归属到最新话题里".tr,
      confirmText: '确认删除',
      confirmStyle: appThemeData.textTheme.bodyText2.copyWith(
        color: redTextColor,
        fontSize: 17,
      ),
    );
    if (!isDelete) {
      return;
    }
    // 确认删除话题
    try {
      Loading.show(context);
      await widget.topicsModel.deleteTopic(topic);
      Loading.hide();
      Get.back();
    } catch (e) {
      print(e);
      Loading.hide();
    }
  }

  Future _editTopicName() async {
    if (!_name.hasValue) {
      showToast("圈子频道名称不能为空".tr);
      return;
    }

    if (_name.characters.length > _total) {
      showToast("圈子频道名称不能超过%s个字".trArgs([_total.toString()]));
      return;
    }

    _textFocus.unfocus();

    // 当前修改圈子频道,如果和修改后的圈子频道标题一致,返回上一个视图
    if (!widget.isCreateTopic) {
      // 获取当前圈子频道数据对象
      final CircleTopicDataModel currentTopic =
          widget.topicsModel.topics[widget.topicIndex];
      // 如果圈子频道名称一致,返回上一个界面
      if (currentTopic.topicName == _name.trim() &&
          currentTopic.listDisplay == _listDisplay) {
        Navigator.pop(context);
        return;
      }
    }

    // 编辑存在相同圈子频道,提示已存在
    if (widget.topicsModel.hasTopic(_name.trim()) &&
        widget.topicsModel.topics[widget.topicIndex].listDisplay ==
            _listDisplay) {
      showToast("圈子频道已存在".tr);
      return;
    }

    try {
      Loading.show(context);
      if (widget.isCreateTopic) {
        // 创建圈子频道接口
        await widget.topicsModel
            .addTopic(_name.trim(), widget.topicsModel.guildId);
      } else {
        // 修改圈子频道名称接口
        await widget.topicsModel.renameTopic(
          widget.topicIndex,
          topic.topicId,
          _name.trim(),
          listDisplay: _listDisplay,
        );
      }
      Get.back();
      Loading.hide();
    } catch (e) {
      print(e);
      Loading.hide();
    }
  }
}
