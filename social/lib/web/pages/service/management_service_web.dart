import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/web/extension/state_extension.dart';
import 'package:im/web/utils/image_picker/image_picker.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:im/web/widgets/popup/web_popup.dart';
import 'package:im/web/widgets/web_form_detector/web_form_detector_model.dart';
import 'package:im/widgets/custom_inputbox_web.dart';
import 'package:im/widgets/link_tile.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';

class CircleManagementService extends StatefulWidget {
  @override
  _CircleManagementPageState createState() => _CircleManagementPageState();
}

class _CircleManagementPageState extends State<CircleManagementService> {
  Uint8List _selectImageIcon;
  Uint8List _selectImageCover;
  ThemeData theme;
  GuildTarget target;
  int systemChannelFlags;
  String systemChannelId;
  bool _loading = false;
  bool changed = false;
  GuildTarget guild;
  Map<dynamic, dynamic> guildInfo = {};
  final TextEditingController _controller = TextEditingController();
  final guestFlag = "GUEST";
  int guestStatusFlag;
  int originGuestStatusFlag;

  @override
  void initState() {
    getImage();
    resetConfig();
    guild = (ChatTargetsModel.instance.selectedChatTarget as GuildTarget)
      ..addListener(onGuildChange);
    target = ChatTargetsModel.instance.getChatTarget(guild.id);
    _controller.text = guild.name;
    guestStatusFlag = guild.featureList.contains(guestFlag) ? 1 : 0;
    originGuestStatusFlag = guild.featureList.contains(guestFlag) ? 1 : 0;
    // checkFormChanged();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      formDetectorModel.setCallback(onReset: _onReset, onConfirm: _onConfirm);
    });
    super.initState();
  }

  bool isSelect(int value, int index) {
    return value & (1 << index) == 0;
  }

  int setValueSelect(int value, int index, bool isSelect) {
    if (isSelect) {
      return value & ~(1 << index);
    } else {
      return value | 1 << index;
    }
  }

  void onGuildChange() {
    resetConfig(refresh: true);
  }

  Future<void> getImage() async {
    final guild = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    final res = await GuildApi.getGuildInfo(
      showDefaultErrorToast: true,
      guildId: guild.id,
      userId: Global.user.id,
    );
    setState(() {
      guildInfo = res;
    });
  }

  void resetConfig({bool refresh = false}) {
    final guildTarget =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    systemChannelFlags = guildTarget?.systemChannelFlags ?? 0;
    // guestStatusFlag = guildTarget.featureList.contains(guestFlag) ? 1 : 0;
    systemChannelId = guildTarget?.systemChannelId;
    if (refresh && mounted) setState(() {});
  }

  String _getChannelName(String channelId) {
    final GuildTarget guild =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    final selectedChannel = guild.channels
        .where((element) =>
            element.type == ChatChannelType.guildText ||
            element.type == ChatChannelType.guildVoice ||
            element.type == ChatChannelType.guildVideo)
        .firstWhere((element) => element.id == channelId, orElse: () => null);
    return selectedChannel?.name ?? '该频道已被删除'.tr;
  }

  @override
  void dispose() {
    guild.removeListener(onGuildChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 648),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildSubtitle('服务器昵称'.tr),
          WebCustomInputBox(
            fillColor: Colors.transparent,
            controller: _controller,
            hintText: '请输入服务器名称'.tr,
            maxLength: 30,
            onChange: (val) {
              checkFormChanged();
            },
          ),
          sizeHeight32,
          _buildSubtitle('服务器标题与封面'.tr),
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                uploadingIcon(),
                uploadingCover(),
              ],
            ),
          ),
          sizeHeight16,
          const Divider(
            height: 1,
          ),
          sizeHeight32,
          _buildSubtitle('欢迎通知频道'.tr),
          LinkTile(
            context,
            Text(
              '当有人加入此服务器时，发送一条随机欢迎语'.tr,
            ),
            padding: EdgeInsets.zero,
            showTrailingIcon: false,
            trailing: Transform.scale(
              scale: 0.9,
              alignment: Alignment.centerRight,
              child: CupertinoSwitch(
                  activeColor: Theme.of(context).primaryColor,
                  value: isSelect(systemChannelFlags, 0),
                  onChanged: (v) {
                    if (_loading) return;
                    systemChannelFlags =
                        setValueSelect(systemChannelFlags, 0, v);
                    setState(() {
                      systemChannelFlags = systemChannelFlags;
                    });
                    checkFormChanged();
                  }),
            ),
          ),
          sizeHeight8,
          LayoutBuilder(builder: (context, constraint) {
            final List items =
                (ChatTargetsModel.instance.selectedChatTarget as GuildTarget)
                    .channels
                    .where((element) =>
                        element.type == ChatChannelType.guildText ||
                        element.type == ChatChannelType.guildVoice ||
                        element.type == ChatChannelType.guildVideo)
                    .map((e) => e.name)
                    .toList();
            final List guildChannels = guild.channels
                .where((element) =>
                    element.type == ChatChannelType.guildText ||
                    element.type == ChatChannelType.guildVoice ||
                    element.type == ChatChannelType.guildVideo)
                .toList();
            return TextButton(
              onPressed: () async {
                final index = await showWebSelectionPopup(context,
                    items: items,
                    offsetY: 8,
                    minimumOutSidePadding: 16,
                    width: constraint.maxWidth);
                setState(() {
                  systemChannelId = guildChannels[index].id;
                });
                // 校验频道
                checkFormChanged();
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      // ignore: avoid_redundant_argument_values
                      width: 1,
                      color: const Color(0xFFDEE0E3),
                    )),
                height: 32,
                padding: const EdgeInsets.only(left: 16, right: 16),
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getChannelName(systemChannelId),
                      style: Theme.of(context)
                          .textTheme
                          .bodyText2
                          .copyWith(fontSize: 14),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          }),
          sizeHeight32,
          const Divider(
            height: 1,
          ),
          sizeHeight32,
          _buildSubtitle('游客模式'.tr),
          LinkTile(
            context,
            Text(
              '开启游客模式'.tr,
            ),
            padding: EdgeInsets.zero,
            showTrailingIcon: false,
            trailing: Transform.scale(
              scale: 0.9,
              alignment: Alignment.centerRight,
              child: CupertinoSwitch(
                  activeColor: Theme.of(context).primaryColor,
                  value: guestStatusFlag == 1,
                  onChanged: (v) {
                    if (_loading) return;
                    guestStatusFlag = v ? 1 : 0;
                    setState(() {});
                    checkFormChanged();
                  }),
            ),
          ),
          Text(
            "开启后，新加入服务器的成员将处于「游客」状态，请添加Fanbot机器人配置「新成员验证」，完成管理者设置的验证步骤后，新成员将会被自动分配角色，成为正式成员"
                .tr,
            style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 12),
          )
        ],
      ),
    );
  }

  void checkFormChanged() {
    Provider.of<WebFormDetectorModel>(context, listen: false)
        .toggleChanged(formChanged);

    final bool enable = _controller.text.isNotEmpty &&
        _controller.text.trim().characters.length <= 30;
    formDetectorModel.confirmEnabled(enable);
  }

  bool get formChanged {
    // 获取初始化的频道id--start
    final guildTarget =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;

    final initSystemChannelId = guildTarget?.systemChannelId;
    final initSystemChannelFlags = guildTarget?.systemChannelFlags ?? 0;
    final initGuestStatusFlag =
        guildTarget.featureList.contains(guestFlag) ? 1 : 0;
    // 获取初始化的频道id--end
    return guild.name != _controller.text ||
        _selectImageIcon != null ||
        _selectImageCover != null ||
        systemChannelId != initSystemChannelId ||
        initSystemChannelFlags != systemChannelFlags ||
        initGuestStatusFlag != guestStatusFlag;
  }

  Widget _buildSubtitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .bodyText2
            .copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  // 图标组件
  Widget uploadingIcon() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 80,
          width: 80,
          margin: const EdgeInsets.only(right: 16),
          foregroundDecoration: (_selectImageIcon == null)
              ? BoxDecoration(
                  image: DecorationImage(
                      image: NetworkImage(guildInfo['icon'] ??
                          'https://xms-dev-1251001060.cos.ap-guangzhou.myqcloud.com/x-project/user-upload-files/d42ca330d93d88e0e7c19e2b2fe42fb5.jpg'),
                      fit: BoxFit.cover),
                  color: const Color(0xFFDEE0E3),
                  borderRadius: BorderRadius.circular(40))
              : BoxDecoration(
                  image: DecorationImage(
                      image: MemoryImage(_selectImageIcon), fit: BoxFit.cover),
                  color: const Color(0xFFDEE0E3),
                  borderRadius: BorderRadius.circular(40)),
          decoration: const BoxDecoration(
            color: Color(0xFFF2F3F5),
            borderRadius: BorderRadius.all(
              Radius.circular(40),
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('服务器最小图标为128x128'.tr),
                  Text(
                    '请勿超过8M'.tr,
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  _pickImage('icon');
                },
                child: Container(
                  height: 22,
                  width: 100,
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFDEE0E3),
                      ),
                      borderRadius: BorderRadius.circular(4)),
                  alignment: Alignment.center,
                  child: Text(
                    '上传图片'.tr,
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xFF1F2125)),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  // 封面组件
  Widget uploadingCover() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 80,
          width: 120,
          margin: const EdgeInsets.only(right: 16),
          foregroundDecoration: BoxDecoration(
            image: (_selectImageCover == null)
                ? DecorationImage(
                    image: NetworkImage(guildInfo['banner'] ??
                        'https://fb-cdn.fanbook.mobi/fanbook/app/files/app_image/default_banner3.jpg'),
                    fit: BoxFit.cover)
                : DecorationImage(
                    image: MemoryImage(_selectImageCover), fit: BoxFit.cover),
            color: const Color(0xFFF2F3F5),
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF2F3F5),
          ),
        ),
        SizedBox(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('服务器封面图'.tr),
                  Text(
                    '建议尺寸为1560x1056px'.tr,
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  _pickImage('cover');
                },
                child: Container(
                  height: 22,
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFDEE0E3),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '上传图片'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2125),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  // 选取图片
  Future<void> _pickImage(String type) async {
    final image = await ImagePicker.pickFile(accept: 'image/*');
    if (image != null) {
      try {
        const limit = 1024 * 1024 * 8; // 图片大小限制8M
        if (image.size > limit) {
          showToast('只能上传大小小于8m的文件'.tr);
          return;
        }
        final fileBytes = await webUtil
            .compressImageFromElement(image.pickedFile.path, quality: 0.3);
        setState(() {
          if (type == 'icon') _selectImageIcon = fileBytes;
          if (type == 'cover') _selectImageCover = fileBytes;
        });
        checkFormChanged();
      } catch (e) {
        showToast('该图片已损坏，请重新选择'.tr);
      }
    }
  }

  // 确认提交
  Future<void> _onConfirm() async {
    if (_controller.text.trim().isEmpty) {
      showToast('服务器名称不能为空'.tr);
      return;
    }

    final guild = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;

    String _icon;
    if (_selectImageIcon != null) {
      // _icon = await uploadFileIfNotExist(
      //     bytes: _selectImageIcon, fileType: "circleIcon");
      _icon = await CosFileUploadQueue.instance
          .onceForBytes(_selectImageIcon, CosUploadFileType.circleIcon);
    }
    String _cover;
    if (_selectImageCover != null) {
      // _cover = await uploadFileIfNotExist(
      //     bytes: _selectImageCover, fileType: "circleIcon");
      _cover = await CosFileUploadQueue.instance
          .onceForBytes(_selectImageCover, CosUploadFileType.circleIcon);
    }

    _toggleLoading(true);
    try {
      await GuildApi.updateGuildConfig(
        guildId: guild.id,
        userId: Global.user.id,
        systemChannelId: systemChannelId,
        systemChannelFlags: systemChannelFlags,
      );

      guild.update(
          systemChannelFlags: systemChannelFlags,
          systemChannelId: systemChannelId);
    } catch (e) {
      _toggleLoading(false);
    }

    try {
      await GuildApi.setGuildFeatures(guild.id,
          featureList: [guestFlag], status: guestStatusFlag);

      await updateGuildTargetInfo();
      originGuestStatusFlag = guestStatusFlag;
    } catch (e, s) {
      logger.severe('', e, s);
      _toggleLoading(false);
    }

    try {
      await GuildApi.updateGuildInfo(
        guild.id,
        Global.user.id,
        icon: _icon ?? guild.icon,
        banner: _cover ?? guild.banner,
        name: _controller.text.trim(),
      );

      if (_icon.hasValue) guildInfo['icon'] = _icon;
      if (_cover.hasValue) guildInfo['banner'] = _cover;

      target.updateInfo(name: _controller.text.trim());
    } catch (e) {
      showToast('图片修改错误'.tr);
      logger.severe('服务器名称修改错误:$e');
    } finally {
      _toggleLoading(false);
    }

    _selectImageIcon = null;
    _selectImageCover = null;
    checkFormChanged();
  }

  void _toggleLoading(bool value) {
    setState(() {
      _loading = value;
    });
  }

  // 取消重置数据
  Future<void> _onReset() async {
    setState(() {
      _selectImageIcon = null;
      _selectImageCover = null;
      final guildTarget =
          ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
      systemChannelFlags = guildTarget?.systemChannelFlags ?? 0;
      systemChannelId = guildTarget?.systemChannelId;
      _controller.text = guild.name;
    });
    checkFormChanged();
  }

  /// 更新服务台信息(游客信息更新)
  Future<void> updateGuildTargetInfo() async {
    ///刷新服务台数据
    final selectGt =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    final guildInfo =
        await GuildApi.getGuildInfo(guildId: guild.id, userId: Global.user.id);
    final GuildTarget tempGuildTarget = GuildTarget.fromJson(guildInfo);

    final json = selectGt.toJson();
    selectGt.featureList = List.from(tempGuildTarget.featureList ?? []);
    // json["channel_lists"] = (json["channel_lists"] as List).join(",");
    unawaited(Db.guildBox.put(selectGt.id, json));
    for (final c in selectGt.channels) unawaited(Db.channelBox.put(c.id, c));

    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    selectGt.notifyListeners();
  }
}
