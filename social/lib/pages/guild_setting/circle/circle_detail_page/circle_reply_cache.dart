class CircleReplyCache {
  static final CircleReplyCache _singleton = CircleReplyCache._internal();

  factory CircleReplyCache() {
    return _singleton;
  }

  CircleReplyCache._internal();

  void putCache(String commentId, String content) {
    if (commentId == null ||
        content == null ||
        commentId.isEmpty ||
        content.isEmpty) return;
    _memCache[commentId] = content;
  }

  void removeCache(String commentId) {
    if (commentId == null || commentId.isEmpty) return;
    _memCache.remove(commentId);
  }

  String readCache(String commentId) {
    if (commentId == null || commentId.isEmpty) return '';
    final result = _memCache[commentId];
    return result ?? '';
  }

  ///key为commentId, value为内容
  final Map<String, String> _memCache = {};
}
