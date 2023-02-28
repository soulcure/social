import 'package:flutter_test/flutter_test.dart';
import 'package:im/pages/home/json/text_chat_json.dart';

void main() {
  group("patterns in TextEntity", () {
    test("at pattern", () {
      expect(TextEntity.atPattern.hasMatch(r"${@!12345678}"), isTrue);
      expect(TextEntity.atPattern.hasMatch(r"${@&12345678}"), isTrue);
      expect(TextEntity.atPattern.hasMatch(r"${@#12345678}"), isFalse);
      expect(TextEntity.atPattern.hasMatch(r"${@!abcdefgh}"), isFalse);
      expect(TextEntity.atPattern.hasMatch(r"${@!a1234567}"), isFalse);
    });
    test("at pattern in incomplete message", () {
      expect(TextEntity.atPatternIncomplete.hasMatch("@!12345678"), isTrue);
      expect(TextEntity.atPatternIncomplete.hasMatch("@&12345678"), isTrue);
      expect(TextEntity.atPatternIncomplete.hasMatch("@#12345678"), isFalse);
      expect(TextEntity.atPatternIncomplete.hasMatch("@!abcdefgh"), isFalse);
      expect(TextEntity.atPatternIncomplete.hasMatch("@&abcdefgh"), isFalse);
    });
    test("command pattern", () {
      expect(TextEntity.commandPattern.hasMatch(r"${/send}"), isTrue);
      expect(TextEntity.commandPattern.hasMatch(r"${/se nd}"), isTrue);
      expect(TextEntity.commandPattern.hasMatch(r"${send}"), isFalse);
    });
    test ("url pattern", () {
      expect(TextEntity.urlPattern.hasMatch("https://www.baidu.com/123/abc"), isTrue);
      expect(TextEntity.urlPattern.hasMatch("http://192.168.1.1:8000/abc"), isTrue);
      expect(TextEntity.urlPattern.hasMatch("http://localhost"), isFalse);
      expect(TextEntity.urlPattern.hasMatch("ftp://www.baidu.com/123/abc"), isFalse );
    });
  });
}
