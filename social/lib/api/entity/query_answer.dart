import "../entity/query_result_article.dart";

class EntityQueryAnswer {
  String inlineQueryId;
  List<EntityQueryResultArticle> results;
  int cacheTime;
  bool isPersonal;
  String nextOffset;
  String switchPmText;
  String switchPmParameter;

  EntityQueryAnswer.fromJson(Map<String, dynamic> json) {
    inlineQueryId = json["inline_query_id"];
    if (json["results"] != null) {
      results = List.from(
        json["results"].map(
          (v) => EntityQueryResultArticle.fromJson(v),
        ),
      );
    }
    cacheTime = json["cache_time"];
    isPersonal = json["is_personal"];
    nextOffset = json["next_offset"];
    switchPmText = json["switch_pm_text"];
    switchPmParameter = json["switch_pm_parameter"];
  }
}
