class EntityReplyKeyboardRemove {
  bool removeKeyboard;
  bool selective;

  EntityReplyKeyboardRemove.fromJson(Map<String, dynamic> json) {
    removeKeyboard = json["remove_keyboard"];
    selective = json["selective"];
  }
}
