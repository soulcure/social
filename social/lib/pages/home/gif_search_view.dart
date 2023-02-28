import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/pages/home/gif_search_controller.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/widgets/circular_progress.dart';
import 'package:im/widgets/load_more.dart';

class GifSearchView extends GetWidget<GifSearchController> {
  static const kHeight = 80.0;

  final String channelId;

  @override
  String get tag => "${Get.currentRoute}\$$channelId";

  const GifSearchView(this.channelId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller.animation,
      builder: (context, listWidget) {
        return Container(
          transform: Matrix4.translationValues(
            0,
            kHeight * (1 - controller.animation.value),
            0,
          ),
          height: kHeight,
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF8F959E)
                      .withOpacity(0.4 * controller.animation.value),
                  blurRadius: 6)
            ],
          ),
          child: listWidget,
        );
      },
      child: _buildList(),
    );
  }

  Widget _buildList() {
    return Obx(
      () {
        if (controller.list.isEmpty) return const SizedBox();

        return LoadMore(
          fetchNextPage: controller.load,
          builder: (_) => Scrollbar(
            controller: controller.scrollController,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              controller: controller.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => controller.send(context, controller.list[index]),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: ImageWidget.fromCachedNet(CachedImageBuilder(
                        imageUrl: controller.list[index].url,
                        // fit: widget.fit,
                        cacheManager: CustomCacheManager.instance,
                        memCacheWidth: (64 * context.devicePixelRatio).toInt(),
                        memCacheHeight: (64 * context.devicePixelRatio).toInt(),
                        progressIndicatorBuilder: _buildLoading,
                      )),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemCount: controller.list.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoading(BuildContext context, _, __) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CircularProgress(
        size: 20,
        primaryColor: Theme.of(context).disabledColor.withOpacity(0.65),
        secondaryColor: Theme.of(context).disabledColor.withOpacity(0),
        strokeWidth: 2,
      ),
    );
  }
}
