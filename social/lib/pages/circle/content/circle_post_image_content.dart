import 'package:im/pages/circle/content/abstract_circle_post_base_content.dart';
import 'package:im/pages/circle/content/circle_post_image_item.dart';

class CirclePostImageContent extends AbstractCirclePostBaseContent {
  CirclePostImageContent.fromDocument() : super.fromDocument();

  List<CirclePostImageItem> images;

  @override
  Map toJson() {
    return {};
  }
}
