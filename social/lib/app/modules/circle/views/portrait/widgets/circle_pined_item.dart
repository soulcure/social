import 'dart:ui';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/controllers/circle_topic_controller.dart';
import 'package:im/app/modules/circle/models/circle_pined_post_data_model.dart';
import 'package:im/app/modules/circle/models/circle_post_data_type.dart';
import 'package:im/app/modules/circle/util.dart';
import 'package:im/app/modules/circle/views/portrait/widgets/circle_style_rich_text.dart';
import 'package:im/app/modules/circle_detail/circle_detail_router.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_video_page/controllers/circle_video_page_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/circle_page.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/routes.dart';
import 'package:im/svg_icons.dart';
import 'package:websafe_svg/websafe_svg.dart';

class CirclePinedItem extends StatelessWidget {
  const CirclePinedItem(this.pinedModel, {Key key}) : super(key: key);
  final List<CirclePinedPostDataModel> pinedModel;

  double get itemWidth => (Get.width / 2) - 7.5;

  double get itemHeight => itemWidth * 1.33;

  bool get multipleItem => pinedModel.length > 1;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight,
      width: itemWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: () {
          if (multipleItem)
            return NotificationListener(
              onNotification: (_) => true,
              child: Swiper(
                autoplay: true,
                autoplayDelay: 5000,
                itemCount: pinedModel.length,
                pagination: SwiperPagination(
                  margin: const EdgeInsets.only(bottom: 6),
                  builder: DotSwiperPaginationBuilder(
                    size: 4,
                    activeSize: 4,
                    activeColor: appThemeData.primaryColor,
                    color:
                        appThemeData.textTheme.headline2.color.withOpacity(0.4),
                  ),
                ),
                onTap: (index) => _onTap(pinedModel[index]),
                itemBuilder: (context, index) {
                  return _card(pinedModel[index]);
                },
              ),
            );
          else
            return GestureDetector(
              onTap: () => _onTap(pinedModel.first),
              child: _card(pinedModel.first),
            );
        }(),
      ),
    );
  }

  ClipRRect _card(CirclePinedPostDataModel model) {
    final postModel = model.post.postInfoDataModel;
    final Map<String, dynamic> mediaMap = postModel.firstMedia;
    final fileType = postModel.firstMediaFileType;
    final thumbUrl =
        fileType == 'video' ? mediaMap['thumbUrl'] : mediaMap['source'];
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration:
                BoxDecoration(color: appThemeData.scaffoldBackgroundColor),
          ),
          if (mediaMap.isEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 66),
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              child: CircleStyleRichText(
                content: CircleUtil.parsePost(postModel),
                guildId: postModel.guildId,
              ),
            )
          else
            ContainerImage(
              thumbUrl,
              thumbWidth: CircleController.circleThumbWidth,
              fit: BoxFit.cover,
            ),
          Positioned(
            bottom: 0,
            child: Container(
              color: Colors.white,
              width: itemWidth,
              height: 66,
              child: _buildText(model.title, model.typeName),
            ),
          ),
          if (fileType == 'video')
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.all(
                    Radius.circular(12),
                  ),
                ),
                width: 24,
                height: 24,
                child: Center(
                  child: WebsafeSvg.asset(
                    SvgIcons.circleVideoPlay,
                    width: 11,
                    height: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  void _onTap(CirclePinedPostDataModel pinedModel) {
    final postModel = pinedModel.post;
    if (postModel.postInfoDataModel.postType == CirclePostDataType.video &&
        postModel.postInfoDataModel.firstMedia.isNotEmpty) {
      Routes.pushCircleVideo(
        Get.context,
        CircleVideoPageControllerParam(model: postModel),
      );
    } else {
      CircleDetailRouter.push(CircleDetailData(
        postModel,
        extraData: ExtraData(extraType: ExtraType.fromCircleList),
        modifyCallBack: (info) {
          CircleTopicController.to(topicId: postModel.topicId)
              .loadData(reload: true);
        },
      ));
    }
  }

  Widget _buildText(String title, String typeName) {
    return Container(
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              child: Container(
                margin: const EdgeInsets.only(bottom: 1.5),
                padding: const EdgeInsets.only(top: 1),
                width: 28,
                height: 16,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: appThemeData.dividerColor.withOpacity(.4),
                    width: .5,
                  ),
                ),
                child: Text(
                  typeName,
                  style: TextStyle(
                    color: appThemeData.disabledColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const WidgetSpan(child: SizedBox(width: 4)),
            TextSpan(
              //每个字中间插入零宽字符
              //为了解决纯数字的情况下文字布局认为整段数字为整体而提前换行来布局数字
              text: Characters(title).join('\u{200B}'),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            )
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
