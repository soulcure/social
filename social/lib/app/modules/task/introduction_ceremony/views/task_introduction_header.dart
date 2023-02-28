import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_builder.dart';
import 'package:im/utils/image_operator_collection/image_widget.dart';

class TaskIntroductionHeader extends StatefulWidget {
  final Widget child;
  final String welcomeMessage;

  const TaskIntroductionHeader({this.child, this.welcomeMessage = ''});

  @override
  _TaskIntroductionHeaderState createState() => _TaskIntroductionHeaderState();
}

class _TaskIntroductionHeaderState extends State<TaskIntroductionHeader> {
  @override
  Widget build(BuildContext context) {
    final gt = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    print(Global.mediaInfo.padding);
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ImageWidget.fromCachedNet(CachedImageBuilder(
                imageUrl: gt.banner ?? '',
                cacheManager: CustomCacheManager.instance,
                height: 188,
                width: MediaQuery.of(context).size.width.toDouble(),
                memCacheHeight: (188 * context.devicePixelRatio).toInt(),
                memCacheWidth: (MediaQuery.of(context).size.width *
                        context.devicePixelRatio)
                    .toInt(),
                filterQuality: FilterQuality.none,
                fit: BoxFit.cover,
              )),
              Positioned.fill(
                  child: Container(
                color: Colors.black.withOpacity(0.15),
              )),
              Positioned.fill(
                  child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: -40,
                    child: Container(
                      alignment: Alignment.center,
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 4),
                        borderRadius: const BorderRadius.all(//圆角
                            Radius.circular(14)),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        child: ImageWidget.fromCachedNet(CachedImageBuilder(
                          imageUrl: gt.icon ?? '',
                          filterQuality: FilterQuality.none,
                          cacheManager: CustomCacheManager.instance,
                          fit: BoxFit.cover,
                          height: 80,
                          width: 80,
                          memCacheHeight:
                              (80 * context.devicePixelRatio).toInt(),
                          memCacheWidth:
                              (80 * context.devicePixelRatio).toInt(),
                        )),
                      ),
                    ),
                  ),
                ],
              ))
            ],
          ),
          if (widget.child != null) ...[
            const SizedBox(height: 60),
            widget.child,
          ],
          if (widget.welcomeMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
              child: Text(
                widget.welcomeMessage ?? "",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF646A73), fontSize: 14, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}
