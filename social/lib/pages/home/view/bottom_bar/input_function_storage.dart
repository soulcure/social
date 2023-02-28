import 'dart:async';
import 'dart:io';

import 'package:fb_ali_pay/fb_ali_pay.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/api/check_api.dart';
import 'package:im/api/entity/file_send_history_bean_entity.dart';
import 'package:im/api/redpack_api.dart';
import 'package:im/app/modules/file/file_manager/file_manager.dart';
import 'package:im/app/modules/redpack/send_pack/controllers/send_redpack_controller.dart';
import 'package:im/app/modules/redpack/send_pack/data/send_redpack_resp.dart';
import 'package:im/app/modules/redpack/send_pack/views/send_redpack_page.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/common/extension/string_extension.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/file_entity.dart';
import 'package:im/pages/home/json/message_card_entity.dart';
import 'package:im/pages/home/json/redpack_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/live_status_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/routes.dart';
import 'package:im/services/server_side_configuration.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/cos_file_download.dart';
import 'package:im/utils/file_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

const functionItemLineCount = 4;
// 图标宽44 + (右上角圆点:间隙 2 * 2 + 宽度 10)
const functionItemIconOuterWidth = 58.0;
const functionItemIconInnerWidth = 44.0;

typedef OnBottomVisible = void Function(bool visible, bool isPageBack);

/// - 输入框更多功能存放视图
/// - 红包/直播/文件
class InputFunctionsStorage extends StatefulWidget {
  final ChatChannel channel;

  /// 底部菜单是否可见
  final OnBottomVisible onBottomVisible;

  final InputModel inputModel;
  final bool needClearReply;

  const InputFunctionsStorage({
    Key key,
    @required this.channel,
    this.onBottomVisible,
    this.inputModel,
    this.needClearReply,
  }) : super(key: key);

  @override
  _InputFunctionsStorageState createState() => _InputFunctionsStorageState();
}

class _InputFunctionsStorageState extends State<InputFunctionsStorage> {
  bool _isProcessRedPacket = false;

  /// - 跳转到文件选择页面
  void _fileSelectTap() {
    widget.onBottomVisible?.call(true, false);
    Get.toNamed(app_pages.Routes.FILE_SELECT).then((value) {
      if (value == null) {
        widget.onBottomVisible?.call(true, true);
        return;
      }
      widget.onBottomVisible?.call(false, true);
      // value数组第一个为systemFile，表示点击手机存储，打开系统文件选择器
      if (value[0] == 'systemFile') {
        _pickFiles();
      } else if (value[0] == 'photo') {
        _pickSystemPhoto();
      } else {
        _sendHistory(value);
      }
    }).catchError((e) {
      widget.onBottomVisible?.call(false, true);
    });
  }

  /// - 调用我们自己的相册选择器
  Future _pickSystemPhoto() async {
    try {
      // 1、选择相册，返回的是凭证ids ,目前最多支持选择1个
      final result = await MultiImagePicker.pickImages(
          maxImages: 1,
          thumbType: FBMediaThumbType.file,
          cupertinoOptions: CupertinoOptions(
              takePhotoIcon: "chat",
              selectionStrokeColor:
                  "#${Theme.of(context).primaryColor.value.toRadixString(16)}",
              selectionFillColor:
                  "#${Theme.of(context).primaryColor.value.toRadixString(16)}"),
          materialOptions: MaterialOptions(
            allViewTitle: "所有图片".tr,
            selectCircleStrokeColor:
                "#${Theme.of(context).primaryColor.value.toRadixString(16)}",
          ));
      final List<String> identifiers = [];
      for (final item in result['identifiers']) {
        identifiers.add(item.toString());
      }
      // 2、根据凭证ids获取具体的文件信息
      final mediaList = await MultiImagePicker.fetchMediaInfo(
          0, identifiers.length,
          selectedAssets: identifiers);
      if (mediaList.isEmpty) {
        showToast('未能在图库中找到指定的图片，请确认图片是否已经从图库中删除'.tr);
      } else {
        // 监听app从后台到前台绘制第一帧再发送文件，是因为在ios上立即发送App.appLifecycleState!=AppLifecycleState.resumed,
        // 导致发送文件消息后，不能自动jump滑动到底部
        WidgetsBinding.instance.addPostFrameCallback((_) {
          mediaList.forEach((element) async {
            try {
              // filePath为空，则还需再次获取filePath
              String filePath = element.filePath;
              if (filePath?.isEmpty ?? true) {
                final filePathMap =
                    await MultiImagePicker.requestFilePath(element.identifier);
                filePath = filePathMap['filePath'].toString();
              }
              await _sendFile(File(filePath).lengthSync(), filePath);
            } catch (e, s) {
              logger.severe("上传文件失败:", e, s);
            }
          });
        });
      }
    } catch (e) {
      if (e is PlatformException && e.code == "PERMISSION_PERMANENTLY_DENIED") {
        await checkSystemPermissions(
          context: context,
          permissions: [
            if (UniversalPlatform.isIOS) permission_handler.Permission.photos,
            if (UniversalPlatform.isAndroid)
              permission_handler.Permission.storage
          ],
        );
      } else {
        print(e);
      }
    }
  }

  /// - 调用系统的文件选择器
  Future _pickFiles() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      unawaited(_sendFile(result.files.first.size, result.files.single.path));
    }
  }

  /// - 发送文件，进行文件大小和名称数美检测
  Future _sendFile(int fileSize, String filePath) async {
    if (fileSize > FileManager().getSupportMaxSize() * 1024 * 1024) {
      showToast('最大支持${FileManager().getSupportMaxSize()}MB'.tr);
    } else {
      // 这里由于数美对于包含@的信息，会判断为灌水行为，所以应他们要求，发送给他们的审核信息，去掉@
      final data = await CheckApi.postCheckText(
          FileUtil.getFileName(filePath).replaceAll('@', ''),
          widget.channel.id);
      if (data == null) return false;
      if (data['riskLevel'] == 'REJECT') {
        showToast(defaultErrorMessage);
        return;
      }
      unawaited(_sendOneFile(filePath));
    }
  }

  /// - 发送单个文件
  Future<void> _sendOneFile(String filePath) async {
    try {
      if (filePath != null && filePath.isNotEmpty) {
        final fileName = FileUtil.getFileName(filePath);
        // ios需要将文件copy到自身应用的缓存路径防止文件选择器删除文件
        if (UniversalPlatform.isIOS) {
          final fileNewPath = await CosDownObject.fileNativePath(fileName);
          if (!File(fileNewPath).existsSync()) {
            File(filePath).copySync(fileNewPath);
          }
          filePath = fileNewPath;
        }
        // 去正在上传的任务列表查看当前文件是否正在上传，防止重复上传
        final task = FileManager().fileUploadTasks.firstWhere((element) {
          return element.filePath == filePath;
        }, orElse: () => null);

        if (task != null) {
          final errorMsg = '$filePath正在上传中，请勿重复上传！'.tr;
          showToast(errorMsg);
          throw Exception(errorMsg);
        }

        final fileMd5 = await FileUtil.getFileMd5(filePath);
        final createTime = DateTime.now().millisecondsSinceEpoch;
        final entity = FileEntity(
          fileId: createTime.toString(),
          filePath: filePath,
          fileName: fileName,
          fileType: FileUtil.getFileType(fileName).index + 1,
          fileExt: FileUtil.getFileExt(fileName),
          fileSize: File(filePath).lengthSync(),
          fileHash: fileMd5 ?? '',
          // 目前只使用腾讯云
          cloudsvr: 1,
          fileDesc: '',
          created: createTime,
          client: UniversalPlatform.clientType(),
        );

        // 上传文件中...
        unawaited(TextChannelController.to(channelId: widget.channel.id)
            .sendContent(entity, reply: widget.inputModel.reply));
        _clearReply();
      }
    } catch (e) {
      if (e is PlatformException && e.code == "PERMISSION_PERMANENTLY_DENIED") {
        await checkSystemPermissions(
          context: context,
          permissions: [
            if (UniversalPlatform.isIOS) permission_handler.Permission.photos,
            if (UniversalPlatform.isAndroid)
              permission_handler.Permission.storage
          ],
        );
      } else {
        if (e.toString().contains('Is a directory')) {
          showToast('暂不支持文件夹'.tr);
        }
        print(e);
      }
    }
  }

  /// - 发送历史文件
  Future<void> _sendHistory(
      List<FileSendHistoryBeanEntity> fileEntityList) async {
    try {
      final List<MessageContentEntity> entities = [];
      int createTime = DateTime.now().millisecondsSinceEpoch;
      for (final fileEntity in fileEntityList) {
        if (fileEntity.fileUrl != null && fileEntity.fileUrl.isNotEmpty) {
          final entity = FileEntity(
            fileId: (createTime++).toString(),
            // 防止连续发送，导致fileId一样的问题
            filePath: fileEntity.path,
            fileUrl: fileEntity.fileUrl,
            fileName: fileEntity.name,
            fileType: FileUtil.getFileType(fileEntity.name).index + 1,
            fileExt: FileUtil.getFileExt(fileEntity.name),
            fileSize: fileEntity.size,
            fileHash: fileEntity.fileHash ?? '',
            // 目前只使用腾讯云
            cloudsvr: 1,
            fileDesc: '',
            created: createTime,
            client: UniversalPlatform.clientType(),
            bucketId: fileEntity.bucketId,
          );
          entities.add(entity);
        }
      }
      // 发送文件消息
      unawaited(TextChannelController.to(channelId: widget.channel.id)
          .sendContents(entities, relay: widget.inputModel.reply));
      _clearReply();
    } catch (e) {
      if (e is PlatformException && e.code == "PERMISSION_PERMANENTLY_DENIED") {
        await checkSystemPermissions(
          context: context,
          permissions: [
            if (UniversalPlatform.isIOS) permission_handler.Permission.photos,
            if (UniversalPlatform.isAndroid)
              permission_handler.Permission.storage
          ],
        );
      } else {
        print(e);
      }
    }
  }

  /// - 删除回复引用
  void _clearReply() {
    if (widget.needClearReply) {
      widget.inputModel.reply = null;
    }
  }

  Future<void> test() async {
    final String channelId = widget.channel.id;
    //'360458345422782464;13;1;360444722893815808;86654728397791232;1'
    final entity = CircleShareEntity();
    await TextChannelController.to(channelId: channelId).sendContent(entity);
  }

  ///发送支付宝红包
  Future<void> _redPacketItemTap() async {
    await test();
    showToast("send ok");
  }

  void _liveItemTap() {
    unawaited(Routes.pushChannelLivePage(context));
    DLogManager.getInstance().customEvent(
      actionEventId: 'live_list_entrance_click',
      actionEventSubId: 'click_channel_live_icon',
      extJson: {'guild_id': widget.channel.guildId},
    );
  }

  double _calculateStoragePadding() {
    return (MediaQuery.of(context).size.width -
            functionItemLineCount * functionItemIconInnerWidth) /
        (functionItemLineCount * 2 + 2);
  }

  @override
  Widget build(BuildContext context) {
    final GuildTarget target =
        ChatTargetsModel.instance.getChatTarget(widget.channel.guildId);
    // 显示频道直播的条件：
    // 1.服务器内有直播频道
    // 2.文字频道
    final _notifier = LiveStatusManager.instance.getNotifier(target?.id);
    final showLiveItem = (target?.hasLiveChannel ?? false) &&
        _notifier != null &&
        widget.channel?.type == ChatChannelType.guildText;

    final storagePadding = _calculateStoragePadding();

    return GridView(
      padding: EdgeInsets.only(
        top: 20,
        left: storagePadding,
        right: storagePadding,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: functionItemLineCount,
        mainAxisSpacing: 12,
      ),
      children: [
        if (showLiveItem)
          Builder(builder: (context) {
            return ValueListenableBuilder<GuildLivingStatus>(
                valueListenable: _notifier,
                builder: (context, livingStatus, child) {
                  final livingChannels = livingStatus.livingChannels ?? [];
                  final ChannelLivingStatus cls = livingChannels.firstWhere(
                    (element) => element.channelId == widget.channel.id,
                    orElse: () => null,
                  );
                  final isLiving = (cls?.livingCount ?? 0) > 0;
                  return StorageItem(
                    title: '频道直播'.tr,
                    itemTap: _liveItemTap,
                    iconData: IconFont.buffChatLive,
                    iconColor: CustomColor.orange,
                    showDot: isLiving,
                  );
                });
          }),
        StorageItem(
          title: '文件'.tr,
          itemTap: _fileSelectTap,
          iconData: IconFont.buffFile,
          iconColor: const Color(0xFF1979FE),
        ),
        if (widget.channel.guildId != Global.user.id)
          StorageItem(
            title: '红包'.tr,
            itemTap: _redPacketItemTap,
            iconData: IconFont.buffIconRedpack,
            iconColor: const Color(0xFFFE544F),
          ),
      ],
    );
  }
}

class StorageItem extends StatelessWidget {
  final String title;
  final Color iconColor;
  final IconData iconData;
  final bool showDot;
  final VoidCallback itemTap;

  const StorageItem({
    Key key,
    this.title,
    this.itemTap,
    this.iconData,
    this.iconColor,
    this.showDot = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: itemTap,
      child: Column(
        children: [
          SizedBox(
            width: functionItemIconOuterWidth,
            height: functionItemIconOuterWidth,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: functionItemIconInnerWidth,
                    height: functionItemIconInnerWidth,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: const BorderRadius.all(Radius.circular(7)),
                    ),
                    child: Icon(
                      iconData,
                      color: Theme.of(context).backgroundColor,
                      size: 22,
                    ),
                  ),
                ),
                Visibility(
                  visible: showDot,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).backgroundColor,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: DefaultTheme.dangerColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyText2.copyWith(
                  fontSize: 12,
                  height: 1.33,
                  color: const Color(0xFF363940),
                ),
          ),
        ],
      ),
    );
  }
}
