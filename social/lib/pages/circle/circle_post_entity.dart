import 'package:im/pages/circle/content/abstract_circle_post_base_content.dart';

enum CirclePostType {
  CirclePostTypeArticle,
  CirclePostTypeVideo,
  CirclePostTypeImage
}

CirclePostType str2CirclePostType(String postType) {
  switch (postType) {
    case 'image':
      return CirclePostType.CirclePostTypeImage;
    case 'video':
      return CirclePostType.CirclePostTypeVideo;
    case 'article':
      return CirclePostType.CirclePostTypeArticle;
    default:
      return CirclePostType.CirclePostTypeArticle;
  }
}

class CirclePostEntity<T extends AbstractCirclePostBaseContent> {
  String title;
  CirclePostType postType;
  List<String> mentions;
  T content;

  Map toJson() {
    return {};
  }
}
