import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_builder.dart';
import 'package:im/utils/image_operator_collection/image_widget.dart';
import 'package:im/utils/utils.dart';

class GoodsShareItem extends StatelessWidget {
  final GoodsShareEntity entity;
  final MessageEntity message;

  const GoodsShareItem({Key key, this.entity, this.message}) : super(key: key);

  void _itemClick() {
    // eg. 'https://shop95766478.youzan.com/v2/showcase/homepage?alias=k1q3puZPsb&shopAutoEnter=1&kdt_id=95574310&fb_redirect&open_type=mp'
    if (!entity.detailUrl.hasValue) return;
    String url = entity.detailUrl;
    if (!url.hasValue) return;
    final uri = Uri.parse(url);
    // 如果没有查询参数，添加小程序参数
    if (uri.queryParameters == null || uri.queryParameters.isEmpty) {
      url += '?fb_redirect&open_type=mp';
    } else {
      // 如果有，则追加
      final redirect = uri.queryParameters['fb_redirect'];
      if (redirect == null) {
        url += '&fb_redirect';
      }
      final openType = uri.queryParameters['open_type'];
      if (openType == null) {
        url += '&open_type=mp';
      }
    }
    Routes.pushMiniProgram(url);
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF5F5F8);
    const radius = Radius.circular(6);
    const double itemHeight = 88;
    final pr = MediaQuery.of(context).devicePixelRatio;
    final iconUrl = fetchYzCdnThumbUrl(entity.icon, (pr * itemHeight).toInt());
    return GestureDetector(
      onTap: _itemClick,
      child: Container(
        height: itemHeight,
        decoration: const BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.all(radius),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(6),
              ),
              child: Container(
                color: bgColor,
                width: itemHeight,
                height: itemHeight,
                child: ImageWidget.fromCachedNet(
                  CachedImageBuilder(
                    // imageUrl: entity.icon,
                    imageUrl: iconUrl,
                    cacheManager: CustomCacheManager.instance,
                    fit: BoxFit.cover,
                  ),
                ),
                // child: NetworkImageWithPlaceholder(
                //   entity.icon,
                //   fit: BoxFit.cover,
                //   width: itemHeight,
                //   height: itemHeight,
                // ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entity.goodsName ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: '￥',
                                style: TextStyle(
                                  color: Color(0xFFF24848),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: entity.isMultiSpecification
                                    ? entity.lowPrice
                                    : entity.price,
                                style: const TextStyle(
                                  color: Color(0xFFF24848),
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (entity.isMultiSpecification)
                                const TextSpan(
                                  text: '起',
                                  style: TextStyle(
                                    color: Color(0xFFF24848),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        sizeWidth4,
                        Expanded(
                          child: Text(
                            '￥${entity.originalPrice}',
                            style: TextStyle(
                              color: Theme.of(context).disabledColor,
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              height: 1.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
