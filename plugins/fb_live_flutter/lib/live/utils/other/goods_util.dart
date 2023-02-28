class GoodsUtil {
  /// 加入小程序后缀，
  /// 所有直播带货调用[fbApi.pushLinkPage]的都需要使用此方法来拼接url后缀
  ///
  /// 所有直播带货url拼接小程序后缀
  /// [2021 11.10]
  ///
  /// 再次优化方法
  /// [2021 11.24]
  static String joinMiniProgramSuffix(String url) {
    if (!url.contains('?')) {
      url = "$url?";
    }
    final String centerStr = url.endsWith("&") || url.endsWith("?") ? "" : "&";
    return '$url$centerStr' 'fb_redirect&open_type=mp';
  }
}
