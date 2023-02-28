import 'package:flutter/material.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/universal_rich_input_controller.dart';

abstract class RichInputPopupBase extends StatefulWidget {
  RichInputPopupBase richInputPopup(
      {MessageEntity originMessage,
      UniversalRichInputController inputController,
      MessageEntity reply,
      bool replyDetailPage,
      @required String cacheKey});
}
