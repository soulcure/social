import 'package:flutter/material.dart';
import 'package:im/pages/home/json/text_chat_json.dart';

class ResendMessageNotification extends Notification {
  final MessageEntity message;

  ResendMessageNotification(this.message);
}
