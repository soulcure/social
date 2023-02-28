import 'package:flutter_test/flutter_test.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/in_memory_db.dart';

void main() {
  final list = MessageList.forTest("cid");

  setUp(() {
    List.generate(5, (index) {
      /// 倒序插入有序集合
      index = 5 - 1 - index;
      list.add(MessageEntity("", "cid", "uid", "gid", DateTime.now(),
          TextEntity(text: "text $index"),
          messageId: index.toString()));
    });
  });

  test('firstValidMessage', () {
    expect(list.firstValidMessage.messageIdBigInt, BigInt.from(0));

    list.firstValidMessage.localStatus = MessageLocalStatus.illegal;
    expect(list.firstValidMessage.messageIdBigInt, BigInt.from(1));
  });

  test('forEach', () {
    list.forEach((e) {
      (e.content as TextEntity).text += "modified";
    });

    for (final e in list.list) {
      assert((e.content as TextEntity).text.endsWith("modified"));
    }
  });

  test("updateMessageId", () {
    final oid = BigInt.from(0);
    final nid = BigInt.from(100);
    var m = list.get(oid);
    list.updateMessageId(nid, m);
    m = list.get(nid);
    expect(m.messageId, nid.toString(), reason: "新 messageId 必须为 100");
    expect(m.messageIdBigInt, BigInt.from(100),
        reason: "新 messageIdBigInt 必须为 100");
  });
}
