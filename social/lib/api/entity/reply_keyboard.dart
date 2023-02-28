import "../entity/replay_keyboard_button.dart";

class EntityReplyKeyboard {
  List<EntityReplayKeyboardButton> keyboard;
  bool resizeKeyboard;
  bool oneTimeKeyboard;
  bool selective;

  EntityReplyKeyboard.fromJson(Map<String, dynamic> json) {
    if (json["keyboard"] != null) {
      keyboard = List.from(
        json["keyboard"].map(
          (v) => EntityReplayKeyboardButton.fromJson(v),
        ),
      );
    }
    resizeKeyboard = json["resize_keyboard"];
    oneTimeKeyboard = json["one_time_keyboard"];
    selective = json["selective"];
  }
}
