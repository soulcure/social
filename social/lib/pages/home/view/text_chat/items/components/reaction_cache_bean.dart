import 'package:hive/hive.dart';

part 'reaction_cache_bean.g.dart';

@HiveType(typeId: 20)
class ReactionCacheBean extends HiveObject {
  @HiveField(0)
  String channelId;

  @HiveField(1)
  String messageId; //未完成任务频道

  @HiveField(2)
  String emojiName;

  @HiveField(3)
  int count;

  ReactionCacheBean();

  ReactionCacheBean.formValue(this.channelId, this.messageId, this.emojiName,
      [this.count = 0]);

  String getKey() {
    return '$messageId#${Uri.encodeComponent(emojiName)}';
  }
}
