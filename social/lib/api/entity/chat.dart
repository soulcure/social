import '../entity/message.dart';
import '../entity/permissions.dart';
import '../entity/photo.dart';

class EntityChat {
  int id;

  /// Type of chat, can be either “private”, “group”, “supergroup” or “channel”
  String type;

  /// Optional. Title, for supergroups, channels and group chats
  String title;

  /// Optional. Username, for private chats, supergroups and channels if available
  String username;
  String firstName;
  String lastName;
  EntityPhoto photo;
  String description;
  String inviteLink;
  EntityMessage pinnedMessage;
  EntityPermissions permissions;
  int slowModeDelay;
  String stickerSetName;
  bool canSetStickerSet;

  EntityChat.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    title = json['title'];
    username = json['username'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    photo = EntityPhoto.fromJson(json['photo']);
    description = json['description'];
    inviteLink = json['invite_link'];
    pinnedMessage = EntityMessage.fromJson(json['pinned_message']);
    permissions = EntityPermissions.fromJson(json['permissions']);
    slowModeDelay = json['slow_mode_delay'];
    stickerSetName = json['sticker_set_name'];
    canSetStickerSet = json['can_set_sticker_set'];
  }
}
