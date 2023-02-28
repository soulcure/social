/*
 * @FilePath       : /social/lib/app/modules/redpack/open_pack/models/open_redpack_params_model.dart
 * 
 * @Info           : 领红包入参数据模型
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-01-05 16:30:32
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-01-10 12:17:12
 * 
 */

import 'package:flutter/material.dart';
import 'package:im/app/modules/redpack/open_pack/models/open_redpack_detail_model.dart';

class OpenRedPackParamsModel {
  /// 红包状态 
  /// - @see [RedPackStatus]
  int status;

  /// 红包详情
  OpenRedPackDetailModel detail;

  OpenRedPackParamsModel({
    @required this.status,
    @required this.detail,
  });
}
