class AuditResp {
  bool status;
  int code;
  String message;
  String desc;
  String requestId;
  AuditRespData data;

  AuditResp._();

  AuditResp.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    code = json['code'];
    message = json['message'];
    desc = json['desc'];
    requestId = json['request_id'];
    data = json['data'] != null ? AuditRespData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['status'] = status;
    data['code'] = code;
    data['message'] = message;
    data['desc'] = desc;
    data['request_id'] = requestId;
    if (data != null) data['data'] = this.data.toJson();
    return data;
  }
}

class AuditRespData {
  Alipay alipay;
  RedPack redPack;
  bool readHistory;
  int leBean;
  int walletBean;
  int wechatLogin;
  int appleLogin;
  BgNotification notificationInfo;

  AuditRespData({alipay, readHistory, ledou, welogin, notificationInfo});

  AuditRespData.fromJson(Map<String, dynamic> json) {
    alipay = json['alipay'] != null ? Alipay.fromJson(json['alipay']) : null;
    redPack = json['redbag'] != null ? RedPack.fromMap(json['redbag']) : null;
    readHistory = json['readHistory'];
    walletBean = json['nft'];
    leBean = json['ledou'];
    wechatLogin = json['welogin'];
    appleLogin = json['applelogin'];
    notificationInfo = json['notification'] != null
        ? BgNotification.fromJson(json['notification'])
        : BgNotification();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (alipay != null) data['alipay'] = alipay.toJson();
    data['readHistory'] = readHistory;
    data['nft'] = walletBean;
    data['ledou'] = leBean;
    data['welogin'] = wechatLogin;
    data['applelogin'] = appleLogin;
    if (notificationInfo != null)
      data['notification'] = notificationInfo.toJson();
    return data;
  }
}

class BgNotification {
  bool enableNotDisturbBgNoti = true;
  int total = 5;

  BgNotification({enableNotDisturbBgNoti = true, total = 5});

  BgNotification.fromJson(Map<String, dynamic> json) {
    enableNotDisturbBgNoti = json['open'] ?? true;
    total = json['total'] ?? 5;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['open'] = enableNotDisturbBgNoti ?? true;
    data['total'] = total ?? 5;
    return data;
  }
}

class Alipay {
  String rule;
  int maxLen;

  Alipay({rule, maxLen});

  Alipay.fromJson(Map<String, dynamic> json) {
    rule = json['rule'].toString();
    maxLen = json['max_len'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['rule'] = rule;
    data['max_len'] = maxLen;
    return data;
  }
}

class RedPack {
  final int singleMaxMoney; // 发送单个红包最大金额
  final int maxNum;
  final int period;

  const RedPack({
    this.singleMaxMoney,
    this.maxNum,
    this.period,
  });

  Map<String, dynamic> toMap() {
    return {
      'single_max_money': this.singleMaxMoney,
      'max_num': this.maxNum,
      'period': this.period,
    };
  }

  factory RedPack.fromMap(Map<String, dynamic> map) {
    return RedPack(
      singleMaxMoney: map['single_max_money'] as int,
      maxNum: map['max_num'] as int,
      period: map['period'] as int,
    );
  } // 拼手气红包最多分成这么多份
}
