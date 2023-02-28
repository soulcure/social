import 'package:flutter/cupertino.dart';
import 'package:im/pages/home/model/universal_rich_input_controller.dart';

enum MatchInputContentCode {
  DELETE_CHAR,
  ENTER_CHAR,
  MATCH,
  NO_MATCH,
}

class MatchInputContentResult {
  MatchInputContentCode code;
  int matchIndex;
  int caretIndex;

  MatchInputContentResult({this.code, this.matchIndex, this.caretIndex});
}

class TextFieldUtils {
  static MatchInputContentResult matchInputContent(
      {UniversalRichInputController inputController,
      @required String matchChar}) {
    final text = inputController.text;
    final caretIndex = inputController.selection.start;

    final matchIndex =
        caretIndex == -1 ? -1 : text.lastIndexOf(matchChar, caretIndex);

    if (matchIndex == -1)
      return MatchInputContentResult(code: MatchInputContentCode.NO_MATCH);

    if (text.isEmpty || caretIndex == -1 || matchIndex == caretIndex) {
      /// 说明删掉了 @ 字符
      /// 虽然删除了字符，但是上一个（如果有）字符还是匹配
      if (caretIndex > 0 && text[caretIndex] == matchChar) {
        return MatchInputContentResult(
          code: MatchInputContentCode.ENTER_CHAR,
          matchIndex: matchIndex,
          caretIndex: caretIndex,
        );
      }

      /// 删除了字符，并且上一个字符不匹配
      return MatchInputContentResult(
        code: MatchInputContentCode.DELETE_CHAR,
        matchIndex: matchIndex,
        caretIndex: caretIndex,
      );
    } else if (matchIndex + 1 == caretIndex) {
      /// 说明输入了 @ 字符
      return MatchInputContentResult(
        code: MatchInputContentCode.ENTER_CHAR,
        matchIndex: matchIndex,
        caretIndex: caretIndex,
      );
    } else {
      /// 说明在过滤 @ 对象
      final aPartOfNickname = text.substring(matchIndex + 1, caretIndex);
      if (!aPartOfNickname.contains(' ')) {
        return MatchInputContentResult(
          code: MatchInputContentCode.MATCH,
          matchIndex: matchIndex,
          caretIndex: caretIndex,
        );
      }
    }

    return MatchInputContentResult(code: MatchInputContentCode.NO_MATCH);
  }

  static String getCharBeforeCaret(UniversalRichInputController controller) {
    if (controller.selection.start == -1 || controller.text.isEmpty)
      return null;
    return controller.text[controller.selection.start];
  }
}
