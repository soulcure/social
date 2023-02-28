import 'package:im/pages/home/json/text_chat_json.dart';

class VoteEntity extends MessageContentEntity {
  final String url;
  final String voteId;
  final Map content;

  VoteEntity({
    this.url,
    this.voteId,
    this.content,
  }) : super(MessageType.vote);

  Map<String, dynamic> toMap() {
    return {
      'type': typeInString,
      'url': url ?? '',
      'vote_id': voteId,
      'content': content ?? {},
    };
  }

  factory VoteEntity.fromJson(Map<String, dynamic> map) {
    return VoteEntity(
      url: map['url'],
      voteId: map['vote_id'],
      content: map['content'],
    );
  }

  @override
  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() {
    return 'TaskEntity(rule: $type, url: $url, voteId: $voteId, content: $content)';
  }
}
