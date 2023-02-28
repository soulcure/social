import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:im/utils/emo_util.dart';
import 'package:im/utils/rsa_util.dart';

void main() {
  test('测试加密解密', () {
    const data =
        'dWTZd8QD/Mxx5iaQYgxSe6zAVeGen5oSx4LSG31lY16A5Ebn3urNSFbGHWJeJxvEuSFU4VVcIQbDUm6baM23qaiPXutiYxanpqoksDerjak8plVTd9kmX1lQTbvBqCD4KfdCaD3YXyIZkFlCX8cr5Da4UqG2AvTt4OVgbs3Wjo0=';
    final result = decodeString(data);
    print('result:\n$result');
  });

  test('测试数据', () {
    for (int i = 0; i < 200; i++) {
      final total = Random().nextInt(1000);
      final row = Random().nextInt(50) + 1;
      final res = EmoUtil.instance.buildGrid(total, row);
      int realTotal = 0;
      res.forEach((element) {
        realTotal += element;
      });
      print('total:$total   row:$row     realTotal:$realTotal');
      assert(total == realTotal);
    }
  });
}
