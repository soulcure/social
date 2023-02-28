import 'dart:convert';

import 'package:api/creater/req_creater.dart';
import 'package:api/creater/res_creater.dart';
import 'package:api/utils.dart';

class CodeCreater {
  static String create(Map<String, dynamic> data) {
    String path = data["path"];
    // 返回书籍
    var resData;
    try {
      resData = json.decode(data["res_body"]);
    } catch (e) {
      throw "[$path] 消息返回不是json类型";
    }

    if (resData == null ||
        resData["properties"] == null ||
        resData["properties"]["data"] == null) {
      throw "[$path] 消息返回没有data字段";
    }

    // 请求数据
    List reqData;
    String reqType = data["req_body_type"];
    if (reqType == "json") {
      reqData = new List();
      String resBodyOther = data["req_body_other"];
      if (resBodyOther.isNotEmpty) {
        var reqBody;
        try {
          reqBody = json.decode(data["req_body_other"]);
        } catch (e) {
          throw "[$path] 请求参数数据格式不对";
        }
        if (reqBody["properties"] != null) {
          Map<String, dynamic> map = Map.from(reqBody["properties"]);
          map.forEach((key, item) {
            reqData.add({
              "name": key,
              "type": item["type"],
              "desc": item["description"]
            });
          });
        }
      }
    } else if (reqType == "form") {
      reqData = data["req_body_form"];
    } else {
      reqData = data["req_query"];
    }

    var className = getClassName(path);
    var dataType = resData["properties"]["data"]["type"];
    // 返回消息体是否不是object
    bool rootNotObject = dataType != "object";

    // 如果data为非object，则返回数据多增加一个data属性
    if (rootNotObject) {
      if (dataType == "array") {
        resData["properties"]["data"]["description"] =
            "className:${className}Data";
      }
      resData = {
        "properties": {
          "data": {
            "type": "object",
            "properties": {"data": resData["properties"]["data"]},
          }
        }
      };
    }

    // 生成请求代码
    var reqCode =
        ReqCreater.create(reqData, "/app" + path, className, rootNotObject);

    // 生成请求代码
    var resCode = ResCreater.create(resData, className, reqCode);

    // print(resCode);
    return resCode;
  }
}
