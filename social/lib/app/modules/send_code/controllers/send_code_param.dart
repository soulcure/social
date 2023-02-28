import 'package:flutter/cupertino.dart';

typedef CodeCallBack = Future<Object> Function(String value);
typedef DoneCallBack = void Function(bool value);

enum CodeType {
  login,
  unbindAlipay,
  bindAlipay,
}

extension CodeTypeExt on CodeType {
  // 留空或不传：为登录、注册验证码 unbindalipay：解绑支付宝 bindalipay：绑定支付宝
  String get value => [null, 'unbindalipay', 'bindalipay'][index];
}

class SendCodeParam {
  // 手机号
  final String mobile;

  // 区域码
  final String country;

  // 验证code
  final CodeCallBack onCheckCode;

  // 验证码类别 【留空或不传：为登录、注册验证码，unbindalipay：解绑支付宝；bindalipay：绑定支付宝】
  final CodeType codeType;

  const SendCodeParam({
    @required this.mobile,
    @required this.country,
    @required this.onCheckCode,
    this.codeType = CodeType.login,
  });
}
