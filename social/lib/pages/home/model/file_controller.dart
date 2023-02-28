import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/file_send_history_bean_entity.dart';
import 'package:im/app/modules/file/file_manager/file_manager.dart';
import 'package:im/app/modules/file/file_manager/file_task.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/json/file_entity.dart';
import 'package:im/utils/cos_file_download.dart';
import 'package:im/utils/file_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

import '../../../routes.dart';
import 'chat_index_model.dart';

/// - 描述：文件上传和下载的管理类
///
/// - author: seven
/// - data: 2021/10/21 3:49 下午
class FileController extends GetxController {
  /// 文件名称
  String fileName;

  /// 上传/下载进度
  double progressValue = 0;

  /// 文件的上传和下载任务
  FileTask fileTask;

  /// 是否是上传类型
  bool get isUploading =>
      fileTask != null && fileTask.taskType == TaskType.upload;

  /// 消息体的用户id
  String msgUserId;

  /// 任务Id
  String taskId;

  /// controller控制器的Id,fix:【查看文件】在下载中的文件，重复进入频道，进度条一下出现一下丢失。
  String tagId;

  /// 是否正在打开文件，防止重复点击
  bool isOpenFile = false;

  /// 文件保存路径
  String _fileSavePath;

  /// 文件实体类型
  FileEntity entity;

  /// 消息Id
  String messageId;

  static FileController to(
    String fileName,
    String msgUserId,
    String taskId,
    String tagId,
  ) {
    FileController c;
    try {
      c = Get.find<FileController>(tag: tagId);
    } catch (_) {}
    return c ??=
        Get.put(FileController(fileName, msgUserId, taskId, tagId), tag: tagId);
  }

  FileController(this.fileName, this.msgUserId, this.taskId, this.tagId);

  /// 当前有没有工作任务
  bool hasFileTask() => fileTask != null;

  @override
  void onInit() {
    super.onInit();
    fileTask = FileManager().getFileTask(taskId);
    progressValue = fileTask?.progressValue ?? 0;
    _addTaskListener();
  }

  @override
  void onClose() {
    fileTask = null;
    super.onClose();
  }

  /// - 添加文件的上传和下载任务
  void addFileTask(FileTask task) {
    fileTask = task;
    progressValue = 0;
    _addTaskListener();
    update();
  }

  /// - 任务监听回调
  void _addTaskListener() {
    if (fileTask == null) return;

    fileTask.onError = (fileId, e) {
      final errorToast = isUploading
          ? '文件上传失败，请检查网络'.tr
          : e.toString().contains('Invalid value')
              ? '文件不存在'.tr
              : '下载失败'.tr;
      uploadError(errorToast);
    };
    fileTask.onFinish = (fileId, downloadUrl) {
      // android 下载完提示下载到哪里，方便用户能在本地找到
      if (fileTask != null && fileTask.taskType == TaskType.download) {
        if (UniversalPlatform.isAndroid) {
          showToast('文件存储至:$_fileSavePath',
              duration: const Duration(seconds: 3));
        }
        // 当前为下载状态时，downloadUrl实际是存储路径
        entity.filePath = downloadUrl;
        FileSendHistoryBeanEntity.insertToDb(entity);
        _downloadFileEvent(messageId, entity.fileSize);
      }

      fileTask = null;
      update();
    };
    fileTask.onSendProgress = (fileId, progress) {
      progressValue = progress;
      update();
    };
    fileTask.onStatus = (fileId, status) {
      update();
    };
    fileTask.onDownloadProgress = (fileId, progress) {
      progressValue = progress;
      update();
    };
  }

  /// - 上传失败
  void uploadError(String errorToast) {
    showToast(errorToast);
    progressValue = 0;
    fileTask = null;
    update();
  }

  /// - 取消任务
  void cancelTask() {
    FileManager().cancelTask(fileTask);
    fileTask = null;
    progressValue = 0;
    isOpenFile = false;
    update();
  }

  /// - 当前文件的下载状态
  String fileCurrentStatusMsg(FileEntity entity) {
    if (fileTask == null) {
      return FileUtil.isFileExists(entity.filePath) ? '已下载'.tr : '';
    }

    if (fileTask.taskType == TaskType.upload) {
      return '正在上传 %s%'.trArgs([(progressValue * 100).round().toString()]);
    } else if (fileTask.taskType == TaskType.download) {
      return '正在下载 %s%'.trArgs([(progressValue * 100).round().toString()]);
    } else {
      return '';
    }
  }

  /// - 根据实体信息获取到本地缓存路径，再判断文件是否存在
  Future<String> fileSavePath(FileEntity entity) async {
    // 如果这个文件是别人发的，需要更新实体的存储路径
    // 如果是自己发的，但是换了手机也需要更新文件路径，所以这里就统一更新文件路径
    if (!FileUtil.isFileExists(entity.filePath) &&
        isNotNullAndEmpty(entity.fileUrl)) {
      // 注意fileManager中下载obj的create方法的参数，需要一致
      final filePath = UniversalPlatform.isIOS
          ? await CosDownObject.fileNativePath(fileName)
          : await CosDownObject.fileSavePath(
              entity.fileUrl,
              fileId: entity.fileUrl,
              fileName: entity.fileName,
            );
      _fileSavePath = filePath;
      if (entity.filePath != filePath) {
        entity.filePath = filePath;
        update();
      }
      return filePath;
    } else {
      return entity.filePath;
    }
  }

  /// - 打开文件 未下载就下载,载后就打开。
  /// - 1.如果这一条是自己上传的，并且本地文件存在，直接打开
  /// - 2.打开没有下载的文件，查看下载任务中有没有正在下载，没有则下载；
  /// - 下载完成后直接打开。如果当前已经下载好了，就直接打开。
  Future<void> openFile(BuildContext context, FileEntity entity) async {
    if (isOpenFile) return;
    isOpenFile = true;
    _openFileEvent(messageId);
    try {
      // 本地文件是否存在
      final fileExists = FileUtil.isFileExists(entity.filePath);

      if ((Global.user.id == msgUserId || fileTask == null) && fileExists) {
        // 1.如果这一条是自己上传的，并且本地文件存在，直接打开,包括正在上传的文件
        // 2.如果没有下载任务，并且本地文件存在，直接打开
        _openShare(context, entity);
      } else if (Global.user.id != msgUserId &&
          FileUtil.isOverDay(entity.created)) {
        // 不是自己上传的，还需要检测是否过期
        showToast('文件已过期'.tr);
      } else if (entity.fileUrl == null || entity.fileUrl.isEmpty) {
        showToast('文件不存在'.tr);
      } else if (FileManager().fileDownloadTasks.isNotEmpty &&
          FileManager()
              .fileDownloadTasks
              .where((element) => element.filePath == entity.fileUrl)
              .toList()
              .isNotEmpty) {
        // 如果当前有相同的url文件在下载，则提示
        showToast('文件正在下载'.tr);
      } else if (fileTask == null) {
        // 开启下载任务
        final task = FileTask(
          id: entity.fileId,
          taskType: TaskType.download,
          fileName: fileName,
          filePath: entity.fileUrl,
        );
        addFileTask(task);
        unawaited(FileManager().addDownloadTask(task));
      }

      // 1秒后执行,点击防抖
      Future.delayed(
          const Duration(milliseconds: 1000), () => isOpenFile = false);
    } catch (e) {
      // 取消下载，断网都能catch，需要将防抖复位
      isOpenFile = false;
    }
  }

  /// - 跳转到预览界面
  void _openShare(BuildContext context, FileEntity entity) {
    Routes.pushFilePreviewPage(context, entity);
  }

  /// - 上报点击文件埋点
  void _openFileEvent(String messageId) {
    final guildId = ChatTargetsModel.instance.selectedChatTarget.id;
    DLogManager.getInstance().customEvent(
      actionEventId: 'click_file',
      actionEventSubId: messageId.toString(),
      extJson: {"guild_id": guildId},
    );
  }

  /// - 上报文件下载埋点
  void _downloadFileEvent(String messageId, int fileSize) {
    final guildId = ChatTargetsModel.instance.selectedChatTarget.id;
    DLogManager.getInstance().customEvent(
      actionEventId: 'finish_download_file',
      actionEventSubId: messageId,
      actionEventSubParam: fileSize.toString(),
      extJson: {"guild_id": guildId},
    );
  }
}
