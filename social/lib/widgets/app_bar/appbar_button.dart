import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/themes/default_theme.dart';

class AppbarButton extends StatelessWidget {
  const AppbarButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class AppbarIconButton<T> extends AppbarButton {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color color;

  /// 红点数监听
  final ValueListenable<T> listenable;
  final int Function(T) selector;
  final double right;
  final double left;

  const AppbarIconButton({
    Key key,
    @required this.icon,
    @required this.onTap,
    this.size,
    this.color,
    this.listenable,
    this.selector,
    this.right = 0,
    this.left = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final child = Container(
        padding: EdgeInsets.only(left: left, right: right),
        child: SizedBox(
          width: 44,
          height: 44,
          child: IconButton(
            onPressed: onTap,
            icon: Icon(
              icon,
              size: size ?? 24,
              color: color ?? const Color(0xFF1F2125),
            ),
          ),
        ));
    if (listenable == null) {
      return child;
    }
    return ValueListenableBuilder(
      valueListenable: listenable,
      builder: (_, o, __) {
        final int value = selector(o);
        return RedDotFill(
          value,
          offset: const Offset(12, -11),
          alignment: Alignment.center,
          borderColor: Theme.of(context).backgroundColor,
          child: child,
        );
      },
    );
  }
}

/// 文字按钮
class AppbarTextButton extends AppbarButton {
  final String text;
  final VoidCallback onTap;
  final bool enable;
  final bool loading;

  const AppbarTextButton(
      {Key key,
      @required this.text,
      @required this.onTap,
      this.enable = true,
      this.loading = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final disableColor = Theme.of(context).disabledColor.withOpacity(0.15);
    final disableTextColor = Theme.of(context).disabledColor;

    return Padding(
      /// 这里加padding是因为统一，iconbutton距离icon内部本身有10的padding，其余button必须补充
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        alignment: AlignmentDirectional.centerEnd,
        children: [
          Visibility(
            visible: !loading,
            child: FadeBackgroundButton(
              onTap: enable ? onTap : null,
              backgroundColor:
                  enable ? Theme.of(context).primaryColor : disableColor,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 32,
              borderRadius: 4,
              tapDownBackgroundColor: disableColor,
              child: Text(
                text,
                style: TextStyle(
                    fontSize: 14,
                    color: enable ? Colors.white : disableTextColor),
              ),
            ),
          ),
          Visibility(
            visible: loading,
            child: Container(
              alignment: Alignment.center,
              width: 60,
              child: DefaultTheme.defaultLoadingIndicator(
                  size: 8, color: disableTextColor),
            ),
          )
        ],
      ),
    );
  }
}

/// 下一步按钮，固定样式
class AppbarNextButton extends AppbarButton {
  final VoidCallback onTap;

  const AppbarNextButton({Key key, @required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final disableColor = Theme.of(context).disabledColor.withOpacity(0.15);
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 10),
      child: FadeBackgroundButton(
        onTap: onTap,
        backgroundColor: disableColor,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 32,
        borderRadius: 16,
        tapDownBackgroundColor: disableColor,
        child: Text(
          '下一步'.tr,
          style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }
}

class AppbarCancelButton extends AppbarButton {
  final VoidCallback onTap;

  const AppbarCancelButton({this.onTap, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeBackgroundButton(
        padding: const EdgeInsets.only(left: 12),
        onTap: onTap,
        tapDownBackgroundColor: null,
        child: Text('取消'.tr,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(Get.context).textTheme.bodyText2.color,
            )),
      ),
    );
  }
}

class AppbarNullButton extends AppbarButton {
  const AppbarNullButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class AppbarCustomButton extends AppbarButton {
  final Widget child;

  const AppbarCustomButton({Key key, @required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
