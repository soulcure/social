import 'package:flutter_test/flutter_test.dart';
import 'package:im/pages/home/json/text_chat_json.dart';

void main() {
  test("fromJson: wrong rich text format", () {
    final m = MessageEntity.fromJson({
      "channel_id": "113839649427820544",
      "message_id": "189713641879109632",
      "content":
          // ignore: avoid_escaping_inner_quotes
          "{\"type\":\"richText\",\"title\":\"签到成功\",\"document\":[{\"insert\":\"恭喜你签到成功\"}]}",
      "user_id": "162831471348809728",
      "quote_l1": null,
      "quote_l2": null,
      "recalled": 0,
      "reactions": [],
      "recall": null,
      "pin": "0",
      "guild_id": "113837472030396416",
      "mentions": null,
      "mention_roles": null,
      "mention_everyone": null,
      "reply_markup": null,
      "time": 1610454144934,
      "author": {
        "nickname": "机器好人",
        "username": "425353",
        "avatar":
            "https://fb-cdn.fanbook.mobi/x-project/user-upload-files/d42ca330d93d88e0e7c19e2b2fe42fb5.jpg"
      },
      "member": {"nick": null, "roles": []}
    });
    expect(m, null);
  });
}
