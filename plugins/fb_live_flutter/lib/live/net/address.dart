class Address {
  // 基础url
  // static String baseUrl = "https://test.faceuu.com";
  static String baseUrl = "https://fbapi.zeinn.net";

  // 客户端 分页查询已上架礼物列表
  static String giftPageList = '/v1/live/gift_page_list';

  // 客户端 打赏礼物给播主
  static String liveReward = '/v1/live/reward';

  // 保存用户信息
  static String saveUserinfo = '/v1/member';

  // 视频列表
  static String videolistUrl = "/v1/live/ing";

  // 主播设置回放可见范围
  static String playbackSetVisible = "/v1/playback/set_visible";

  // 违规回放申诉
  static String playbackAppeal = "/v1/playback/appeal";

  // 是否完成了回放上诉
  static String playbackIsAppeal = "/v1/playback/is_appealed";

  // 用户观看回放
  static String playbackWatch = "/v1/playback/watch";

  // 查询回放专辑
  static String playbackAlbumList = "/v1/playback_album/page_list";

  // 查询主播回放列表
  static String playbackList = "/v1/playback/page_list";

  // 图片上传接口
  static String uploadImg = '/v1/upload/img';

  // 查询系统标签
  static String getTags = '/v1/system/tags';

  // 开直播
  static String creatlive = '/v1/live/open';

  // 获取直播间基础信息
  static String getLiveInfo = '/v1/live/room/';

  // 获取zego房间登录token
  static String getZegoToken = '/v1/zego/token/';

  // 获取直播间在线用户数量
  static String getOnlineCount = '/v1/online/count/';

  // 获取直播间在线用户列表
  static String getOnlineUserList = '/v1/online/users';

  // 查询乐豆账户余额
  static String getBalance = '/v1/account/balance';

  // 主播端结束直播
  static String closeLive = '/v1/live/close/';

  // 主播端 直播开始
  static String starteLive = '/v1/live/started/';

  // 用户端 获取快速充值金币列表
  static String coinsList = '/v1/charge/coins/';

  // 用户端 充值预下单
  static String order = '/v1/charge/order';

  // 用户端 查询乐豆账户余额
  static String queryBalance = '/v1/account/balance';

  // 用户端 直播点赞
  static String thumbUp = '/v1/live/thumb';

  // 上报用户进入直播间
  static String liveEnter = '/v1/live/enter';

  // 上报用户退出直播间
  static String liveExit = '/v1/live/exit';

  // 获取礼物记录
  static String giftRoced = '/v1/live/gift/page_list';

  //获取本场直播乐豆总数
  static String giftsCount = '/v1/live/gift/sum/';

  //检查是否正在直播
  static String checkRoom = '/v1/live/check';

  //强制结束直播
  static String mandatoryClose = '/v1/live/mandatory_close/';

  //获取OBS推流地址
  static String obsAddress = '/v1/live/obs/address/';

  //开启OBS直播
  static String obsStartLive = '/v1/live/obs/start/';

  //36. 获取直播间带货地址
  static String liveCommerce = '/v1/live/commerce/';

  //38. 获取直播间概要信息
  static String liveSimple = '/v1/live/simple/';

  //39. 上报直播间屏幕尺寸
  static String liveScreenSize = '/v1/live/screen_size';

  // 42. 获取我的直播间排名
  static String onlineMyRank = '/v1/online/my_rank/';

  // 21. 直播间统计数据
  static String liveStatistics = '/v1/live/data/';

  //  ============直播带货
  // 43. 获取直播间带货信息（直播带货2.0）
  static String commerce2 = '/v1/live/commerce2/';

  // 44. 是否是直播小助手
  static String isAssistant = '/v1/live/is_assistant/';

  // 45. 主播是否具备带货能力
  static String hasCommerce = '/v1/anchor/has_commerce';

  // 46. 查询店铺商品列表
  static String shopGoodsList = '/v1/shop/goods_list';

  // 47. 获取商品详情
  static String shopGoodsDetail = '/v1/shop/goods_detail';

  // 48. 查询直播间商品列表
  static String liveGoodsList = '/v1/live/goods/list';

  // 49. 新增直播间商品
  static String liveGoodsAdd = '/v1/live/goods/add';

  // 50. 移除直播间商品
  static String liveGoodsRemove = '/v1/live/goods/remove';

  // 51. 推荐直播间商品
  static String liveGoodsRecommend = '/v1/live/goods/recommend';

  // 52. 获取直播间推荐商品
  static String liveGoodsGetRecommend = '/v1/live/goods/recommend';

  // 53. 获取直播间商品数量
  static String liveGoodsGetCount = '/v1/live/goods/count';

  // 54. 查询店铺优惠券列表
  static String shopCouponList = '/v1/shop/coupon_list';

  // 55. 直播间优惠券列表
  static String liveCouponList = '/v1/live/coupon/list';

  // 56. 新增直播间优惠券
  static String liveCouponAdd = '/v1/live/coupon/add';

  // 57. 移除直播间优惠券
  static String liveCouponRemove = '/v1/live/coupon/remove';

  // 58. 获取直播间优惠券数量
  static String liveCouponCount = '/v1/live/coupon/count';

  // 59. 获取优惠券最新库存
  static String shopCouponStock = '/v1/shop/coupon_stock';

  // 60. 用户领取直播间优惠券
  static String liveCouponSend = '/v1/live/coupon/send';

  // 61. 向购物车添加商品
  static String liveCartAdd = '/v1/live/cart/add';

  // 62. 获取购物车商品数量
  static String liveCartCount = '/v1/live/cart/count';

  // 63. 商品立即下单
  static String liveGoodsOrder = '/v1/live/goods/order';

  // 64. 检查用户是否完成有赞店铺授权
  static String youZanCheckAuth = '/v1/youzan/check_auth';

  // 65. 获取ZEGO拉流模式
  static String zegoPlayMode = '/v1/zego/play_mode';

  // 66. 【V3】刷新优惠券库存
  static String couponRefreshStock = '/v1/live/coupon/refresh_stock';

  // 67. 【V3】上报用户进入直播回放
  static String playbackEnter = '/v1/playback/enter';

  // 68. 【V3】上报用户退出直播回放
  static String playbackExit = '/v1/playback/exit';

// 69. 【V3】取消直播间推荐商品
  static String goodsCancelRecommend = '/v1/live/goods/cancel_recommend';

// 70. 【V3】查询主播生成中的回放列表
  static String playbackCreatingList = '/v1/playback/creating_list';
}
