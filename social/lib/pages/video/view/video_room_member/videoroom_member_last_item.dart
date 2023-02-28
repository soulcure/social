import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';

class VideoroomMemberLastItem extends StatefulWidget {
  const VideoroomMemberLastItem({Key key}) : super(key: key);

  @override
  State<VideoroomMemberLastItem> createState() =>
      _VideoroomMemberLastItemState();
}

class _VideoroomMemberLastItemState extends State<VideoroomMemberLastItem> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 56,
          color: Colors.white,
          child: Row(
            children: [
              sizeWidth16,
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8F959E).withOpacity(0.15)),
                child: const Icon(
                  IconFont.buffInviteUser,
                  color: Color(0xFF646A73),
                  size: 18,
                ),
              ),
              sizeWidth16,
              Expanded(
                  child: Text(
                "邀请朋友".tr,
                style: const TextStyle(
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF363940)),
              )),
              sizeWidth16,
            ],
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(left: 64),
          child: Divider(
            height: 0.5,
            color: const Color(0xFF8F959E).withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}
