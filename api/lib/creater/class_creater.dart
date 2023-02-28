class ClassCreater {
  static String create(String className, List<Prop> props, String reqCode) {
    final sb = new StringBuffer();
    sb.write("class $className {\n");

    // 创建属性
    props.forEach((item) {
      sb.write("${item.type} ${item.name};\n");
    });

    sb.write("\n$className.fromJson(Map<String, dynamic> json) {\n");

    // 数据赋值
    props.forEach((item) {
      if (item.isList) {
        sb.write("if (json['${item.field}'] != null) {\n");
        sb.write("  ${item.name} = new List();\n");
        sb.write("  json['${item.field}'].forEach((v) {\n");
        var value = "v";
        if (item.itemClassName != null) {
          value = "new ${item.itemClassName}.fromJson(v)";
        }
        sb.write("  ${item.name}.add($value);\n");
        sb.write("  });\n");
        sb.write("}\n");
      } else if (item.isObject) {
        sb.write("if(json['${item.field}']!=null){\n");
        sb.write(
            "  ${item.name} = ${item.type}.fromJson(json['${item.field}']);\n");
        sb.write("}\n");
      } else {
        sb.write("${item.name} = json['${item.field}'];\n");
      }
    });

    sb.write("}\n");

    sb.write(reqCode);

    sb.write("}\n");
    // print(sb.toString());
    return sb.toString();
  }
}

class Prop {
  String name;
  String field;
  String type;
  bool isList;
  bool isObject;
  String itemClassName;

  Prop(this.name, this.field, this.type, this.isList, this.isObject,
      {this.itemClassName});
}
