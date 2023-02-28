import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:im/pages/home/json/add_friend_tips_entity.dart';

class AddFriendTipsItem extends StatelessWidget {
  final AddFriendTipsEntity entity;

  const AddFriendTipsItem({Key key, this.entity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return dmStartWidget(context);
  }

  Widget dmStartWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Text(entity.toNotificationString(),
          style: TextStyle(color: Theme.of(context).disabledColor)),
    );
  }
}
