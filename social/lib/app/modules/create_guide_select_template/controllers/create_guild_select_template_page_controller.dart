import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:im/api/entity/create_template.dart';
import 'package:im/api/entity/guild_template.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/const.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/quest/fb_quest.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/utils/get_image_fom_camera_or_file.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:quest_system/quest_system.dart';

class CreateGuildSelectTemplatePageController extends GetxController {
  final List<GuildTemplate> itemList = [];
  final TextEditingController inputController = TextEditingController();

  final FocusNode focusNode = FocusNode();
  final GlobalKey autoGenAvatarKey = GlobalKey();

  ///用户选择的服务器用处
  int _usedForChoice = 0;

  ///背景图片
  File _bgImageFromFile;

  ///头像
  File _avatar;

  ///创建服务器按钮校验允许
  bool _confirmEnable = false;

  bool _loadError = false;

  ///服务器名称
  String _serverName = '';

  ///获取当前选择的模板的角色列表
  List<GuildTemplateRole> get selectTargetRoles =>
      itemList[usedForChoice].guildTemplateInfo.roles;

  ///获取当前选择的模板的频道列表
  List<GuildTemplateChannel> get selectTargetChannels =>
      itemList[usedForChoice].guildTemplateInfo.channels;

  bool get loadError => _loadError;

  String get serverName => _serverName;

  bool get confirmEnable => _confirmEnable;

  File get bgImageFromFile => _bgImageFromFile;

  String get bgImageFromNet => () {
        if (itemList.isNotEmpty) {
          return itemList[_usedForChoice].background;
        } else {
          return null;
        }
      }();

  Color get templateThemeColor => itemList[usedForChoice].themeColor;

  File get avatar => _avatar;

  int get usedForChoice => _usedForChoice;

  List<CreateTemplate> templateList = [];

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  ///用户选择的服务器用途
  void choiceUsedFor(int index) {
    _usedForChoice = index;
    update();
  }

  void updateServerName() {
    if (_serverName != inputController.text.trim()) {
      _serverName = inputController.text.trim();
      confirmCheck();
      update();
    }
  }

  void confirmCheck() {
    _confirmEnable = _serverName.hasValue &&
        _serverName.length <= maxUserServerLength &&
        !loadError;
    update(['createButton']);
  }

  ///设置圈子背景图
  Future setBanner(BuildContext context) async {
    final file = await getImageFromCameraOrFile(context,
        title: "设置圈子背景图".tr,
        channel: ImageChannelType.FB_CIRCLE_BACKGROUND_PIC,
        crop: true,
        checkType: CheckType.circle,
        cropRatio: const CropAspectRatio(ratioX: 75, ratioY: 44));
    if (file != null) _bgImageFromFile = file;
    update();
  }

  ///设置服务器头像
  Future setAvatar(BuildContext context) async {
    final file = await getImageFromCameraOrFile(context,
        title: '上传服务器头像'.tr,
        crop: true,
        channel: ImageChannelType.serviceImage);
    if (file != null) _avatar = file;
    update();
  }

  ///加载模版数据
  Future loadData({bool reload = false, BuildContext context}) async {
    try {
      if (reload) Loading.show(context, label: '加载中'.tr);
      itemList.addAll(await GuildApi.getGuildTemplate(version: '60'));
      if (itemList.isEmpty) {
        if (reload) Loading.hide();
        _loadError = true;
      } else {
        if (reload) Loading.hide();
        _loadError = false;
      }
    } catch (e) {
      if (reload) Loading.hide();
      _loadError = true;
    }
    update();
  }

  ///创建服务器
  Future<void> createServer(BuildContext context) async {
    try {
      _confirmEnable = false;
      update(['createButton']);
      Loading.show(context, label: '创建中'.tr);
      String avatarUrl = '';
      String bgUrl = itemList[usedForChoice].background;
      if (avatar != null) {
        ///如果用户选择了头像就上传COS获取URL
        avatarUrl = await CosFileUploadQueue.instance
            .onceForPath(avatar.path, CosUploadFileType.headImage);
      } else {
        ///用户没有上传头像，则获取头像截图上传COS获取URL
        final RenderRepaintBoundary boundary =
            autoGenAvatarKey.currentContext.findRenderObject();
        final avatar = await boundary.toImage();
        final byteData =
            await avatar.toByteData(format: ui.ImageByteFormat.png);
        avatarUrl = await CosFileUploadQueue.instance.onceForBytes(
            byteData.buffer.asUint8List(), CosUploadFileType.headImage);
      }
      if (_bgImageFromFile != null) {
        bgUrl = await CosFileUploadQueue.instance
            .onceForPath(_bgImageFromFile.path, CosUploadFileType.image);
      }
      final res = await GuildApi.createGuild(
        name: inputController.text.trim(),
        icon: avatarUrl,
        userId: Global.user.id,
        templateId: itemList[usedForChoice].templateId.toString(),
        banner: bgUrl,
      );

      PermissionModel.initGuildPermission(
        guildId: res["guild_id"],
        ownerId: res["owner_id"],
        permissions: res['permissions'],
        userRoles: res['userRoles'],
        channels: res['channels'],
        roles: res['roles'],
      );

      final GuildTarget target = GuildTarget.fromJson(res);

      Loading.hide();

      /// 延迟 500ms 是为了服务器 push {type: string} 的消息被插入到本地数据库中
      await Future.delayed(const Duration(milliseconds: 500));
      unawaited(Get.offAllNamed(Routes.HOME));
      if (target != null) {
        // 创建服务器成功插入到官方服务器后面
        final model = ChatTargetsModel.instance;
        //web版本: 创建成功后频道需要排序
        if (target.channels != null && target.channels.isNotEmpty)
          target.sortChannels();
        // 创建完服务器默认选中
        model.addChatTarget(target);
        unawaited(model.selectChatTarget(target));

        ///添加创建新服务器后的任务引导
        FbQuest.addCreatedGuildGuide(target.id);

        /// 触发创建服务器后弹出任务弹框任务
        CustomTrigger.instance.dispatch(QuestTriggerData(
            condition: QuestCondition(
          [QIDSegGuildQuickStart.onCreatedShowTask, target.id],
        )));
      }
    } catch (e) {
      _confirmEnable = true;
      update(['createButton']);
      Loading.hide();
      if (e is DioError) {
        if (e is TimeoutException || e.type != DioErrorType.response) {
          showToast(networkErrorText);
        }
      }
    }
  }

  /// 创建服务成功后，相应的关闭当前页面
  void off() => Get.back();
}
