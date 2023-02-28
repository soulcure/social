import 'package:im/utils/cos_file_download.dart';
import 'package:im/utils/cos_file_upload.dart';

/// - 描述：文件上传/下载的任务
///
/// - author: seven
/// - data: 2021/10/22 3:50 下午

enum FileStatus {
  not_exist, //本地不存在
  uploading, //上传中
  downloading, //下载中
  exist, //本地存在
}

/// 任务类型 上传/下载
enum TaskType {
  upload,
  download,
}

/// 任务上传下载的任务
class FileTask {
  /// 任务id，这里是文件的名称作为id
  String id;

  TaskType taskType;

  /// 文件的路径
  String fileName;

  /// 文件的路径
  String filePath;

  /// 当前文件的状态
  FileStatus fileStatus;

  /// 进度反馈值
  double progressValue;

  /// 反馈回调
  UploadProgressCallback onSendProgress;
  UploadErrorCallback onError;
  UploadFinishCallback onFinish;
  UploadStatusCallback onStatus;

  /// 下载进度条
  DownProgressCallback onDownloadProgress;

  FileTask({
    this.id,
    this.taskType,
    this.fileName,
    this.filePath,
    this.fileStatus,
    this.progressValue,
  });
}
