import 'package:im/api/entity/file_upload_setting.dart';
import 'package:im/api/upload_api.dart';
import 'package:im/utils/cos_file_download.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/utils/file_util.dart';

import 'file_task.dart';

/// - 描述：文件上传/下载管理类,单例类
///
/// - author: seven
/// - data: 2021/10/22 3:27 下午
class FileManager {
  static final FileManager _fileManager = FileManager._internal();

  factory FileManager() {
    return _fileManager;
  }

  /// - 文件上传配置
  FileUploadSetting fileUploadSetting;

  /// 文件的上传下载任务
  final List<FileTask> _fileUploadTasks = [];

  List<FileTask> get fileUploadTasks => _fileUploadTasks;

  /// 文件的下载任务
  final List<FileTask> _fileDownloadTasks = [];

  List<FileTask> get fileDownloadTasks => _fileDownloadTasks;

  List<FileTask> getFileTasks() => [..._fileUploadTasks, ..._fileDownloadTasks];

  FileManager._internal() {
    _getFileUploadConfig();
    _initUpload();
    _initDownload();
  }

  /// - 初始化下载器
  void _initDownload() {
    CosFileDownloadQueue.instance.registerCallback(
      onDownProgress: (fileId, progress) {
        // debugPrint('下载进度 :$fileId; $progress');
        final task = _fileDownloadTasks.firstWhere(
            (element) => element.filePath == fileId,
            orElse: () => null);
        task?.onDownloadProgress(fileId, progress);
        task?.progressValue = progress;
      },
      onFinish: (fileId, u) {
        // debugPrint('下载完成 :$fileId; $u');
        _fileDownloadTasks
            .firstWhere((element) => element.filePath == fileId,
                orElse: () => null)
            ?.onFinish(fileId, u);
        _removeDownloadTask(fileId);
      },
      onError: (fileId, e) {
        // debugPrint('下载错误 :$fileId; $e');
        _fileDownloadTasks
            .firstWhere((element) => element.filePath == fileId,
                orElse: () => null)
            ?.onError(fileId, e);
        _removeDownloadTask(fileId);
      },
    );
  }

  /// - 初始化上传监听
  void _initUpload() {
    CosFileUploadQueue.instance.registCallback(
        onSendProgress: (fileId, progress) {
      // debugPrint('上传进度 :$fileId; $progress');
      final task = _fileUploadTasks.firstWhere(
          (element) => element.filePath == fileId,
          orElse: () => null);
      task?.onSendProgress(fileId, progress);
      task?.progressValue = progress;
    }, onFinish: (fileId, downloadUrl) {
      // debugPrint('上传完成 :$fileId; $downloadUrl');
      _fileUploadTasks
          .firstWhere((element) => element.filePath == fileId,
              orElse: () => null)
          ?.onFinish(fileId, downloadUrl);
      _removeUpdateTask(fileId);
    }, onError: (fileId, e) {
      // debugPrint('上传错误 :$fileId; $e');
      _fileUploadTasks
          .firstWhere((element) => element.filePath == fileId,
              orElse: () => null)
          ?.onError(fileId, e);
      _removeUpdateTask(fileId);
    }, onStatus: (fileId, status) {
      // debugPrint('上传状态改变 :$fileId; $status');
      _fileUploadTasks
          .firstWhere((element) => element.filePath == fileId,
              orElse: () => null)
          ?.onStatus(fileId, status);
    });
  }

  /// - 上传异常、成功后删除任务
  void _removeUpdateTask(String fileId) {
    _fileUploadTasks.removeWhere((element) => element.filePath == fileId);
  }

  /// - 下载异常、成功后删除任务
  void _removeDownloadTask(String fileId) {
    _fileDownloadTasks.removeWhere((element) => element.filePath == fileId);
  }

  /// -下发上传配置接囗/api/common/setting 例如每个文件大细，下载/上传并行客的数目。
  /// - upload_number跟 download_number -1 ，是客户端自已计数算上传跟下载数
  Future _getFileUploadConfig() async {
    final response = await UploadApi.getFileUploadSetting();
    if (response['upload_setting'] != null) {
      fileUploadSetting =
          FileUploadSetting.fromJson(response['upload_setting']);

      // 应该要获取系统cpu的核心数量，倒是考虑到获取各种平台cpu比较复杂，这里就默认统一为4
      CosFileUploadQueue.instance.maxConcurrentOperationCount =
          fileUploadSetting.uploadNumber > 0
              ? fileUploadSetting.uploadNumber
              : 4;
      CosFileDownloadQueue.instance.maxConcurrentOperationCount =
          fileUploadSetting.downloadNumber > 0
              ? fileUploadSetting.downloadNumber
              : 4;
    }
  }

  /// - 添加上传任务
  /// - 返回url和存储桶
  Future<List<String>> addUploadTask(FileTask task) async {
    _fileUploadTasks.add(task);
    final obj = await CosPutObject.create(
      task.filePath,
      _getUploadType(task.fileName),
      fileId: task.filePath,
      forceAudit: true,
    );
    try {
      final fileUrl =
          await CosFileUploadQueue.instance.executeCompeterTask(obj);
      final fileBucket = obj.bucket ?? '';
      return [fileUrl, fileBucket];
    } catch (e) {
      // 文件发送失败之后，从队列删除该任务
      // 或者重新上传的时候,通过CosFileUploadQueue.instance.findPutObject(fileId)拿到putObject而不是create一个新实例
      CosFileUploadQueue.instance.removeQueueItem(obj);
      rethrow;
    }
  }

  /// - 类型转化
  CosUploadFileType _getUploadType(String fileName) {
    switch (FileUtil.getFileType(fileName)) {
      case FileType.picture:
        return CosUploadFileType.image;
      case FileType.video:
        return CosUploadFileType.video;
      case FileType.audio:
        return CosUploadFileType.audio;
      case FileType.document:
      case FileType.zip:
        if (fileName.trim().endsWith('.pdf')) return CosUploadFileType.pdf;
        return CosUploadFileType.txt;
      default:
        return CosUploadFileType.unKnow;
    }
  }

  /// - 添加下载任务
  Future<String> addDownloadTask(FileTask task) async {
    _fileDownloadTasks.add(task);
    // 下载传入文件的创建名称
    final downloadObj = await CosDownObject.create(
      task.filePath,
      fileId: task.filePath,
      fileName: task.fileName,
    );
    return CosFileDownloadQueue.instance.executeCompeterTask(downloadObj);
  }

  /// - 找到对应的任务
  FileTask getFileTask(String taskId) => getFileTasks()
      .firstWhere((element) => element.id == taskId, orElse: () => null);

  /// - 最大支持文件上传大小
  int getSupportMaxSize() => fileUploadSetting?.size ?? 500;

  /// - 取消任务
  void cancelTask(FileTask fileTask) {
    if (_fileUploadTasks.contains(fileTask)) {
      _fileUploadTasks.remove(fileTask);
      CosFileUploadQueue.instance.cancel(fileTask.filePath);
    } else if (_fileDownloadTasks.contains(fileTask)) {
      _fileDownloadTasks.remove(fileTask);
      CosFileDownloadQueue.instance.cancel(fileTask.filePath);
    }
  }
}
