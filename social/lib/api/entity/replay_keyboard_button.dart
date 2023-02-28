import "../entity/replay_keyboard_button_poll_type.dart";

class EntityReplayKeyboardButton {
  String text;
  bool requestContact;
  bool requestLocation;
  EntityReplayKeyboardButtonPollType requestPoll;

  EntityReplayKeyboardButton.fromJson(Map<String, dynamic> json) {
    text = json["text"];
    requestContact = json["request_contact"];
    requestLocation = json["request_location"];
    requestPoll = EntityReplayKeyboardButtonPollType.fromJson(json["request_poll"]);
  }
}
