import 'package:flutter/material.dart';

class AppInfo {
  final String avatarUrl;
  final String appName;
  final Map desc;
  final String userInfoDesc;
  final String userLinkDesc;

  AppInfo({
    @required this.avatarUrl,
    @required this.appName,
    this.desc,
    this.userInfoDesc,
    this.userLinkDesc,
  });
}
