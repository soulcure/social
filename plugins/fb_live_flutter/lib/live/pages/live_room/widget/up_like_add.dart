import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';

bool isAddAnimateOk = true;

/// 【2022 01.04】
/// 双击点赞，可叠加，可显示数字。
class UpLikeAdd extends StatefulWidget {
  final int? count;

  const UpLikeAdd(this.count);

  @override
  _UpLikeAddState createState() => _UpLikeAddState();
}

class _UpLikeAddState extends State<UpLikeAdd> with TickerProviderStateMixin {
  AnimationController? controllerScale;
  late Animation<double> scale;

  late AnimationController controllerAlign;
  late Animation<AlignmentGeometry> align;

  bool isShowView = false;

  @override
  void initState() {
    super.initState();
    controllerScale = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    scale = Tween<double>(
      begin: 2.2,
      end: 0,
    ).animate(
      CurvedAnimation(
          parent: controllerScale!,
          curve: const Cubic(0.68, -0.55, 0.365, 1.55)),
    );

    controllerAlign = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    align = Tween<AlignmentGeometry>(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).animate(
      CurvedAnimation(parent: controllerAlign, curve: Curves.ease),
    );
    if (isAddAnimateOk) {
      if (mounted) {
        setState(() {
          isShowView = true;
        });
      }
      isAddAnimateOk = false;
      controllerScale!.forward();
      controllerAlign.forward().then((value) {
        isAddAnimateOk = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget view;
    final count = (widget.count ?? 0) + 1;
    if (count < 10) {
      view = Container();
    } else {
      view = AnimatedBuilder(
        builder: (context, child) {
          return AlignTransition(
            alignment: align,
            child: Transform.scale(
              scale: () {
                final value = scale.value;
                if (value <= 0.7) {
                  return 0.0;
                } else {
                  return value;
                }
              }(),
              child: Text(
                'x$count',
                style: TextStyle(
                  color: isShowView ? Colors.white : Colors.transparent,
                  fontSize: 9.px,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
        animation: controllerScale!,
      );
    }
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        height: 20.px,
        child: view,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    controllerScale?.stop();
    controllerScale?.dispose();
  }
}
