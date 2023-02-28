import 'package:api/creater/class_creater.dart';
import 'package:api/utils.dart';

class ResCreater {
  static create(resData, className, String reqCode) {
    var data = resData["properties"]["data"];

    List<String> codes = [];
    List<String> imports = ["import '../core/http.dart';\n"];
    _createCode(data, className, reqCode, codes, imports);
    var code = imports.join("");
    for (var i = codes.length - 1; i > -1; i--) {
      code += codes[i];
    }
    return code;
  }

  /// 如果描述里面有className:xxx，则会改类名为xxx
  static _getClassName(propName, String description) {
    if (description != null) {
      if (description.indexOf("className:") == 0) {
        return getClassName(description.replaceFirst("className:", ""));
      }
    }
    return getClassName(propName);
  }

  /// 如果描述里面有name:xxx，则会改field为xxx
  static _getPropdName(fieldName, String description) {
    if (description != null) {
      if (description.indexOf("name:") == 0) {
        return camelCaseFirstLower(description.replaceFirst("name:", ""));
      }
    }
    return camelCaseFirstLower(fieldName);
  }

  static bool _createCode(
      data, className, reqCode, List<String> codes, List<String> imports) {
    var type = data["type"];
    if (type == "object") {
      List<Prop> props = [];
      Map<String, dynamic> map = Map.from(data["properties"]);
      map.forEach((key, item) {
        String propType = item["type"];
        String propField = key;
        String propDesc = item["description"];
        String propName = _getPropdName(propField, propDesc);
        if (propType == "object") {
          // 如果描述里面有class:xxx，这忽略类的生成
          if (propDesc != null && propDesc.indexOf("class:") == 0) {
            var path = propDesc.replaceFirst("class:", "");
            var import = "import '${getFileName(path)}.dart';";
            if (imports.indexOf(import) < 0) {
              imports.add(import);
            }
            var propClassName = getClassName(path);
            props.add(
              Prop(propName, propField, propClassName, false, true),
            );
          } else {
            var propClassName = _getClassName(propField, propDesc);
            // 如果item内没有子对象，则返回失败，不创建新类
            var success = _createCode(item, propClassName, "", codes, imports);
            props.add(
              Prop(propName, propField, success ? propClassName : "var", false,
                  success),
            );
          }
        } else if (propType == "array") {
          String itemDesc = item["items"]["description"];
          // 如果描述里面有class:xxx，这忽略类的生成
          if (itemDesc != null && itemDesc.indexOf("class:") == 0) {
            var path = itemDesc.replaceFirst("class:", "");
            var import = "import '${getFileName(path)}.dart';";
            if (imports.indexOf(import) < 0) {
              imports.add(import);
            }
            var propClassName = getClassName(path);
            props.add(
              Prop(propName, propField, "List<$propClassName>", true, false,
                  itemClassName: propClassName),
            );
          } else {
            var propClassName = _getClassName(propField, propDesc);
            var itemType = item["items"]["type"];
            var itemTypeStr = "";
            var itemClassName;
            if (itemType == "array") {
              itemTypeStr = "List";
            } else if (itemType == "object") {
              // 如果item内没有子对象，则返回失败，不创建新类
              var success =
                  _createCode(item["items"], propClassName, "", codes, imports);
              if (success) {
                itemTypeStr = "List<$propClassName>";
                itemClassName = propClassName;
              } else {
                itemTypeStr = "List";
              }
            } else {
              itemTypeStr = "List<" + getReqType(itemType) + ">";
            }
            props.add(
              Prop(propName, propField, itemTypeStr, true, false,
                  itemClassName: itemClassName),
            );
          }
        } else {
          props.add(
            Prop(propName, propField, getReqType(propType), false, false),
          );
        }
      });
      if (props.length == 0) {
        return false;
      }
      var code = ClassCreater.create(className, props, reqCode);
      codes.add(code);
      return true;
    }
    return false;
  }
}
