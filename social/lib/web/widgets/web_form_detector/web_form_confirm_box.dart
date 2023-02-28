import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/web/widgets/web_form_detector/web_form_detector_model.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';

class WebFormConfirmBox extends StatefulWidget {
  @override
  _WebFormConfirmBoxState createState() => _WebFormConfirmBoxState();
}

class _WebFormConfirmBoxState extends State<WebFormConfirmBox>
    with TickerProviderStateMixin {
  AnimationController _slideController;
  AnimationController _bgColorController;
  Animation<Offset> _slideAnimation;
  Animation<Color> _colorAnimation;
  ValueNotifier<bool> _loading;
  bool confirmEnable = true;

  @override
  void initState() {
    final model = Provider.of<WebFormDetectorModel>(context, listen: false);
    model.animating.addListener(() async {
      if (model.animating.value) {
        if (_bgColorController.isAnimating) return;
        await _bgColorController.forward();
        unawaited(_bgColorController.reverse());
      }
    });
    model.changed.addListener(() {
      final formChanged = model.changed.value;
      if (formChanged) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    });
    model.confirmEnable.addListener(() {
      confirmEnable = model.confirmEnable.value;
      setState(() {});
    });
    _slideController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _slideAnimation = Tween(begin: const Offset(0, 2), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _slideController, curve: Curves.easeInOutBack));
    _bgColorController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _colorAnimation = ColorTween(
            begin: const Color(0xFFF2F3F5), end: DefaultTheme.dangerColor)
        .animate(_bgColorController);
    _loading = ValueNotifier(false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Container(
            width: 648,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 60, left: 40),
            decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(4)),
            child: Row(
              children: [
                Text(
                  '设置已发生变化，确定更改吗？'.tr,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2
                      .copyWith(fontSize: 16),
                ),
                spacer,
                SizedBox(
                  height: 32,
                  // ignore: deprecated_member_use
                  child: OutlineButton(
                    onPressed: () {
                      FocusManager.instance.primaryFocus.unfocus();
                      final formModel = Provider.of<WebFormDetectorModel>(
                          context,
                          listen: false);
                      formModel.onReset?.call();
                    },
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      '取消'.tr,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText2
                          .copyWith(fontSize: 14),
                    ),
                  ),
                ),
                sizeWidth16,
                SizedBox(
                  height: 32,
                  child: ValueListenableBuilder<bool>(
                      valueListenable: _loading,
                      builder: (context, loading, child) {
                        // ignore: deprecated_member_use
                        return RaisedButton(
                            onPressed: confirmEnable ? () async {
                              FocusManager.instance.primaryFocus.unfocus();
                              try {
                                _loading.value = true;
                                final formModel =
                                    Provider.of<WebFormDetectorModel>(context,
                                        listen: false);
                                await formModel.onConfirm?.call();
                              } finally {
                                _loading.value = false;
                              }
                            }: null,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            child: loading
                                ? const SizedBox(
                                    height: 15,
                                    width: 15,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        backgroundColor: Colors.white),
                                  )
                                : Text(
                                    '保存更改'.tr,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ));
                      }),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
