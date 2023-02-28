import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/image_operator_collection/status_widget.dart';
import 'package:im/widgets/cache_widget.dart';

class UploadProgress extends StatefulWidget {
  final Future future;
  final double width;
  final WidgetBuilder builder;
  const UploadProgress({this.future, this.builder, this.width});
  @override
  _UploadProgressState createState() => _UploadProgressState();
}


class _UploadProgressState extends State<UploadProgress> {

  /// -1 代表审核被拒
  /// 0 loading..
  /// 1 success
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);

  @override
  void initState() {
    widget.future.then((value) {
      if (value is List<String>) {
        _progress.value = value.first.contains('reject') ? -1 : 1;
      }
    }).catchError((e) {
      print('上传 $e');
    });
    super.initState();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _progress,
        builder: (context, progress, _) {
          if (_progress.value == -1)
            return SizedBox(
              width: widget.width,
              child: videoRejectWidget(context,
                  showBorder: true, size: 20, margin: 8, message: '内容包含违规内容'.tr),
            );
          return Stack(
            children: [
              CacheWidget(builder: () => widget.builder(context)),
              if (_progress.value != 1)
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black38),
                  ),
                ),
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    if (progress == 1) return const SizedBox();
                    return Center(
                        child: DefaultTheme.defaultLoadingIndicator(size: 8));
                  },
                ),
              )
            ],
          );
        });
  }
}
