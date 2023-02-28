import 'package:hive/hive.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/json/file_entity.dart';

import '../../global.dart';

part 'file_send_history_bean_entity.g.dart';

/// - 文件收发的数据库bean
@HiveType(typeId: 19)
class FileSendHistoryBeanEntity extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int size;

  @HiveField(2)
  int updateTime;

  @HiveField(3)
  String path;

  @HiveField(4)
  String fileHash;

  @HiveField(5)
  String fileUrl;

  @HiveField(6)
  String bucketId;

  bool isSelected;

  FileSendHistoryBeanEntity({
    this.name,
    this.size,
    this.updateTime,
    this.path,
    this.fileHash,
    this.fileUrl,
    this.bucketId,
    this.isSelected = false,
  });

  /// - 插入到本地数据库
  static void insertToDb(FileEntity fileEntity) {
    final historyBean = FileSendHistoryBeanEntity(
        name: fileEntity.fileName,
        path: fileEntity.filePath,
        size: fileEntity.fileSize,
        fileHash: fileEntity.fileHash,
        fileUrl: fileEntity.fileUrl,
        bucketId: fileEntity.bucketId,
        updateTime: DateTime.now().millisecondsSinceEpoch);
    final fileHistoryList = Db.fileSendHistoryBox.get(Global.user.id) ?? [];
    //将历史同名文件更新，防止重复显示
    fileHistoryList.removeWhere((element) =>
        (element as FileSendHistoryBeanEntity).fileUrl == fileEntity.fileUrl);
    fileHistoryList.insert(0, historyBean);
    Db.fileSendHistoryBox.put(Global.user.id, fileHistoryList);
  }
}
