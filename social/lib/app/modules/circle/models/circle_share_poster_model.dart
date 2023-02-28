//
// circle_share_poster_model
// social
// Created by weiweili$ on 2021/11/10$.
//

import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_video_page/controllers/circle_video_page_controller.dart';

class CircleSharePosterModel {
  /// 用户分享海报
  // final bool isCirclePoster;

  /// 圈子详情分享的数据
  final CircleDetailData circleDetailData;

  /// 沉浸视频分享数据
  final PostVideo postVideo;

  CircleSharePosterModel({this.circleDetailData, this.postVideo});
}
