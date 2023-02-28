class DocTypeInfo {
  String type;
  String desc;

  DocTypeInfo({this.type, this.desc});

  factory DocTypeInfo.fromMap(Map<String, dynamic> map) {
    return DocTypeInfo(
      type: map['type'] as String,
      desc: map['desc'] as String,
    );
  }
}

class DocTypeItem {
  List<DocTypeInfo> docTypeList;

  DocTypeItem({
    this.docTypeList,
  });

  factory DocTypeItem.fromMap(Map<String, dynamic> map) {
    final List lists = map['list'];
    final List<DocTypeInfo> docList =
        lists.map((e) => DocTypeInfo.fromMap(e)).toList();

    return DocTypeItem(docTypeList: docList);
  }
}
