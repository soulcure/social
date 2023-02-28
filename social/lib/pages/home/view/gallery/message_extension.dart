import 'package:im/pages/home/json/text_chat_json.dart';

extension HeroEntity on MessageEntity {
  String get heroTag {
    String res = messageId;
    if (content.runtimeType == VideoEntity) {
      final video = content as VideoEntity;
      var identifier = video?.asset?.identifier ?? video.localIdentify;
      if (identifier != null) identifier += '${time.microsecondsSinceEpoch}';
      res = identifier ?? messageId;
    } else if (content.runtimeType == ImageEntity) {
      final image = content as ImageEntity;
      var identifier = image?.asset?.identifier ?? image.localIdentify;
      if (identifier != null) identifier += '${time.microsecondsSinceEpoch}';
      res = identifier ?? messageId;
    }
    final result = res + (shareParentId ?? '');
    return result;
  }

  bool isTag(String tag) {
    return tag == (messageId ?? '') || tag == '${seq ?? ''}';
  }
}
