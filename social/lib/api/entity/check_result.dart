/// code : 1100
/// message : "成功".tr
/// requestId : "6409c38b0f57cb0538a1cc8f0271abcd"
/// score : 998
/// riskLevel : "REJECT"
/// detail : "{\"contactResult\":[],\"description\":\"黑名单\",\"filteredText\":\"***\",\"hitPosition\":\"0,1,2\",\"matchedDetail\":\"[{\\\"listId\\\":\\\"3eb099321da9f66fcd5c109b97b6d29b\\\",\\\"matchedFiled\\\":[\\\"text\\\"],\\\"name\\\":\\\"批量添敏感词黑名单\\\",\\\"organization\\\":\\\"tAOpW0xGzXg4pg5oMyku\\\",\\\"wordPositions\\\":[{\\\"position\\\":\\\"0,1,2\\\",\\\"word\\\":\\\"胡锦涛\\\"}],\\\"words\\\":[\\\"胡锦涛\\\"]},{\\\"listId\\\":\\\"98efc045774269517740189d3eb5f191\\\",\\\"matchedFiled\\\":[\\\"text\\\"],\\\"name\\\":\\\"网监敏感词名单\\\",\\\"organization\\\":\\\"tAOpW0xGzXg4pg5oMyku\\\",\\\"wordPositions\\\":[{\\\"position\\\":\\\"0,1,2\\\",\\\"word\\\":\\\"胡锦涛\\\"},{\\\"position\\\":\\\"\\\",\\\"word\\\":\\\"錦濤\\\"}],\\\"words\\\":[\\\"胡锦涛\\\",\\\"錦濤\\\"]}]\",\"matchedField\":\"text\",\"matchedItem\":\"胡锦涛,錦濤\",\"matchedList\":\"网监敏感词名单\",\"model\":\"M1020_70\",\"riskType\":700}"
/// status : 0

class TextCheckResult {
  int code;
  String message;
  String requestId;
  int score;
  String riskLevel;
  String detail;
  int status;

  TextCheckResult.fromMap(Map<String, dynamic> map) {
    code = map['code'];
    message = map['message'];
    requestId = map['requestId'];
    score = map['score'];
    riskLevel = map['riskLevel'];
    detail = map['detail'];
    status = map['status'];
  }

  Map toJson() => {
        "code": code,
        "message": message,
        "requestId": requestId,
        "score": score,
        "riskLevel": riskLevel,
        "detail": detail,
        "status": status,
      };
}

/// code : 1100
/// message : "成功".tr
/// requestId : "6fd8ff8d0f582291c9e1d5db399dcfa5"
/// imgs : [{"btId":"123123123","code":1100,"detail":{"description":"正常","hits":[],"model":"M1000","riskType":0},"message":"成功".tr,"requestId":"6fd8ff8d0f582291c9e1d5db399dcfa5_4397cd00f53b9d7149f5b0f53135db","riskLevel":"PASS","score":0}]
/// statistics : [0,0,1,0]

class ImageCheckResult {
  int code;
  String message;
  String requestId;
  List<ImgsBean> imgs;
  List<int> statistics;

  ImageCheckResult.fromMap(Map<String, dynamic> map) {
    code = map['code'];
    message = map['message'];
    requestId = map['requestId'];
    imgs = [...(map['imgs'] as List ?? []).map((o) => ImgsBean.fromMap(o))];
    statistics = [
      ...(map['statistics'] as List ?? [])
          .map((o) => int.tryParse(o.toString()))
    ];
  }

  Map toJson() => {
        "code": code,
        "message": message,
        "requestId": requestId,
        "imgs": imgs,
        "statistics": statistics,
      };
}

class ImgsBean {
  String btId;
  int code;
  DetailBean detail;
  String message;
  String requestId;
  String riskLevel;
  int score;

  ImgsBean.fromMap(Map<String, dynamic> map) {
    btId = map['btId'];
    code = map['code'];
    detail = DetailBean.fromMap(map['detail']);
    message = map['message'];
    requestId = map['requestId'];
    riskLevel = map['riskLevel'];
    score = map['score'];
  }

  Map toJson() => {
        "btId": btId,
        "code": code,
        "detail": detail,
        "message": message,
        "requestId": requestId,
        "riskLevel": riskLevel,
        "score": score,
      };
}

class DetailBean {
  String description;
  List<dynamic> hits;
  String model;
  int riskType;

  DetailBean.fromMap(Map<String, dynamic> map) {
    if (map == null) return;
    description = map['description'];
    hits = map['hits'];
    model = map['model'];
    riskType = map['riskType'];
  }

  Map toJson() => {
        "description": description,
        "hits": hits,
        "model": model,
        "riskType": riskType,
      };
}
