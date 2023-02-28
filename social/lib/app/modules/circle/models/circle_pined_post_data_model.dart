import 'package:im/app/modules/circle/models/circle_post_data_model.dart';

class CirclePinedPostDataModel {
  String listId;
  String typeId;
  String typeName;
  String title;
  String channelId;
  String topicId;
  String postId;
  String guildId;
  String createAt;
  CirclePostDataModel post;

  CirclePinedPostDataModel({
    this.listId = '',
    this.typeId = '',
    this.guildId = '',
    this.typeName = '',
    this.title = '',
    this.channelId = '',
    this.topicId = '',
    this.postId = '',
    this.createAt = '',
    this.post,
  });

  factory CirclePinedPostDataModel.fromJson(Map<String, dynamic> json) =>
      CirclePinedPostDataModel(
        channelId: (json['channel_id'] ?? '').toString(),
        listId: (json['list_id'] ?? '').toString(),
        createAt: (json['created_at'] ?? '').toString(),
        guildId: (json['guild_id'] ?? '').toString(),
        postId: (json['post_id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        topicId: (json['topic_id'] ?? '').toString(),
        typeId: (json['type_id'] ?? '').toString(),
        typeName: (json['type_name'] ?? '').toString(),
        post: json['post'] != null
            ? CirclePostDataModel.fromJson(json['post'])
            : null,
      );
}
