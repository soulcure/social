/// total : 4
/// users : [117950755050098688]

class TopicAvatar {
  int total;
  List<int> users;

  TopicAvatar.fromMap(Map<String, dynamic> map) {
    total = map['total'];
    users = [
      ...(map['users'] as List ?? []).map((o) => int.tryParse(o.toString()))
    ];
  }

  Map toJson() => {
        "total": total,
        "users": users,
      };
}
