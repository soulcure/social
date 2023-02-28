import 'package:hive/hive.dart';

part 'dlog_report_model.g.dart';

@HiveType(typeId: 17)
class DLogReportModel extends HiveObject {
  /// 日志唯一id
  @HiveField(0)
  String dlogContentID;

  /// 日志上报内容
  @HiveField(1)
  String dlogContent;

  /// 日志数据库中的自增id
  String seqID;

  DLogReportModel({this.dlogContentID, this.dlogContent, this.seqID});

  Map<String, dynamic> toJson() => {
        'dlogContentID': dlogContentID ?? '',
        'dlogContent': dlogContent ?? '',
        'seqID': seqID ?? '',
      };
}
