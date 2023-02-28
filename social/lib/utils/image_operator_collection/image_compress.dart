//
//  image_compress
//  social
//
//  Created by weiweili on 2021/11/5 .
//  Copyright © social. All rights reserved.
//
// import 'dart:typed_data';

// import 'package:flutter_image_compress/flutter_image_compress.dart';

/// 暂时全部屏蔽，有需要再使用
// class ImageCompress {
//   /// 微信分享最大10M
//   static int maxWechatLength = 10 * 1024 * 1024;
//
//   /// 压缩微信分享海报图片大小
//   static Future<Uint8List> compresssWechatImage(
//     Uint8List data,
//     int imageW,
//     int imageH,
//   ) async {
//     if (data.length < ImageCompress.maxWechatLength) return data;
//     Uint8List result = data;
//     // 压缩比列
//     double quality = 0.8;
//     // 图片宽高比
//     final double scale = imageW / imageH;
//     // 微信最大10M
//     // 每次缩减步长
//     const double step = 0.1;
//     for (int i = 0; i <= 6; i++) {
//       // 压缩到0.2直接退出
//       if (quality <= 0.2) {
//         break;
//       }
//       // 压缩到的宽和高
//       final w = quality * imageW;
//       final h = w / scale;
//       // 执行压缩
//       result = await FlutterImageCompress.compressWithList(
//         data,
//         minHeight: h.toInt(),
//         minWidth: w.toInt(),
//         format: CompressFormat.png,
//       );
//       final length = result.length;
//       if (length < maxWechatLength) {
//         break;
//       } else {
//         quality -= step;
//       }
//     }
//     return result;
//   }
// }
