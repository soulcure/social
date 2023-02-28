import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';

/// gif展示widget：包含加载失败后的UI和重载
// ignore: camel_case_types
class GalleryGifViewWidget extends StatefulWidget {
  const GalleryGifViewWidget({Key key, this.imageUrl}) : super(key: key);

  final String imageUrl;

  @override
  GifErrorState createState() => GifErrorState();
}

class GifErrorState extends State<GalleryGifViewWidget> {
  int mKey = 0;

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_unnecessary_containers
    return Container(
      child: ImageWidget.fromCachedNet(CachedImageBuilder(
          key: ValueKey('GifErrorState-$mKey'),
          imageUrl: widget.imageUrl,
          fit: BoxFit.contain,
          cacheManager: CustomCacheManager.instance,
          placeholder: (context, _) => Container(
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 5,
                  height: 5,
                  child: CircularProgressIndicator(strokeWidth: 0.5),
                ),
              ),
          errorWidget: (context, url, error) {
            return Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: GestureDetector(
                    onTap: () {
                      setState(() {
                        mKey++;
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      // ignore: prefer_const_literals_to_create_immutables
                      children: <Widget>[
                        const Icon(
                          Icons.broken_image,
                          color: Colors.black38,
                          size: 15,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          constraints: const BoxConstraints.tightFor(
                              width: 32, height: 10),
                          decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.black38, width: 0.1),
                              borderRadius: BorderRadius.circular(2)),
                          alignment: Alignment.center,
                          child: Text("重新加载".tr,
                              style: const TextStyle(
                                  fontSize: 4, color: Colors.black)),
                        ),
                      ],
                    )));
          })),
    );
  }
}
