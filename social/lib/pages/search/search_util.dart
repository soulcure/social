import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/themes/const.dart';
import 'package:websafe_svg/websafe_svg.dart';

/// 搜索工具类
class SearchUtil {
  /// 构建搜索中的界面
  static Widget buildSearchingView({Color bgColor}) {
    return Container(
      alignment: Alignment.center,
      color: bgColor ?? Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          sizeWidth16,
          Text(
            "搜索中...".tr,
            style: const TextStyle(fontSize: 14, color: Color(0xFF8F959E)),
          ),
        ],
      ),
    );
  }

  /// 构建搜索失败重试的界面
  static Widget buildRetryView(Function retry, {Color bgColor}) {
    return Container(
      alignment: Alignment.center,
      color: bgColor ?? Colors.white,
      child: TextButton(
        onPressed: () {
          retry();
        },
        child: Text("搜索失败，点击重试".tr),
      ),
    );
  }

  /// 当输入的关键字为单个字符且属于此集合，则不触发搜索
  /// 此集合中涵盖了url中的字符跟文本消息特殊字符，防止输入单个字符搜索出大量用户不关心的信息
  static final filterChars = [
    '(',
    ')',
    '/',
    ':',
    '?',
    '&',
    '=',
    '@',
    '!',
    '{',
    '}',
    '#',
    r'$',
    '[',
    ']'
  ];

  /// 按照如下规则，过滤输入的关键字
  /// 1. 去除头尾的空格
  /// 2. 当输入（去除头尾空格后）单个字符，且属于filterChars, 则不发起搜索
  /// 3. 当输入（去除头尾空格后）两个或两个以上的字符，直接发起搜索，不进行过滤
  static bool filterInput(String key) {
    if (key == null) return false;

    /// 去除关键字头尾的空格
    key = key.trim();

    /// 输入单个字符，且属于url特殊字符，直接过滤
    if (key.length == 1 && filterChars.contains(key)) {
      return false;
    }

    /// 其他情况下不过滤
    return true;
  }
}

///搜索类型：网络服务端，本地
enum SearchType { network, local }

///搜索请求状态
enum SearchStatus { normal, searching, success, fail }

///搜索空状态页面
class SearchNullView extends StatelessWidget {
  final String svgName;
  final double size;
  final String text;
  final double textSize;
  final Color textColor;
  final FontWeight fontWeight;

  const SearchNullView({
    @required this.svgName,
    @required this.text,
    this.size = 140,
    this.textSize,
    this.textColor,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(children: [
        Positioned(
          top: 91,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: WebsafeSvg.asset(svgName),
              ),
              const SizedBox(
                height: 18,
              ),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: textColor ?? const Color(0xFF363940),
                    fontSize: textSize ?? 17,
                    fontWeight: fontWeight ?? FontWeight.bold),
              ),
            ],
          ),
        )
      ]),
    );
  }
}
