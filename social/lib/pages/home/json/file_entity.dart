import 'package:get/get.dart';
import 'package:im/api/entity/file_send_history_bean_entity.dart';
import 'package:im/app/modules/file/file_manager/file_manager.dart';
import 'package:im/app/modules/file/file_manager/file_task.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/file_controller.dart';
import 'package:im/utils/utils.dart';

import '../../../global.dart';

/*
5.file_name   // 文件名
6.file_url  // 完整url
7.file_type  // 文件类型，1：图片，2：视频，3：音频，4：普通文档，5：压缩文档
8.file_ext //文件后缀
9.file_size  //  单位，kb，一个小数点
10.created //创建时间
11.status // 0,正常，1：封禁，2：疑似敏感，-1：审核失败，-2：尚未审核
12.file_hash  //文件hash值
13.cloudsvr// 1：腾讯云，2：阿里云，3：百度云，4：亚马逊云，5：谷歌云，6：电信云
14.file_desc // 文件描述
15.updated //更新时间
16.client // 1:android,2:ios,3:web,4:小程序，5：win pc，6：linux pc
17.file_id // 目前是时间戳，作为这个消息体的唯一标识
*/

/// - 文件收发实体类
class FileEntity extends MessageContentEntity {
  /// 文件的唯一id，目前使用时间戳，用于创建上传和下载的任务Id和刷新控件
  /// 作为这个客户端重复文件的唯一标识
  String fileId;
  String fileName;
  String fileUrl;
  int fileType;
  String fileExt;
  int fileSize;
  int created;
  int status;
  String fileHash;
  int cloudsvr;
  String fileDesc;
  int updated;
  int client;
  String filePath;
  String bucketId;

  /// 本地getx的controller需要用到
  String controllerTagId;

  FileEntity({
    this.fileId,
    this.fileName,
    this.fileUrl,
    this.fileType,
    this.fileExt,
    this.fileSize,
    this.created,
    this.status,
    this.fileHash,
    this.cloudsvr,
    this.fileDesc,
    this.updated,
    this.client,
    this.filePath,
    this.bucketId,
  }) : super(MessageType.file);

  factory FileEntity.fromJson(Map<String, dynamic> json) {
    return FileEntity(
      fileId: json['file_id'],
      fileName: json['file_name'],
      fileUrl: json['file_url'],
      fileType: json['file_type'],
      fileExt: json['file_ext'],
      fileSize: json['file_size'],
      created: json['created'],
      status: json['status'],
      fileHash: json['file_hash'],
      cloudsvr: json['cloudsvr'],
      fileDesc: json['file_desc'],
      updated: json['updated'],
      client: json['client'],
      filePath: json['file_path'],
      bucketId: json['bucket_id'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = typeInString;
    data['file_name'] = fileName;
    data['file_url'] = fileUrl;
    data['file_type'] = fileType;
    data['file_ext'] = fileExt;
    data['file_size'] = fileSize;
    data['created'] = created;
    data['status'] = status;
    data['file_hash'] = fileHash;
    data['cloudsvr'] = cloudsvr;
    data['file_desc'] = fileDesc;
    data['updated'] = updated;
    data['client'] = client;
    data['file_path'] = filePath;
    data['file_id'] = fileId;
    data['bucket_id'] = bucketId;
    return data;
  }

  Future<String> toNotificationString() async {
    return '[文件] $fileName'.tr;
  }

  /// - 上传文件
  @override
  Future startUpload({String channelId}) async {
    await super.startUpload(channelId: channelId);
    if (fileName == null || fileName.isEmpty) {
      return;
    }
    if (isNotNullAndEmpty(fileUrl)) {
      // 表明这是一条文件转发消息，不进行文件上传操作,更新本地数据记录的时间
      FileSendHistoryBeanEntity.insertToDb(this);
      return;
    }

    final task = FileTask(
      id: fileId,
      taskType: TaskType.upload,
      filePath: filePath,
      fileName: fileName,
    );
    try {
      FileController.to(fileName, Global.user.id, fileId, controllerTagId)
          .addFileTask(task);
      final result = await FileManager().addUploadTask(task);

      fileUrl = result[0];
      bucketId = result[1];
      FileSendHistoryBeanEntity.insertToDb(this);
    } catch (e) {
      throw Exception('上传失败');
    }
  }
}
