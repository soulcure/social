import 'dart:convert';

class ReactionDetailBean {
  final String name;
  final String avatar;
  final String id;
  final List<String> users;

  ReactionDetailBean({
    this.name,
    this.avatar,
    this.id,
    this.users,
  });

  ReactionDetailBean copyWith({
    String name,
    String avatar,
    String id,
    List<String> users,
  }) {
    return ReactionDetailBean(
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      id: id ?? this.id,
      users: users ?? this.users,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'avatar': avatar,
      'id': id,
      'users': users,
    };
  }

  factory ReactionDetailBean.fromMap(Map<String, dynamic> map) {
    String name = map['name'];
    try {
      name = Uri.decodeComponent(name);
    } catch (e) {
      print(e);
    }
    return ReactionDetailBean(
      name: name,
      avatar: map['avatar'],
      id: map['id'],
      users: List<String>.from(map['users']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ReactionDetailBean.fromJson(String source) =>
      ReactionDetailBean.fromMap(json.decode(source));

  @override
  String toString() {
    return 'ReactionDetailBean(name: $name, avatar: $avatar, id: $id, users: $users)';
  }
}
