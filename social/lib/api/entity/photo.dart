class EntityPhoto {
  String smallFileId;
  String smallFileUniqueId;
  String bigFileId;
  String bigFileUniqueId;

  EntityPhoto.fromJson(Map<String, dynamic> json) {
    smallFileId = json["small_file_id"];
    smallFileUniqueId = json["small_file_unique_id"];
    bigFileId = json["big_file_id"];
    bigFileUniqueId = json["big_file_unique_id"];
  }
}
