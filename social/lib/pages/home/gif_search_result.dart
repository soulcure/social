class GifSearchResult {
  String url;
  String authorName;
  int h;
  int w;
  String id;
  int isVideo;

  GifSearchResult(
      {this.url, this.authorName, this.h, this.w, this.id, this.isVideo});

  GifSearchResult.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    authorName = json['author_name'];
    h = json['h'];
    w = json['w'];
    id = json['id'];
    isVideo = json['isvideo'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['url'] = url;
    data['author_name'] = authorName;
    data['h'] = h;
    data['w'] = w;
    data['id'] = id;
    data['isvideo'] = isVideo;
    return data;
  }
}
