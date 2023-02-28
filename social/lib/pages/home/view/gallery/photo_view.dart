import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'gallery.dart';

void showImageDialog(BuildContext context,
    {List<GalleryItem> items, int index = 0, bool showIndicator = false}) {
  Get.to(
    Gallery(
      items: items,
      chatContent: context,
      initialIndex: index,
      routeName: ModalRoute.of(context)?.settings?.name,
      isNeedLocation: false,
      showIndicator: showIndicator,
    ),
    opaque: false,
    fullscreenDialog: true,
    transition: Transition.fadeIn,
  );
}
