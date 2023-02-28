import 'package:im/pages/home/json/text_chat_json.dart';

class DuEntity extends MessageContentEntity {
  String userId;
  String url;
  String voteId;
  int isVoted;
  Map xpath;

  DuEntity({this.userId, this.url, this.voteId, this.isVoted, this.xpath})
      : super(MessageType.du);

  factory DuEntity.fromJson(Map<String, dynamic> json) {
    return DuEntity(
      userId: json['userId'],
      url: json['url'],
      voteId: json['voteId'],
      isVoted: json['isVoted'],
      xpath: json['xpath'],
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = typeInString;
    data['userId'] = userId;
    data['url'] = url;
    data['voteId'] = voteId;
    data['isVoted'] = isVoted;
    data['xpath'] = xpath;
    return data;
  }

  @override
  Map<String, dynamic> toJson() => toMap();
}
