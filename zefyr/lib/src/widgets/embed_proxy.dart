import 'package:flutter/widgets.dart';

import '../rendering/embed_proxy.dart';

class EmbedProxy extends SingleChildRenderObjectWidget {
  // 修改，添加embedSize参数，保存图片宽高
  final Size embedSize;
  EmbedProxy({@required Widget child, this.embedSize}) : super(child: child);

  @override
  RenderEmbedProxy createRenderObject(BuildContext context) {
    return RenderEmbedProxy(embedSize: embedSize);
  }
}
