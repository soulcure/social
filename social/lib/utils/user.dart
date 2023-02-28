import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/circle_icon.dart';

String getOnlineStatusText(PresenceStatus status) {
  switch (status) {
    case PresenceStatus.offline:
      return '隐身'.tr;
      break;
    case PresenceStatus.online:
      return '在线'.tr;
      break;
    case PresenceStatus.free:
      return '闲置'.tr;
      break;
    case PresenceStatus.notDisturb:
      return '请勿打扰'.tr;
      break;
    default:
      return '离线'.tr;
  }
}

Widget getOnlineStatusIcon(
  BuildContext context,
  PresenceStatus status, {
  double radius = 6,
}) {
  switch (status) {
    case PresenceStatus.offline:
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: Theme.of(context).iconTheme.color, width: 2)),
      );
      break;
    case PresenceStatus.online:
      return Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor,
          ));
      break;
    case PresenceStatus.free:
      return Icon(
        IconFont.buffOtherFree,
        size: radius * 2,
        color: const Color(0xFFF3B22F),
      );
      break;
    case PresenceStatus.notDisturb:
      return Icon(
        IconFont.buffOtherBusy,
        size: radius * 2,
        color: const Color(0xFFF2494A),
      );
      break;
    default:
      return const SizedBox();
  }
}

Widget getGenderIcon(int gender,
    {double radius = 10, double size = 10, bool square = false}) {
  if (gender == 1 || gender == 2) {
    if (!square)
      return CircleIcon(
        icon: gender == 1 ? IconFont.buffTabMale : IconFont.buffTabFemale,
        color: Colors.white,
        size: size,
        radius: radius,
        backgroundColor:
            gender == 1 ? appThemeData.primaryColor : const Color(0xFFE900FE),
      );
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color:
            gender == 1 ? appThemeData.primaryColor : const Color(0xFFE900FE),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        gender == 1 ? IconFont.buffTabMale : IconFont.buffTabFemale,
        color: Colors.white,
        size: size,
      ),
    );
  }
  return const SizedBox();
}
