import 'package:im/pages/circle/content/abstract_circle_post_base_content.dart';

class CirclePostVideoContent extends AbstractCirclePostBaseContent {
  double width;
  double height;
  String url;
  String thumbUrl;

  CirclePostVideoContent.fromDocument() : super.fromDocument();

  @override
  Map toJson() {
    return {};
  }
}
