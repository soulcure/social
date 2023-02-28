import 'package:flutter_test/flutter_test.dart';
import 'package:im/utils/fb_encryption.dart';

void main() {
  test("test encrypt phone number", () {
    expect(fbEncrypt("17601270422"), "8jsG8zUCdDwk8TY=");
    expect(fbEncrypt("oq9uhmdPag8MHf69"), "LnUJNmR9p1xRpDRdi2IG+g==");
  });
}
