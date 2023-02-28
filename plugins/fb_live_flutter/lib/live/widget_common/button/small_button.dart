import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';

const double kMinInteractiveDimensionMagic = 44;

const EdgeInsets _kBackgroundButtonPadding =
    EdgeInsets.symmetric(vertical: 10, horizontal: 64);

class SmallButton extends StatefulWidget {
  const SmallButton({
    Key? key,
    required this.child,
    this.padding,
    this.margin = const EdgeInsets.symmetric(horizontal: 37),
    this.width,
    this.height,
    this.color,
    this.disabledColor = const Color(0xffEFEFEF),
    this.minWidth = kMinInteractiveDimensionMagic,
    this.minHeight = kMinInteractiveDimensionMagic,
    this.pressedOpacity = 1,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.isShadow = false,
    this.shadowColor,
    this.border,
    this.gradient,
    this.filled = false,
    required this.onPressed,
  })  : assert(pressedOpacity == null ||
            (pressedOpacity >= 0.0 && pressedOpacity <= 1.0)),
        super(key: key);

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Color disabledColor;
  final ClickEventCallback? onPressed;
  final double minWidth;
  final double minHeight;
  final double? width;
  final double? height;
  final double? pressedOpacity;
  final BorderRadius borderRadius;
  final bool filled;
  final bool isShadow;
  final Color? shadowColor;
  final BoxBorder? border;
  final Gradient? gradient;

  bool get enabled => onPressed != null;

  @override
  _SmallButtonState createState() => _SmallButtonState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _SmallButtonState extends State<SmallButton>
    with SingleTickerProviderStateMixin {
  static const Duration kFadeOutDuration = Duration(milliseconds: 10);
  static const Duration kFadeInDuration = Duration(milliseconds: 100);
  final Tween<double> _opacityTween = Tween<double>(begin: 1);

  AnimationController? _animationController;
  late Animation<double> _opacityAnimation;

  bool isInkWellProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      value: 0,
      vsync: this,
    );
    _opacityAnimation = _animationController!
        .drive(CurveTween(curve: Curves.decelerate))
        .drive(_opacityTween);
    _setTween();
  }

  @override
  void didUpdateWidget(SmallButton old) {
    super.didUpdateWidget(old);
    _setTween();
  }

  void _setTween() {
    _opacityTween.end = widget.pressedOpacity ?? 1.0;
  }

  @override
  void dispose() {
    _animationController!.dispose();
    _animationController = null;
    super.dispose();
  }

  bool _buttonHeldDown = false;

  void _handleTapDown(TapDownDetails event) {
    if (!_buttonHeldDown) {
      _buttonHeldDown = true;
      _animate();
    }
  }

  void _handleTapUp(TapUpDetails event) {
    if (_buttonHeldDown) {
      _buttonHeldDown = false;
      _animate();
    }
  }

  void _handleTapCancel() {
    if (_buttonHeldDown) {
      _buttonHeldDown = false;
      _animate();
    }
  }

  void _animate() {
    if (_animationController!.isAnimating) return;
    final bool wasHeldDown = _buttonHeldDown;
    final TickerFuture ticker = _buttonHeldDown
        ? _animationController!.animateTo(1, duration: kFadeOutDuration)
        : _animationController!.animateTo(0, duration: kFadeInDuration);
    ticker.then<void>((value) {
      if (mounted && wasHeldDown != _buttonHeldDown) _animate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.color ?? Colors.white;
    final bool enabled = widget.enabled;
    final Color backgroundColor = color;
    final Color foregroundColor =
        CupertinoTheme.of(context).primaryContrastingColor;
    final TextStyle textStyle = CupertinoTheme.of(context)
        .textTheme
        .textStyle
        .copyWith(color: foregroundColor);
    final Color resultColor = !enabled ? widget.disabledColor : backgroundColor;
    return Container(
      margin: widget.margin,
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(borderRadius: widget.borderRadius),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? _handleTapDown : null,
        onTapUp: enabled ? _handleTapUp : null,
        onTapCancel: enabled ? _handleTapCancel : null,
        onTap: () {
          if (isInkWellProcessing) {
            return;
          }
          isInkWellProcessing = true;

          if (widget.onPressed == null) {
            isInkWellProcessing = false;
            return;
          }
          widget.onPressed!().whenComplete(() {
            isInkWellProcessing = false;
          });
        },
        child: Semantics(
          button: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minWidth: widget.minWidth, minHeight: widget.minHeight),
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius,
                  color: widget.gradient != null ? null : resultColor,
                  gradient: widget.gradient,
                  boxShadow: widget.isShadow
                      ? [
                          BoxShadow(
                              color: widget.shadowColor!,
                              blurRadius: 10,
                              spreadRadius: 0.5),
                        ]
                      : [],
                  border: widget.border,
                ),
                child: Padding(
                  padding: widget.padding ?? _kBackgroundButtonPadding,
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: DefaultTextStyle(
                      style: textStyle,
                      child: IconTheme(
                        data: IconThemeData(color: foregroundColor),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
