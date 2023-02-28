import 'package:hive/hive.dart';

part 'last_reaction_item.g.dart';

@HiveType(typeId: 21)
class LastReactionItem extends HiveObject {
  @HiveField(0)
  String emojiName;
  @HiveField(1)
  int count;

  LastReactionItem(this.emojiName, this.count);
}
