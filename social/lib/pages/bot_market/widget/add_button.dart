import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/widgets/fb_ui_kit/button/button_builder.dart';

import '../bot_utils.dart';

typedef AddOp = Future<bool> Function();

class AddButton extends StatefulWidget {
  // 按钮类型
  final FbButtonType buttonType;

  // 添加状态
  final AddedStatus status;

  // 添加操作
  final AddOp onAdd;

  // 取消添加操作
  final AddOp onUnAdded;

  // 删除操作
  final AddOp onRemove;

  // 添加操作拦截器，如果拦截器返回false，则不执行添加操作
  final AddOp addInterceptor;

  // 取消添加操作拦截器，如果拦截器返回false，则不执行取消添加操作
  final AddOp unAddInterceptor;

  final double width;
  final double height;
  final String addedText;
  final bool keepNormal;
  const AddButton({
    Key key,
    this.buttonType = FbButtonType.subElevated,
    this.status = AddedStatus.UnAdded,
    this.onAdd,
    this.onUnAdded,
    this.onRemove,
    this.addInterceptor,
    this.unAddInterceptor,
    this.width = 60,
    this.height = 32,
    this.addedText,
    this.keepNormal = false,
  }) : super(key: key);

  @override
  _AddButtonState createState() => _AddButtonState();
}

class _AddButtonState extends State<AddButton> {
  AddedStatus _status;
  FbButtonStatus _isLoading = FbButtonStatus.normal;

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _isLoading = _getButtonStatus(_status);
  }

  FbButtonStatus _getButtonStatus(AddedStatus status) {
    if (widget.keepNormal) return FbButtonStatus.normal;
    return status == AddedStatus.UnAdded
        ? FbButtonStatus.normal
        : FbButtonStatus.finish;
  }

  @override
  void didUpdateWidget(covariant AddButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _status = widget.status;
    _isLoading = _getButtonStatus(_status);
  }

  // 如果已添加，执行删除操作，否则执行添加操作
  Future _toggleAction() async {
    if (_isLoading == FbButtonStatus.loading) return;
    AddOp action;
    AddOp interceptor;
    AddedStatus targetStatus;
    switch (_status) {
      case AddedStatus.Added:
        action = widget.onUnAdded;
        interceptor = widget.unAddInterceptor;
        targetStatus = AddedStatus.UnAdded;
        break;
      case AddedStatus.UnAdded:
        action = widget.onAdd;
        interceptor = widget.addInterceptor;
        targetStatus = AddedStatus.Added;
        break;
      case AddedStatus.Invalid:
        action = widget.onRemove;
        targetStatus = AddedStatus.Invalid;
        break;
    }

    if (action == null) return;

    if (interceptor != null) {
      // 拦截器阻断了操作
      final isContinue = await interceptor();
      if (isContinue != true) {
        return;
      }
    }
    setState(() {
      _isLoading = FbButtonStatus.loading;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _status = targetStatus;
        _isLoading = _getButtonStatus(_status);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = _getButtonStatus(_status);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String text;
    switch (_status) {
      case AddedStatus.Added:
        text = widget.addedText ?? '已添加'.tr;
        break;
      case AddedStatus.UnAdded:
        text = "添加".tr;
        break;
      case AddedStatus.Invalid:
        text = "已失效".tr;
        break;
    }

    return FbButton(
      text,
      type: widget.buttonType,
      status: _isLoading,
      width: widget.width,
      height: widget.height,
      onPressed: _toggleAction,
    );
  }
}
