import 'package:flutter/cupertino.dart';

class MpAuthScope {
  final String scope;
  static MpAuthScope userInfo = MpAuthScope._('userInfo');
  MpAuthScope._(this.scope);
  @override
  String toString() {
    return 'scope.$scope';
  }
}

// 授权结果返回类型
class MpAuthResType {
  static String deny = 'fail auth deny';
  static String ok = 'ok';
  static String error = 'error';
}

class MpAuthRes {
  // 授权结果
  String errMsg;
  // 返回数据
  Map<String, dynamic> data;
  MpAuthRes({@required this.errMsg, Map<String, dynamic> data})
      : data = data ?? {};
  Map<String, dynamic> toJson() {
    return {
      'errMsg': errMsg,
      'data': data,
    };
  }

  MpAuthRes._({this.errMsg, this.data});
  static MpAuthRes empty = MpAuthRes._(errMsg: '');
}
