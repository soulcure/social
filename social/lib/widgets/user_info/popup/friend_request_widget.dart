import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/pages/friend/relation.dart';
import 'package:im/pages/friend/widgets/relation_utils.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/loading_action.dart';
import 'package:im/widgets/user_info/popup/view_model.dart';

// 好友通过与否组件
class FriendRequestWidget extends StatefulWidget {
  final UserInfo user;
  const FriendRequestWidget({Key key, this.user}) : super(key: key);

  @override
  _FriendRequestWidgetState createState() => _FriendRequestWidgetState();
}

class _FriendRequestWidgetState extends State<FriendRequestWidget> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserInfoViewModel>(
        tag: widget.user.userId,
        builder: (controller) {
          return RelationUtils.consumer(widget.user.userId,
              builder: (context, relation, widget) {
            return Visibility(
              visible: relation == RelationType.pendingIncoming,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '收到好友请求'.tr,
                    style:
                        appThemeData.textTheme.bodyText1.copyWith(fontSize: 13),
                  ),
                  sizeHeight10,
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ObxValue<RxBool>((loading) {
                          return LoadingAction(
                            height: 36,
                            color: appThemeData.primaryColor,
                            borderRadius: 8,
                            loading: loading.value,
                            onTap: controller.agreeApply,
                            child: Text(
                              '通过'.tr,
                              style: appThemeData.textTheme.bodyText2
                                  .copyWith(color: Colors.white),
                            ),
                          );
                        }, controller.agreeLoading),
                      ),
                      sizeWidth16,
                      Expanded(
                        child: ObxValue<RxBool>((loading) {
                          return LoadingAction(
                            height: 36,
                            // 以前的UI色值，appThemeData里面没有，需要找UI对一下
                            color: const Color(0xff737780).withOpacity(0.2),
                            borderRadius: 8,
                            loading: loading.value,
                            onTap: controller.agreeRefuse,
                            child: Text(
                              '忽略'.tr,
                              style: appThemeData.textTheme.bodyText2,
                            ),
                          );
                        }, controller.refuseLoading),
                      ),
                    ],
                  ),
                  sizeHeight24
                ],
              ),
            );
          });
        });
  }
}
