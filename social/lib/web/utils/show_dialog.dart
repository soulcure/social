
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';


Future<T> showAnimationDialog<T>({
  @required BuildContext context,
  @required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color barrierColor = Colors.black54,
  String barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings routeSettings,
}) {
  assert(builder != null);
  assert(barrierDismissible != null);
  assert(useSafeArea != null);
  assert(useRootNavigator != null);
  assert(debugCheckHasMaterialLocalizations(context));

  final CapturedThemes themes = InheritedTheme.capture(
    from: context,
    to: Navigator.of(
      context,
      rootNavigator: useRootNavigator,
    ).context,
  );

  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(AnimationDialogRoute<T>(
    context: context,
    builder: builder,
    barrierColor: barrierColor,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    settings: routeSettings,
    themes: themes,
  ));
}

class AnimationDialogRoute<T> extends RawDialogRoute<T> {
  /// A dialog route with Material entrance and exit animations,
  /// modal barrier color, and modal barrier behavior (dialog is dismissible
  /// with a tap on the barrier).
  AnimationDialogRoute({
    @required BuildContext context,
    @required WidgetBuilder builder,
    CapturedThemes themes,
    Color barrierColor = Colors.black54,
    bool barrierDismissible = true,
    String barrierLabel,
    bool useSafeArea = true,
    RouteSettings settings,
  }) : assert(barrierDismissible != null),
        super(
        pageBuilder: (buildContext, animation, secondaryAnimation) {
          final Widget pageChild = Builder(builder: builder);
          Widget dialog = themes?.wrap(pageChild) ?? pageChild;
          if (useSafeArea) {
            dialog = SafeArea(child: dialog);
          }
          return dialog;
        },
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel ?? MaterialLocalizations.of(context).modalBarrierDismissLabel,
        transitionDuration: const Duration(milliseconds: 150),
        transitionBuilder: (context, animation, secondaryAnimation, child) => FadeThroughTransition(animation: animation, secondaryAnimation: secondaryAnimation, fillColor: Colors.transparent, child: child,),
        settings: settings,
      );
}