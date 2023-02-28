// To parse this JSON data, do
//
//     final replyMarkup = replyMarkupFromJson(jsonString);

import 'dart:convert';

class ReplyMarkup {
  ReplyMarkup({
    this.inlineKeyboard,
    this.keyboard,
    this.selective,
    this.removeKeyboard,
  });

  final List<List<InlineKeyboardData>> inlineKeyboard;
  final List<List<Keyboard>> keyboard;
  final bool selective;
  final bool removeKeyboard;

  factory ReplyMarkup.fromRawJson(String str) =>
      ReplyMarkup.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReplyMarkup.fromJson(Map<String, dynamic> json) => ReplyMarkup(
        inlineKeyboard: json["inline_keyboard"] == null
            ? null
            : List<List<InlineKeyboardData>>.from(json["inline_keyboard"].map(
                (x) => List<InlineKeyboardData>.from(
                    x.map((x) => InlineKeyboardData.fromJson(x))))),
        keyboard: json["keyboard"] == null
            ? null
            : List<List<Keyboard>>.from(json["keyboard"].map((x) =>
                List<Keyboard>.from(x.map((x) => Keyboard.fromJson(x))))),
        selective: json["selective"],
        removeKeyboard: json["remove_keyboard"],
      );

  Map<String, dynamic> toJson() => {
        "inline_keyboard": inlineKeyboard == null
            ? null
            : List<dynamic>.from(inlineKeyboard
                .map((x) => List<dynamic>.from(x.map((x) => x.toJson())))),
        "keyboard": keyboard == null
            ? null
            : List<dynamic>.from(keyboard
                .map((x) => List<dynamic>.from(x.map((x) => x.toJson())))),
        "selective": selective,
        "remove_keyboard": removeKeyboard,
      };
}

class InlineKeyboardData {
  InlineKeyboardData({
    this.text,
    this.url,
    this.appId,
    this.callbackData,
  });

  final String text;
  final String appId;
  final String url;
  final String callbackData;

  factory InlineKeyboardData.fromRawJson(String str) =>
      InlineKeyboardData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory InlineKeyboardData.fromJson(Map<String, dynamic> json) =>
      InlineKeyboardData(
        text: json["text"],
        url: json["url"],
        appId: json["app_id"],
        callbackData: json["callback_data"],
      );

  Map<String, dynamic> toJson() => {
        "text": text,
        "url": url,
        "app_id": appId,
        "callback_data": callbackData,
      };
}

class Keyboard {
  Keyboard({
    this.text,
  });

  final String text;

  factory Keyboard.fromRawJson(String str) =>
      Keyboard.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Keyboard.fromJson(Map<String, dynamic> json) => Keyboard(
        text: json["text"],
      );

  Map<String, dynamic> toJson() => {
        "text": text,
      };
}
