import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/utils/utils.dart';

class GuildIcon extends StatelessWidget {
  final GuildTarget guild;
  final double size;
  final double fontSize;

  const GuildIcon(this.guild, {this.size = 24, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    if (isNotNullAndEmpty(guild.icon)) {
      return ImageWidget.fromCachedNet(
        CachedImageBuilder(
          key: ValueKey(guild.icon),
          imageBuilder: (context, imageProvider) => DecoratedBox(
              decoration:
                  _decoration(image: DecorationImage(image: imageProvider))),
          imageUrl: guild.icon,
          memCacheHeight: (size * Get.pixelRatio).toInt(),
          memCacheWidth: (size * Get.pixelRatio).toInt(),
          width: size,
          height: size,
          placeholder: (context, url) => SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(decoration: _decoration()),
          ),
        ),
      );
    } else {
      return Container(
        alignment: Alignment.center,
        width: size,
        height: size,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: _decoration(),
        child: Text(
          subRichString(guild.name, 1),
          maxLines: 1,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: appThemeData.dividerColor.withOpacity(1),
            fontSize: fontSize,
          ),
        ),
      );
    }
  }

  BoxDecoration _decoration({DecorationImage image}) {
    return BoxDecoration(
      color: appThemeData.scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(size / 6),
      border: Border.all(
        color: appThemeData.dividerColor.withOpacity(.2),
        width: .5,
      ),
      image: image,
    );
  }
}
