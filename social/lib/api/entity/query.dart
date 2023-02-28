import "../entity/user.dart";

class EntityQuery {
  int id;
  EntityUser from;
  dynamic location;
  String query;
  String offset;

  EntityQuery.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    from = EntityUser.fromJson(json["from"]);
    location = json["location"];
    query = json["query"];
    offset = json["offset"];
  }
}
