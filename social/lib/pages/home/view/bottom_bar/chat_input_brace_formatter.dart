import 'package:im/pages/home/model/universal_rich_input_controller.dart';

/// 解决安卓平台聊天框用qq输入法单次输入成对括号后光标位置偏移量异常问题
/// 输入法在单次输入成对括号会触发两次valueChang事件，第一次是内容变化，第二次是光标偏移
/// 而只有内容变化才会转发到TextInput的inputFormatters中进行处理，因此无法通过添加一个formatter来进行光标偏移校正
class ChatInputBraceTextFormatter {
  /// 下列所有成对符号通过qq输入法符号键盘单次输入时都会出现自动向左偏移量3的情况
  static const BraceList = [
    "<>",
    "[]",
    "［］",
    "{}",
    "｛｝",
    "()",
    "〈〉",
    "''",
    '""',
    "《》",
    "【】",
    "「」",
    "（）",
    '“”',
    "‘’",
    "〔〕",
    "『』",
    "「」",
    "〖〗",
  ];

  static String lastInputValue = "";
  static num lastSelectionOffset = 0;
  static bool isBraceInput = false;

  static void checkInputBraceStatus(UniversalRichInputController controller) {
    final String newText = controller.text;
    final num newOffset = controller.offset;
    // logger.info("聊天框原有值：${lastInputValue} 光标位置：${lastSelectionOffset}");
    // logger.info("聊天框当前值：${newText} 光标位置：${newOffset}");
    if (lastSelectionOffset == -1 || newOffset == -1) {
      isBraceInput = false;
      return;
    }

    if (newText != lastInputValue) {
      final String prefix = lastInputValue.substring(0, lastSelectionOffset);
      final String postfix = lastSelectionOffset == lastInputValue.length
          ? ""
          : lastInputValue.substring(
              lastSelectionOffset, lastInputValue.length);

      isBraceInput =
          BraceList.any((element) => newText == "$prefix$element$postfix");
      if (isBraceInput) {
        // logger.info("本次输入了成对括号");
      }

      lastInputValue = newText;
      lastSelectionOffset = newOffset;
    } else {
      /// 在上一次输入了成对括号的情况下再出现光标左偏移量为3的事件，则拦截当前事件改为向左偏移1位
      if (isBraceInput && lastSelectionOffset - newOffset == 3) {
        // logger.info("检测到输入成对括号后左偏移3事件,触发校正光标位置");
        final correctOffset =
            lastSelectionOffset - 1 < 0 ? 0 : lastSelectionOffset - 1;
        controller.offset = correctOffset;
        isBraceInput = false;
        lastSelectionOffset = correctOffset;
      } else {
        lastSelectionOffset = newOffset;
      }
    }
  }
}
