getClassName(String name) {
  if (name.indexOf("/") == 0) {
    name = name.replaceFirst("/", "");
  }
  var names = name.replaceAll("-", "/").replaceAll("_", "/").split("/");
  var className = "";
  for (String name in names) {
    if (name.isNotEmpty) {
      name = name.substring(0, 1).toUpperCase() + name.substring(1);
      className += name;
    }
  }
  return className;
}

getFileName(String name) {
  if (name.indexOf("/") == 0) {
    name = name.replaceFirst("/", "");
  }
  var names = name.replaceAll("-", "/").replaceAll("_", "/").split("/");
  return names.join("_");
}

String camelCase(String text) {
  String capitalize(Match m) =>
      m[0].substring(0, 1).toUpperCase() + m[0].substring(1);
  String skip(String s) => "";
  return text.splitMapJoin(new RegExp(r'[a-zA-Z0-9]+'),
      onMatch: capitalize, onNonMatch: skip);
}

String camelCaseFirstLower(String text) {
  final camelCaseText = camelCase(text);
  final firstChar = camelCaseText.substring(0, 1).toLowerCase();
  final rest = camelCaseText.substring(1);
  return '$firstChar$rest';
}

Map _reqTypeMap = {
  "string": "String",
  "number": "num",
  "integer": "int",
  "boolean": "bool",
  "array": "List",
  "object": "Map",
  "text": "String",
  "null": "String",
  "file": ""
};
String getReqType(type) {
  return _reqTypeMap[type];
}
