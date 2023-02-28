class EmojiEntity {
  final String name;
  final String id;

  EmojiEntity({this.name, this.id});

  factory EmojiEntity.fromJson(Map<String, dynamic> srcJson) => EmojiEntity(
        name: Uri.decodeComponent(srcJson['name']),
        id: srcJson['id'] as String,
      );

  Map<String, dynamic> toJson() => {
        'name': Uri.encodeComponent(name),
        'id': id,
      };
}
