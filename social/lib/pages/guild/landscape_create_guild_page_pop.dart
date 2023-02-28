import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/app/modules/config_guild_assistant_page/controllers/config_guild_assistant_page_controller.dart';
import 'package:im/app/modules/config_guild_assistant_page/views/land_config_guild_assistant_page_view.dart';
import 'package:im/app/modules/create_guide_select_template/views/land_create_guild_select_template_page_view.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/utils/get_image_fom_camera_or_file.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:im/widgets/button/primary_button.dart';
import 'package:im/widgets/land_pop_app_bar.dart';
import 'package:im/widgets/normal_text_input.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:x_picker/x_picker.dart';

const int MAX_LENGTH = 30;

///
/// 创建服务器
///
class CreateGuildPagePop extends StatefulWidget {
  final String batchGuidType;
  const CreateGuildPagePop({Key key, this.batchGuidType}) : super(key: key);
  @override
  _CreateGuildPageState createState() => _CreateGuildPageState();
}

class _CreateGuildPageState extends State<CreateGuildPagePop> {
  Uint8List _avatarFile;
  ThemeData _theme;
  bool _confirmEnable = false;
  bool _loading = false;
  String _serverName = '';

  @override
  void initState() {
    _serverName = '%s的服务器'.trArgs([Global.user.nickname]);
    _updateConfirmEnable();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    return popWrap(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LandPopAppBar(title: '创建服务器'.tr),
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 24),
            child: Text(
              '上传服务器头像和填写名字，免费创建一个服务器'.tr,
              style: _theme.textTheme.bodyText2.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildAvatar(),
          FractionallySizedBox(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.only(top: 40, bottom: 10),
              child: Text("服务器名称".tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: _theme.disabledColor,
                  )),
            ),
          ),
          _buildInput(),
          const SizedBox(height: 40),
          // _buildCreateBtn()
          _buildButton(),
          sizeHeight16,
        ],
      ),
    );
  }

  /// 创建头像栏
  Align _buildAvatar() {
    return Align(
      alignment: Alignment.topCenter,
      child: Builder(
        builder: (context) => InkWell(
          onTap: () => _selectAvatar(context),
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              children: <Widget>[
                _previewAvatar(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    alignment: Alignment.center,
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                        color: Colors.black, shape: BoxShape.circle),
                    child: Icon(
                      IconFont.buffOtherPhoto,
                      color: _theme.backgroundColor,
                      size: 26,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 头像预览
  Widget _previewAvatar() {
    if (_avatarFile != null) {
      return ClipOval(
          child: SizedBox(
        width: 120,
        height: 120,
        child: Image.memory(_avatarFile, fit: BoxFit.cover),
      ));
    } else {
      return Container(
        width: 120,
        height: 120,
        decoration: DottedDecoration(
          shape: Shape.circle,
          color: const Color(0xFFE0E2E6),
          strokeWidth: 2,
          dash: const [7, 7],
        ),
      );
    }
  }

  /// 点击选择头像
  Future<void> _selectAvatar(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final image = await XPicker.instance.pickMedia(type: MediaType.IMAGE);
    if (image != null) {
      try {
        const limit = 1024 * 1024 * 8; // 图片大小限制8M
        if (await image.length() > limit) {
          showToast('只能上传大小小于8m的文件'.tr);
          return;
        }

        final fileBytes = await webUtil.compressImageFromElement(image.path);
        await webUtil.compressImageFromElement(image.path);
        final checkResult = await CheckUtil.startCheck(ImageCheckItem.fromBytes(
            [U8ListWithPath(fileBytes, image.path)], ImageChannelType.headImage,
            needCompress: true));
        if (!checkResult) {
          return;
        }

        setState(() {
          _avatarFile = fileBytes;
        });

        _updateConfirmEnable();
      } catch (e) {
        print('e: $e');
        showToast('该图片已损坏，请重新选择'.tr);
      }
    }
  }

  /// 创建输入框
  Widget _buildInput() {
    return Container(
      decoration: BoxDecoration(
          color: Get.theme.backgroundColor,
          border: Border.all(
            color: const Color(0xFFDEE0E3),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(6))),
      height: 40,
      child: NormalTextInput(
        initText: _serverName,
        placeHolder: '输入服务器名称'.tr,
        maxCnt: MAX_LENGTH,
        height: 40,
        fontSize: 14,
        backgroundColor: Colors.transparent,
        contentPadding: const EdgeInsets.only(bottom: 10),
        onChanged: (value) {
          _serverName = value;
          _updateConfirmEnable();
        },
      ),
    );
  }

  void _updateConfirmEnable() {
    final nameLen = _serverName.trim().runes.length;
    setState(() {
      _confirmEnable =
          nameLen > 0 && nameLen <= MAX_LENGTH && _avatarFile != null;
    });
  }

  Widget _buildButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildPreviousBtn(),
        sizeWidth12,
        _buildCreateBtn(),
      ],
    );
  }

  /// 上一步
  Widget _buildPreviousBtn() {
    return InkWell(
      onTap: () {
        Get.back();
        unawaited(Get.dialog(LandCreateGuildSelectTemplatePageView()));
      },
      child: Container(
        width: 88,
        height: 32,
        decoration: BoxDecoration(
            color: Get.theme.backgroundColor,
            border: Border.all(
              color: const Color(0xFFDEE0E3),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(4))),
        child: Center(
            child: Text(
          '上一步'.tr,
          // style: TextStyle(fontSize: 14, color: Color(0xFF17181A)),
          style: Get.textTheme.headline4.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        )),
      ),
    );
  }

  /// 创建按钮
  PrimaryButton _buildCreateBtn() {
    return PrimaryButton(
      label: '创建'.tr,
      loading: _loading,
      width: 88,
      height: 32,
      textStyle: const TextStyle(fontSize: 14, height: 1.17),
      borderRadius: 4,
      onPressed: !_confirmEnable
          ? null
          : () async {
              setState(() {
                _loading = true;
              });
              Loading.show(context, isEmpty: true);
              try {
                // final String avatar = _avatarFile == null
                //     ? ''
                //     : await uploadFileIfNotExist(
                //         bytes: _avatarFile, fileType: "headImage");
                final String avatar = _avatarFile == null
                    ? ''
                    : await CosFileUploadQueue.instance
                        .onceForBytes(_avatarFile, CosUploadFileType.headImage);

                final res = await GuildApi.createGuild(
                    name: _serverName.trim(),
                    icon: avatar,
                    userId: Global.user.id,
                    batchGuidType: widget.batchGuidType);

                PermissionModel.initGuildPermission(
                  guildId: res["guild_id"],
                  ownerId: res["owner_id"],
                  permissions: res['permissions'],
                  userRoles: res['userRoles'],
                  channels: res['channels'],
                  roles: res['roles'],
                );

                final GuildTarget target = GuildTarget.fromJson(res);

                /// 延迟 500ms 是为了服务器 push {type: string} 的消息被插入到本地数据库中
                await Future.delayed(const Duration(milliseconds: 500));

                setState(() {
                  _loading = false;
                });
                Loading.hide();
                Navigator.of(context).pop(target);

                final List<String> robotIds = res['robot_ids'].cast<String>();
                if (robotIds != null && robotIds.isNotEmpty) {
                  /// 如果有值，跳转到 配置服务器助手 页面
                  await Get.dialog(LandConfigGuildAssistantPageView(
                      RobotConfigInfo(robotIds, widget.batchGuidType, avatar,
                          _serverName.trim())));
                }
              } catch (e) {
                if (e is DioError) {
                  if (e is TimeoutException ||
                      e.type != DioErrorType.response) {
                    showToast(networkErrorText);
                  }
                }
                setState(() {
                  _loading = false;
                });
                Loading.hide();
              }
            },
//      child: const Text('创建服务器'.tr),
    );
  }
}
