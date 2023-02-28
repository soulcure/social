// // ignore_for_file: avoid_annotating_with_dynamic
//
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
//
// import 'package:dio/dio.dart';
// import 'package:fb_live_flutter/fb_live_flutter.dart';
// import 'package:fb_live_flutter/live/api/page/aid_page.dart';
// import 'package:fb_live_flutter/live/api/page/mock_html_page.dart';
// import 'package:fb_live_flutter/live/api/page/test_share_page.dart';
// import 'package:fb_live_flutter/live/api/test/show_bottom_sheetview.dart';
// import 'package:fb_live_flutter/live/api/test/test_plugin.dart';
// import 'package:fb_live_flutter/live/api/widget/select_channel_dialog.dart';
// import 'package:fb_live_flutter/live/event_bus_model/emoji_keyboard_model.dart';
// import 'package:fb_live_flutter/live/model/goods/goods_push_model.dart';
// import 'package:fb_live_flutter/live/pages/create_room/widget/image_upload.dart';
// import 'package:fb_live_flutter/live/utils/config/route_config.dart';
// import 'package:fb_live_flutter/live/utils/config/route_path.dart';
// import 'package:fb_live_flutter/live/utils/func/router.dart';
// import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
// import 'package:fb_live_flutter/live/utils/manager/event_bus_manager.dart';
// import 'package:fb_live_flutter/live/utils/manager/sp_manager.dart';
// import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
// import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
// import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
// import 'package:fb_live_flutter/live/widget_common/loading/ball_circle_pulse_loading.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:image_cropper/image_cropper.dart';
// import 'package:image_picker/image_picker.dart' as native_image_picker;
// import 'package:image_picker/image_picker.dart';
//
// import 'net/log_interceptor.dart';
// // import 'package:rich_input/rich_input.dart';
//
// // ignore: avoid_js_rounded_ints
// String channelId = "125113909345521999";
//
// //用户01，http://www.pmpmpm.cn/wp-content/images/1.png
// //用户02，http://www.pmpmpm.cn/wp-content/images/2.png
// //用户03，http://www.pmpmpm.cn/wp-content/images/3.png
// //用户04，http://www.pmpmpm.cn/wp-content/images/4.png
// //用户05，http://www.pmpmpm.cn/wp-content/images/5.png
// //用户06，http://www.pmpmpm.cn/wp-content/images/6.png
// //用户07，http://www.pmpmpm.cn/wp-content/images/7.png
// //用户08，http://www.pmpmpm.cn/wp-content/images/8.png
// //用户09，http://www.pmpmpm.cn/wp-content/images/9.png
// //用户10，http://www.pmpmpm.cn/wp-content/images/10.png
// //
// //横屏标准封面   http://www.pmpmpm.cn/wp-content/images/heng.png
// //竖屏标准封面   http://www.pmpmpm.cn/wp-content/images/shu.png
// class ApiProviderDev extends LiveApiProvider {
//   final bool _inAVChannel = true;
//   FBLiveMsgHandler? _handler;
//   Timer? _mockTimer;
//   int index = 0;
//   bool isInLiveRoom = false;
//
//   //1.1、获取 token
//   @override
//   String? getToken() {
//     // SharedPreferences prefs = await SharedPreferences.getInstance();
//     return SPManager.sp!.getString("Authentication");
//   }
//
//   //1.2、获取自己的ID
//   @override
//   String? getUserId() {
//     // SharedPreferences prefs = await SharedPreferences.getInstance();
//     return SPManager.sp!.getString("user_id");
//   }
//
//   //1.3、获取用户信息
//   @override
//   Future<FBUserInfo> getUserInfo(String userId,
//       {required String guildId}) async {
//     FBUserInfo testUserInfo(int index) {
//       return FBUserInfo(
//           userId: userId,
//           shortId: userId.substring(0, 5),
//           avatar: "http://www.pmpmpm.cn/wp-content/images/$index.png",
//           nickname: "测试$index$index$index",
//           name: "aaaa$index$index$index",
//           guildName: "服务器昵称1");
//     }
//
//     if (userId == "125113909345521111") {
//       return testUserInfo(1);
//     } else if (userId == "125113909345521222") {
//       return testUserInfo(2);
//     } else if (userId == "125113909345521333") {
//       return testUserInfo(3);
//     } else if (userId == "125113909345521444") {
//       return testUserInfo(4);
//     } else if (userId == "125113909345521555") {
//       return testUserInfo(5);
//     } else if (userId == "125113909345521666") {
//       return testUserInfo(6);
//     } else if (userId == "125113909345521777") {
//       return testUserInfo(7);
//     } else if (userId == "125113909345521888") {
//       return testUserInfo(8);
//     } else if (userId == "125113909345521999") {
//       return testUserInfo(9);
//     }
//     return FBUserInfo(
//         shortId: "12",
//         userId: "1234",
//         avatar: "http://www.pmpmpm.cn/wp-content/images/1.png",
//         name: "测试123",
//         nickname: "nick1",
//         guildName: "服务器昵称1");
//   }
//
//   //1.4、获取当前频道信息
//   @override
//   FBChatChannel? getCurrentChannel() {
//     return FBChatChannel(
//       id: channelId,
//       // id: SPManager.sp.getString("user_id"),
//       name: "直播频道",
//       topic: "用来直播的频道",
//       guildId: "171963015145455616",
//       guildName: "直播测试服务器",
//     );
//   }
//
//   // 1.5、获取指定服务器的频道列表
//   @override
//   List<FBChatChannel> getGuildChannels(String guildId) {
//     return List.generate(5, (index) {
//       return FBChatChannel(
//         id: "125113909345521999",
//         name: "模拟频道$index",
//         guildId: "171963015145455616",
//         guildName: "直播测试服务器mock",
//         topic: "用来直播的频道",
//       );
//     });
//   }
//
//   //1.5、获取直播间是否是测试环境
//   @override
//   bool liveIsTestEnv() {
//     return true;
//   }
//
//   //2.1、是否在音视频频道
//   @override
//   bool inAVChannel() {
//     return _inAVChannel;
//   }
//
//   //2.2、退出音视频频道
//   @override
//   Future<bool> exitAVChannel() async {
//     print('退出音视频频道');
//     return true;
//   }
//
//   //2.3、是否有开播权限
//   @override
//   bool canStartLive() {
//     return true;
//   }
//
//   //2.4、审核创建直播间
//   @override
//   Future<bool> inspectLiveRoom({String? desc, List<String>? tags}) async {
//     return true;
//   }
//
//   //2.5、进入直播间
//   @override
//   Future enterLiveRoom(String channelId, String roomId, bool isAnchor,
//       String guildId, bool isSmallWindow) async {
//     print('进入直播间');
//   }
//
//   //2.6 离开直播间
//   @override
//   Future exitLiveRoom(String guildId, String channelId, String roomId) async {
//     print('离开直播间');
//     // _handler.onUserQuit(FBUserInfo());
//   }
//
//   //2.7、停止直播
//   @override
//   Future stopLive(String guildId, String channelId, String roomId) async {
//     print('停止直播');
//     // _handler.onLiveStop();
//   }
//
//   //2.8、充值
//   @override
//   Future<PaymentResult> charge({
//     required BuildContext context,
//     required String orderId,
//     required String productId,
//     required double price,
//     required String productName,
//     required String appId,
//     int? quantity,
//     double? totalPrice,
//     ProductType? productType,
//     String? extra,
//   }) async {
//     final PaymentResult paymentResult =
//         PaymentResult(status: PaymentStatus.completed, orderId: "123");
//     return paymentResult;
//   }
//
//   //2.9、审核聊天消息
//   @override
//   Future<bool> inspectChatMsg(String msg) {
//     final Completer<bool> completer = Completer();
//     completer.complete(true);
//     return completer.future;
//   }
//
//   //3.1、发送弹幕消息
//   // @param roomId: 直播间房间id
//   // @param msg: 弹幕消息
//   // @param json: 自定义消息，json字符串
//   @override
//   Future sendLiveMsg(
//       String guildId, String channelId, String roomId, String json) {
//     return Future.value();
//   }
//
//   //3.2、发送礼物消息
//   // @param roomId: 直播间房间id
//   // @param giftId: 礼物id
//   // @param json: 自定义消息，json字符串
//   @override
//   Future sendLiveGift(
//       String guildId, String channelId, String roomId, String json) {
//     return Future.value();
//   }
//
// //  3.3、发送商品消息
//   // @param guildId String 直播间所属服务台
//   // @param channelId String 直播间所属频道id
//   // @param roomId String 直播间房间id
//   // @param type String 行为类型
//   //        商品推送：'productPush',
//   //        商品移除：'productRemove',
//   //        优惠券推送：'couponPush' ,
//   //        优惠券移除：'couponRemove'
//   // @param json String 自定义消息
//   @override
//   Future sendGoodsNotice(String guildId, String channelId, String roomId,
//       String type, String json) async {}
//
//   //1、mock回调数据
//   void _cancelMockTimer() {
//     _mockTimer?.cancel();
//   }
//
//   void _createMoreInfo(int msgNum) {
//     for (var i = 0; i < msgNum; i++) {
//       final random = Random();
//       final String nickName = "测试用户-${index++}";
//       final FBUserInfo _userInfo = FBUserInfo(
//           nickname: nickName,
//           userId: "1234",
//           shortId: "1234",
//           avatar: "http://www.pmpmpm.cn/wp-content/images/1.png",
//           name: "测试123"
//           // userId: "${random.nextInt(100)}",
//           ,
//           guildName: "服务器昵称1");
//       final String _msgJsonStr =
//           formatMsgJSON('这是一条输入消息～${random.nextInt(100)}');
//       // final String _giftJsonStr = formatGiftJSON(
//       //     giftId: 1,
//       //     giftName: '小飞猪${random.nextInt(100)}',
//       //     giftQt: 3,
//       //     giftImgUrl:
//       //         'https://abc-1304742102.cos.ap-shenzhen-fsi.myqcloud.com/20210118-a15dbea7-f341-48e6-8d3a-7a89df4182d4.png');
//
//       // 发送一条用户登录消息
//       // _handler.onUserEnter(_userInfo);
//       if (kDebugMode) {
//         // 发送一条回调消息
//         _handler!.onReceiveChatMsg(_userInfo, _msgJsonStr);
//       }
//       // 发送一条礼物回调消息
//       // _handler.onSendGift(_userInfo, _giftJsonStr);
//     }
//   }
//
//   void _initRoomHandler() {
//     _cancelMockTimer();
//     _mockTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
//       // 发送多条模拟消息
//       _createMoreInfo(1);
//     });
//   }
//
//   // 格式化发送消息-JSON-String
//   String formatMsgJSON(String content) {
//     final Map msgJSON = {};
//     msgJSON['content'] = content;
//     msgJSON['type'] = "user_chat";
//
//     return json.encode(msgJSON);
//   }
//
//   // 格式化发送礼物消息-JSON-String
//   String formatGiftJSON(
//       {int? giftId, String? giftName, int? giftQt, String? giftImgUrl}) {
//     final Map giftJSON = {};
//     giftJSON['giftId'] = giftId;
//     giftJSON['giftName'] = giftName;
//     giftJSON['giftQt'] = giftQt;
//     giftJSON['giftImgUrl'] = giftImgUrl;
//     giftJSON['type'] = "gifts";
//
//     return json.encode(giftJSON);
//   }
//
//   //3.3 ignore: use_setters_to_change_properties
//   // 注册消息接收回调
//   @override
//   void registerLiveMsgHandler(FBLiveMsgHandler handler) {
//     _handler = handler;
//     _initRoomHandler();
//   }
//
//   //3.4、移除消息接收回调
//   @override
//   void removeLiveMsgHandler(FBLiveMsgHandler handler) {
//     _handler = null;
//     _cancelMockTimer();
//   }
//
//   void onRecvGroupTextMessage(
//     String msgID,
//     String groupID,
//     String text,
//   ) {
//     print("收到聊天消息::$text");
//     try {
//       final Map map = json.decode(text);
//       if (map.containsKey('giftImgUrl') && map.containsKey("giftId")) {
//         _handler!.onSendGift(
//             FBUserInfo(
//                 shortId: "12",
//                 userId: "1234",
//                 avatar: "http://www.pmpmpm.cn/wp-content/images/1.png",
//                 nickname: "测试123",
//                 name: "nick1",
//                 guildName: "服务器昵称1"),
//             text);
//       } else if (map['content'] == '来了') {
//         _handler!.onUserEnter(FBUserInfo(
//             shortId: "12",
//             userId: "1234",
//             avatar: "http://www.pmpmpm.cn/wp-content/images/1.png",
//             nickname: "测试123",
//             name: "nick1",
//             guildName: "服务器昵称1"));
//       } else if (map['content'] == 'pushGoods') {
//         _handler!.onGoodsNotice(
//             FBUserInfo(
//                 shortId: "12",
//                 userId: "1234",
//                 avatar: "http://www.pmpmpm.cn/wp-content/images/1.png",
//                 nickname: "测试123",
//                 name: "nick1",
//                 guildName: "服务器昵称1"),
//             "productPush",
//             json.encode(GoodsPushModel.fromJson(map as Map<String, dynamic>)));
//       } else if (map['content'] == 'couponPush') {
//         _handler!.onGoodsNotice(
//             FBUserInfo(
//                 shortId: "12",
//                 userId: "1234",
//                 avatar: "http://www.pmpmpm.cn/wp-content/images/1.png",
//                 nickname: "测试123",
//                 name: "nick1",
//                 guildName: "服务器昵称1"),
//             "couponPush",
//             text);
//       } else if (map['content'] == 'productRemove') {
//         _handler!.onGoodsNotice(
//             FBUserInfo(
//                 shortId: "12",
//                 userId: "1234",
//                 avatar: "http://www.pmpmpm.cn/wp-content/images/1.png",
//                 nickname: "测试123",
//                 name: "nick1",
//                 guildName: "服务器昵称1"),
//             "productRemove",
//             text);
//       } else {
//         _handler!.onReceiveChatMsg(
//             FBUserInfo(
//                 shortId: "12",
//                 userId: "1234",
//                 avatar: "http://www.pmpmpm.cn/wp-content/images/1.png",
//                 nickname: "测试123",
//                 name: "nick1",
//                 guildName: "服务器昵称1"),
//             text);
//       }
//     } catch (e) {
//       _handler!.onReceiveChatMsg(
//           FBUserInfo(
//               shortId: "12",
//               userId: "1234",
//               avatar: "http://www.pmpmpm.cn/wp-content/images/1.png",
//               nickname: "测试123",
//               name: "nick1",
//               guildName: "服务器昵称1"),
//           text);
//     }
//   }
//
//   // 3.4、查询直播间历史消息
//   @override
//   Future<List<Map<String, dynamic>>> getLiveHistoryMessages(
//     String userId,
//     String roomId, {
//     String? lastMessageId,
//   }) async {
//     if (strNoEmpty(lastMessageId) && int.parse(lastMessageId!) < 50) {
//       return [];
//     }
//
//     print(
//         "getLiveHistoryMessages[查询直播间历史消息] ==> 传输lastMessageId::$lastMessageId");
//     return List.generate(50, (index) {
//       final lastIndex =
//           strNoEmpty(lastMessageId) ? int.parse(lastMessageId!) : 0;
//       final int newIndex = (100 - lastIndex) - index;
//       if (index.isEven) {
//         return {
//           "channel_id": "12121212",
//           "message_id": "$newIndex",
//           "content": () {
//             final Map msgJSON = {};
//             msgJSON['content'] = "我是消息$newIndex";
//             return json.encode(msgJSON);
//           }(),
//           "user_id": "2121",
//           "guild_id": "22313",
//           "time": 2222,
//           "type": "user_chat",
//           "author": {
//             "nickname": "hahaha",
//             "username": "#hahaha",
//             "avatar":
//                 "https://abc-1304742102.cos.ap-shenzhen-fsi.myqcloud.com/20210118-a15dbea7-f341-48e6-8d3a-7a89df4182d4.png",
//           },
//         };
//       }
//       // if (index.isEven) {
//       return {
//         "message_id": "$newIndex",
//         "channel_id": "12121212",
//         "content": () {
//           final Map giftJSON = {};
//           giftJSON['giftId'] = "giftId";
//           giftJSON['giftName'] = "giftName";
//           giftJSON['giftQt'] = "giftQt";
//           giftJSON['giftImgUrl'] =
//               "https://abc-1304742102.cos.ap-shenzhen-fsi.myqcloud.com/20210123-067b3ba8-a1b2-4b84-9636-36f0b1ac9701.png";
//           return json.encode(giftJSON);
//         }(),
//         "user_id": "2121",
//         "guild_id": "22313",
//         "time": 2222,
//         "type": "user_chat",
//         "author": {
//           "nickname": "hahaha",
//           "username": "#hahaha",
//           "avatar":
//               "https://abc-1304742102.cos.ap-shenzhen-fsi.myqcloud.com/20210118-a15dbea7-f341-48e6-8d3a-7a89df4182d4.png",
//         },
//       };
//       // }
//       // return {
//       //   "channel_id": "12121212",
//       //   "content": json.encode(
//       //       {"user": FBUserInfo(), "text": "来了", "type": "user_coming"}),
//       //   "user_id": "2121",
//       //   "guild_id": "22313",
//       //   "time": 2222,
//       //   "type": "user_chat",
//       //   "author": {
//       //     "nickname": "hahaha",
//       //     "username": "#hahaha",
//       //     "avatar":
//       //         "https://abc-1304742102.cos.ap-shenzhen-fsi.myqcloud.com/20210118-a15dbea7-f341-48e6-8d3a-7a89df4182d4.png",
//       //   },
//       // };
//     });
//   }
//
//   // 3.6、发送直播间重连通知
//   @override
//   Future sendLiveConnect(
//       String guildId, String channelId, String roomId) async {
//     print("发送直播间重连通知，guildId:$guildId,channelId:$channelId,roomId:$roomId");
//   }
//
//   // 4.1、用户信息头部组件
//   @override
//   Widget userInfoComponent(
//     BuildContext context,
//     String userId, {
//     required String guildId,
//   }) {
//     return Container(
//       alignment: Alignment.center,
//       width: FrameSize.winWidth(),
//       height: FrameSize.px(278),
//       child: Text(
//         '作者ID:$userId',
//         style: TextStyle(
//           fontSize: FrameSize.px(24),
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }
//
//   //4.1、唤起用户个人信息弹窗
//   @override
//   void showUserInfoPopUp(
//     BuildContext context,
//     String userId, {
//     required String guildId,
//     bool showRemoveFromGuild = true,
//     bool hideGuildName = false,
//   }) {
//     print('唤起用户弹窗, 用户: $userId,guildId:$guildId');
//     showDialog(
//         context: context,
//         builder: (_) {
//           return ClickEvent(
//             child: Material(
//               type: MaterialType.transparency,
//               child: Center(
//                 child: Container(
//                   width: 200,
//                   height: 200,
//                   color: Colors.white,
//                   child: Text('唤起用户弹窗, 用户: $userId,guildId:$guildId'),
//                 ),
//               ),
//             ),
//             onTap: () async {
//               RouteUtil.pop();
//             },
//           );
//         });
//   }
//
//   //4.2、唤起分享弹窗
//   @override
//   Future showShareLinkPopUp(
//     BuildContext context,
//     FBShareContent content,
//   ) async {
//     await RouteUtil.push(
//         context,
//         Scaffold(
//           appBar: AppBar(
//             actions: [
//               const TextButton(
//                 onPressed: TestPlugin.testJumpToLogin,
//                 child: Text(
//                   '跳转原生登录页',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {
//                   RouteUtil.push(context, TestSharePage(), "test_share");
//                 },
//                 child: const Text(
//                   '跳转内页',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//           body: SelectableText(
//             '唤起分享弹窗, type：${content.type},\n roomId：${content.roomId},\n canWatchOutside：${content.canWatchOutside},\n '
//             '服务器ID：${content.guildId}\n 频道D：${content.channelId}\n 主播昵称：${content.anchorName}\n 房间logo：${content.coverUrl}'
//             '像素比例：${FrameSize.pixelRatio()}',
//           ),
//         ),
//         'share');
//     // myToast(
//     //   '唤起分享弹窗, type：${content.type},\n roomId：${content.roomId},\n canWatchOutside：${content.canWatchOutside},\n '
//     //   '服务器ID：${content.guildId}\n 频道D：${content.channelId}\n 主播昵称：${content.anchorName}\n 房间logo：${content.coverUrl}',
//     // );
//   }
//
//   //4.3、选择图片
//   @override
//   Future<File?> pickImage(
//     BuildContext context, {
//     bool crop = true,
//     CropAspectRatio? cropRatio,
//     int compressQuality = 100,
//     int? maxWidth,
//     int? maxHeight,
//   }) async {
//     final List _pickerSheetList = ["拍照", '从手机相册选择', '取消'];
//     final Completer<File> completer = Completer();
//
//     await showModalBottomSheet(
//         backgroundColor: Colors.transparent,
//         context: context,
//         builder: (context) {
//           return ShowBottomSheet(
//             titleList: _pickerSheetList,
//             onItemClickListener: (index) async {
//               final native_image_picker.ImagePicker picker =
//                   native_image_picker.ImagePicker();
//               if (index == 0) {
//                 final PickedFile? pickedFile = await picker.getImage(
//                     source: native_image_picker.ImageSource.camera);
//                 print(pickedFile!.path);
//                 completer.complete(File(pickedFile.path));
//               } else {
//                 final PickedFile? pickedFile = await picker.getImage(
//                     source: native_image_picker.ImageSource.gallery);
//                 completer.complete(File(pickedFile!.path));
//               }
//             },
//           );
//         });
//     final File imageFile = await completer.future;
//
//     final File? croppedFile = await ImageCropper.cropImage(
//         sourcePath: imageFile.path,
//         aspectRatio: cropRatio,
//         aspectRatioPresets: [
//           CropAspectRatioPreset.square,
//           CropAspectRatioPreset.ratio3x2,
//           CropAspectRatioPreset.original,
//           CropAspectRatioPreset.ratio4x3,
//           CropAspectRatioPreset.ratio16x9
//         ],
//         androidUiSettings: const AndroidUiSettings(
//             toolbarTitle: 'Cropper',
//             toolbarColor: Colors.deepOrange,
//             toolbarWidgetColor: Colors.white,
//             initAspectRatio: CropAspectRatioPreset.original,
//             lockAspectRatio: false),
//         iosUiSettings: const IOSUiSettings(
//           minimumAspectRatio: 1,
//         ));
//
//     return croppedFile;
//   }
//
//   /// web端图片上传
//   @override
//   Future<Map?> webPickImage() {
//     final Completer<Map> completer = Completer();
//     ImageUpload.uploadImage().then(completer.complete);
//     return completer.future;
//   }
//
//   //4.5、唤起底部modal弹窗
//   // @param body: 弹窗内容组件
//   // @param header: 小横线下方，内容组件上方
//   // @param backgroundColor: 弹窗背景颜色
//   // @param showTopCache: 是否显示顶部小横线
//   // @param maxHeight: 其值为：弹窗展开的高度/屏幕高度，取值区间：(0, 1]
//   @override
//   void showBottomModal(
//     BuildContext context, {
//     required Widget body,
//     Widget? header,
//     Color? backgroundColor,
//     bool showTopCache = true,
//     double maxHeight = 0.9,
//   }) {
//     myToast('唤起底部modal弹窗');
//   }
//
//   //4.6、唤起底部ActionSheet
//   // @param actions: ActionSheet的item列表
//   // @param title: 标题文字，位于ActionSheet上方
//   @override
//   Future<int?> showActionSheet(
//     BuildContext context,
//     List<Widget> actions, {
//     String? title,
//   }) async {
//     return selectFbMockDialog(context, actions: actions, title: title);
//   }
//
//   //4.8、上传直播相关文件
//   // @param file: 要上传的文件
//   @override
//   Future<String> uploadFile(File file) async {
//     return "http://mock.image.com/mocked_image.png";
//   }
//
//   //4.9、emoji表情键盘，当点击某个emoji表情时，会自动在输入框中添加该emoji表情
//   // ignore: missing_return
//   @override
//   void showEmojiKeyboard(
//     BuildContext context, {
//     OnSendText? onSendText,
//     int? maxLength,
//     TextEditingController? inputController,
//     double offset = 250,
//   }) {
//     showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         backgroundColor: Colors.transparent,
//         builder: (context) {
//           return MockKeyBord(
//             controller: inputController,
//             onSubmitted: (text) {
//               onSendText!(text);
//               _handler!.onReceiveChatMsg(
//                   FBUserInfo(
//                       shortId: "12",
//                       userId: getUserId()!,
//                       avatar: "http://www.pmpmpm.cn/wp-content/images/1.png",
//                       nickname: "测试123",
//                       name: "nick1",
//                       guildName: "服务器昵称1"),
//                   json.encode({"content": text}));
//               RouteUtil.pop();
//             },
//           );
//         }).then((value) {
//       Future.delayed(const Duration(milliseconds: 100)).then((value) {
//         EventBusManager.eventBus.fire(EmojiKeyBoardModel(height: 0));
//       });
//     });
//   }
//
//   //4.10、emoji文本
//   @override
//   InlineSpan buildEmojiText(
//     BuildContext context,
//     String content, {
//     TextStyle? textStyle,
//   }) {
//     return TextSpan(text: content, style: textStyle);
//   }
//
//   //4.11、打开跳转到网页
//   @override
//   Future pushHTML(BuildContext context, String url, {String? title}) async {
//     myToast('打开跳转到网页:$url');
//   }
//
//   //4.12、路由跳转
//   @override
//   Future push(
//     BuildContext context,
//     Widget page,
//     String name, {
//     bool isReplace = false,
//   }) {
//     // try {
//     return isReplace
//         ? Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => page,
//                 settings: RouteSettings(name: name)))
//         : Navigator.push(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => page,
//                 settings: RouteSettings(name: name)));
//     // } catch (e) {
//     //   print("路由跳转出现异常：${e.toString()},isReplace::$isReplace");
//     //   return Future.value();
//     // }
//   }
//
//   @override
//   Widget htmlPage(String url, {String? title}) {
//     return MockHtmlPage(url, title);
//   }
//
//   @override
//   AssetImage getFanbookIcon() {
//     return const AssetImage("assets/live/LiveRoom/userlogo.png");
//   }
//
//   //4.14、是否弹出送礼弹窗
//
//   @override
//   bool? isShowGiftConfirmDialog() {
//     final bool? show = SPManager.sp!.getBool("isShow");
//     return show;
//   }
//
//   //4.15、设置是否弹出过送礼弹窗
//
//   @override
//   void setShowGiftConfirmDialog(bool isShow) {
//     SPManager.sp!.setBool('isShow', isShow);
//   }
//
//   //4.16、获取用户列表是否有备注名称
//   @override
//   Map<String, String> getMarkNames(List<String> userIds) {
//     final Map<String, String> _userMarkInfo = {};
//     if (userIds.isNotEmpty) {
//       userIds.forEach((userId) {
//         if (userId == '125113909345521777') {
//           _userMarkInfo[userId] = '测试00';
//         }
//       });
//     }
//     return _userMarkInfo;
//   }
//
//   // 1.8、获取指定用户备注名
//   @override
//   String? getMarkName(String? userId) {
//     return null;
//   }
//
// //  1.9、获取用户显示名
//   @override
//   Future<Map<String, String>> getShowNames(List<String> userIds,
//       {required String guildId}) async {
//     print("获取用户显示名:$userIds,guildId$guildId");
//     final Map<String, String> data = {};
//     for (final String userId in userIds) {
//       if (!strNoEmpty(guildId)) {
//         data[userId] = "error";
//       } else {
//         if (!strNoEmpty(userId)) {
//           data[userId] = "游客";
//         }
//         if (guildId == getCurrentChannel()!.guildId) {
//           data[userId] = "aaaa${userId.replaceAll("12511390934552", "")}";
//         } else {
//           data[userId] = "show${userId.replaceAll("12511390934552", "")}";
//         }
//       }
//     }
//     return data;
//   }
//
//   @override
//   Future<String> getShowName(String userId, {required String guildId}) async {
//     if (!strNoEmpty(guildId)) {
//       return "error";
//     }
//
//     if (guildId == getCurrentChannel()!.guildId) {
//       return "aaaa${userId.replaceAll("12511390934552", "")}";
//     } else {
//       return "show${userId.replaceAll("12511390934552", "")}";
//     }
//   }
//
//   //  void saveRoomInfo(String roomInfo) {
//   //
//   // }
//   @override
//   Future<bool> setSharePref(String key, dynamic value) {
//     return SPManager.sp!.setString(key, value);
//   }
//
//   @override
//   dynamic getSharePref(String key) {
//     final String? data = SPManager.sp!.getString(key);
//     return data;
//   }
//
//   //  String getData(String key) {
//   //   final String data = SPManager.sp.getString(key);
//   //   return data;
//   // }
//
//   // 4.17 实时用户姓名组件
//   @override
//   Widget realtimeUserName(
//     String userId, {
//     required String guildId,
//     required TextStyle style,
//     int maxLines = 1,
//     bool isGuest = false,
//     String? guestName,
//   }) {
//     if (isGuest) {
//       return Text(
//         guestName ?? '游客',
//         style: style,
//         maxLines: maxLines,
//       );
//     }
//     return Text(
//       "姓名-昵称",
//       style: style,
//       maxLines: maxLines,
//     );
//   }
//
//   // 4.18 实时用户头像组件
//   @override
//   Widget realtimeAvatar(
//     String userId, {
//     double size = 30,
//     bool isGuest = false,
//   }) {
//     return CircleAvatar(
//       backgroundImage: fbApi.getFanbookIcon(),
//       radius: size / 2,
//     );
//   }
//
//   //4.18、注册关闭小窗回调
//   @override
//   void registerLiveCloseListener(OnLiveClose onClose) {}
//
//   //4.19、注销关闭小窗回调
//   @override
//   void unregisterLiveCloseListener(OnLiveClose onClose) {}
//
//   //4.22、注册事件监听函数
//
//   @override
//   void addFBLiveEventListener(FBLiveEventListener listener) {}
//
//   //4.23、注销事件监听函数
//
//   @override
//   void removeFBLiveEventListener(FBLiveEventListener listener) {}
//
//   // 5.1、消息推送
//   @override
//   Future pushNotification({
//     required String title,
//     required String content,
//     required String subtitle,
//     DateTime? fireTime,
//     bool addBadge = false,
//     Map<String, String>? extra,
//   }) {
//     print("FBAPI ==> pushNotification");
//     print("title:$title,content:$content,subtitle$subtitle,fireTime:$fireTime");
//     return Future.value();
//   }
//
// //  5.2、日志埋点
// //   5.2.1、行为事件
//   @override
//   void customEvent({
//     String actionEventId = '',
//     String actionEventSubId = '',
//     String actionEventSubParam = '',
//     String pageId = '',
//     required Map extJson,
//   }) {
//     print("FBAPI 行为事件");
//     print(
//         "actionEventId:$actionEventId,actionEventSubId:$actionEventSubId,actionEventSubParam$actionEventSubParam,pageId:$pageId,extJson:$extJson");
//   }
//
//   // 5.2.2、扩展事件
//   @override
//   void extensionEvent({required String logType, Map? extJson}) {
//     fbLogger.info("FBAPI 扩展事件");
//     fbLogger.info("logType:$logType,extJson:$extJson");
//   }
//
// // /*
// // * 获取eventBus
// // * */
// //  EventBus eventBus() {
// //   return webViewBus;
// // }
// //
// // /*
// // * 销毁eventBus
// // * */
// //  void destroyEventBus() {
// //   webViewBus.destroy();
// // }
//
//   /*
//   * 跳转链接页面-小程序-webView等
//   * */
//   @override
//   Future pushLinkPage(BuildContext context, String url, {String? title}) {
//     return RouteUtil.push(context, htmlPage(url, title: title), RoutePath.html);
//   }
//
// //  4.26、添加小助手页面
//   @override
//   Future pushAddAssistantsPage(
//       String guildId, List<FBUserInfo>? defaultSelectedUsers) {
//     print("defaultSelectedUsers::${defaultSelectedUsers.toString()}");
//     return RouteUtil.push(fbApi.globalNavigatorKey.currentContext,
//         AidPage(defaultSelectedUsers), "/aid_page");
//   }
//
// //  4.27、多选框小组件
//   /// 目前只有小助手用了，添加禁用样式后把添加商品和添加优惠券相关也换上
//   @override
//   Widget checkboxIcon(bool selected,
//       {double size = 18.33, bool disabled = false}) {
//     return Image.asset(
//       'assets/live/main/goods_check_${disabled ? "disable" : selected ? "select" : 'cancel'}.png',
//       width: size,
//       height: size,
//     );
//   }
//
// //  4.28、加载态小组件
//   @override
//   Widget circularProgressIcon(
//     double size, {
//     Color primaryColor = Colors.white,
//     Color? secondaryColor,
//     int lapDuration = 1000,
//     double strokeWidth = 1.67,
//   }) {
//     return SizedBox(
//       height: size,
//       width: size,
//       child: BallCirclePulseLoading(
//         radius: 8.px,
//         ballStyle: BallStyle(size: 4.px),
//       ),
//     );
//   }
//
// //
// // //  5、WS连接状态
// // //  5.1、获取当前ws连接状态
// //   @override
// //   FBWsConnectionStatus get wsConnectionStatus {
// //     return FBWsConnectionStatus.connected;
// //   }
//
// //  5.2、ws连接监听器
// //   ---注册监听---
//   @override
//   void registerWsConnectStatusCallback(FBWsConnectionStatusCallback callback) {}
//
//   // ---移除监听---
//   @override
//   void removeWsConnectStatusCallback() {}
//
//   @override
//   GlobalKey<NavigatorState> get globalNavigatorKey => RouteConfig.navigatorKey;
//
//   @override
//   void liveStatisticsNotice(String guildId, String channelId, int count) {}
//
//   @override
//   Interceptor get loggingInterceptor => LoggingInterceptor();
// }
//
// class MockKeyBord extends StatefulWidget {
//   final ValueChanged<String>? onSubmitted;
//   final TextEditingController? controller;
//
//   const MockKeyBord({
//     this.onSubmitted,
//     this.controller,
//   });
//
//   @override
//   _MockKeyBordState createState() => _MockKeyBordState();
// }
//
// class _MockKeyBordState extends State<MockKeyBord> {
//   FocusNode focusNode = FocusNode();
//
//   bool deactivateState = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     focusNode.addListener(() {
//       if (focusNode.hasFocus) {
//         Future.delayed(const Duration(milliseconds: 100)).then((value) {
//           final double keyHeight = MediaQuery.of(context).viewInsets.bottom;
//           if (mounted && !deactivateState) {
//             EventBusManager.eventBus
//                 .fire(EmojiKeyBoardModel(height: keyHeight + 300));
//           }
//         });
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ClickEvent(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           Container(
//             height: 50,
//             width: FrameSize.winWidth(),
//             color: Colors.white,
//             margin: EdgeInsets.only(bottom: FrameSize.winKeyHeight(context)),
//             child: TextField(
//               focusNode: focusNode,
//               controller: widget.controller,
//               textInputAction: TextInputAction.send,
//               autofocus: true,
//               onSubmitted: (text) {
//                 if (widget.onSubmitted != null) {
//                   widget.onSubmitted!(text);
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//       onTap: () async {
//         RouteUtil.pop();
//       },
//     );
//   }
//
//   @override
//   void deactivate() {
//     deactivateState = true;
//     super.deactivate();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     deactivateState = true;
//   }
// }
