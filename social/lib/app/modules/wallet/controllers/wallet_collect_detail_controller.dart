/*
 * @FilePath       : /social/lib/app/modules/wallet/controllers/wallet_collect_detail_controller.dart
 * 
 * @Info           : 业务逻辑：钱包 - 藏品详情
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-04-07 17:36:12
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-04-21 15:20:38
 * 
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/modules/wallet/models/wallet_collect_model.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';

class WalletCollectDetailController extends GetxController {
  /// - 藏品信息
  final WalletCollectModel collect;

  /// - Get - 是否是自己的收藏
  bool get isOwn => collect.collectorId == Global.user.id;

  /// - Get - 是否可以设置nft头像
  bool get isCanSetNftAvatar => Global.user.avatarNftId != collect.nftId;

  WalletCollectDetailController(this.collect);

  @override
  void onInit() {
    super.onInit();
    update();
  }

  /// 修改用户头像
  Future changeUserAvatar(BuildContext context) async {
    //  获取缓存用户信息
    final LocalUser user = Global.user;
    Loading.show(context);
    //  接口调用后isCanSetNftAvatar的值会变，所以这里赋值给局部变量
    final bool isCanSetNft = isCanSetNftAvatar;
    //  更新服务器用户信息
    final res = await UserApi.updateUserInfo(
            user.id, user.nickname, user.avatar, user.gender,
            avatarNftId: isCanSetNft ? collect.nftId : "")
        .onError((error, stackTrace) {
      return false;
    });
    //  成功会返回null,不能修改接口否则影响的地方太多，只能在onError的时候返回可操作的值判断是否不执行
    if (res == false) {
      Loading.hide();
      return;
    }
    //  根据判断是否需要设置nft头像
    final String newAvatarNft = isCanSetNft ? collect.displayUrl : "";
    final String newAvatarNftId = isCanSetNft ? collect.nftId : "";
    //  更新本地数据库用户信息
    final userInfoBox = Db.userInfoBox.get(user.id);
    userInfoBox.avatarNft = newAvatarNft;
    userInfoBox.avatarNftId = newAvatarNftId;
    UserInfo.set(userInfoBox);
    //  更新缓存用户信息
    await Global.user.update(
      avatarNft: newAvatarNft,
      avatarNftId: newAvatarNftId,
    );
    Loading.hide();
    update();
  }
}
