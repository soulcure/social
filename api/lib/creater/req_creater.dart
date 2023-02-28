import 'package:api/utils.dart';

class ReqCreater {
  static create(
      List reqData, String reqPath, String className, bool rootNotObject) {
    String params = "";
    String postData = "";
    reqData.forEach((item) {
      String name1 = item["name"];
      String name2 = camelCaseFirstLower(name1);
      params += (item["type"] != null
              ? ", " + getReqType(item["type"]) + " "
              : ", ") +
          name2;
      postData += ", '$name1': " + name2;
    });
    params = params.replaceFirst(", ", "");
    postData = postData.replaceFirst(", ", "");

    return _createCode(className, reqPath, params, postData, rootNotObject);
  }

  static String _createCode(String className, String reqPath, String params,
      String postData, bool rootNotObject) {
    final sb = new StringBuffer();
    sb.write('\n\nstatic Future<$className> fetch($params) async {\n');
    sb.write('Map<String, dynamic> res = await request("$reqPath"');
    if (postData.isNotEmpty) sb.write(',{$postData}');
    if (rootNotObject) {
      sb.write(
          ');\nreturn res!=null?$className.fromJson({"data":res["data"]}):null;');
    } else {
      sb.write(');\nreturn res!=null?$className.fromJson(res["data"]):null;');
    }
    sb.write('\n}');
    return sb.toString();
  }
}
