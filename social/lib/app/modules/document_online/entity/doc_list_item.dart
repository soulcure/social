import 'doc_item.dart';

class DocListItem {
  int total;
  List<DocItem> docList;
  int size;

  DocListItem({
    this.total,
    this.docList,
    this.size,
  });

  factory DocListItem.fromMap(Map<String, dynamic> map) {
    final List lists = map['lists'];
    final List<DocItem> docList = lists.map((e) => DocItem.fromMap(e)).toList();

    return DocListItem(
      total: map['total'] as int,
      docList: docList,
      size: map['size'] as int,
    );
  }
}
