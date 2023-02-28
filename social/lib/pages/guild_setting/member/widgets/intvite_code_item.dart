import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/invite_code.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/realtime_user_info.dart';

class InviteCodeItem extends StatelessWidget {
  final EntityInviteCode model;
  final VoidCallback moreCallback;
  final VoidCallback inviterInfoCallback;
  final VoidCallback detailCallback;

  const InviteCodeItem({
    @required this.model,
    @required this.moreCallback,
    @required this.inviterInfoCallback,
    @required this.detailCallback,
  });

  Widget _deadLineWidget(BuildContext context, int deadLine, int times) {
    String value = '';
    if (deadLine == -1) {
      value += '永久有效，'.tr;
    } else {
      value += '有效期还剩 %s，'.trArgs([formatSecond(deadLine)]);
    }
    if (times == -1) {
      value += '无限次数'.tr;
    } else {
      value += '使用次数还剩%s次'.trArgs([times.toString()]);
    }
    final isExpire = deadLine == 0 || times == 0;
    return Text(
      value,
      style: TextStyle(
          fontSize: 14,
          height: 1.21,
          color: isExpire
              ? Theme.of(context).errorColor
              : Theme.of(context).disabledColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpire = model.expireTime == '0' || model.numberLess == '0';
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '邀请码：%s'.trArgs([model.code.toString()]),
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2
                      .copyWith(fontWeight: FontWeight.bold, height: 1.25),
                ),
                Visibility(
                  visible:
                      model.channelName != null && model.channelName.isNotEmpty,
                  child: Column(
                    children: [
                      sizeHeight6,
                      Text(
                        model.channelType ==
                                ChatChannelType.guildCircleTopic.index
                            ? '圈子 #${model.channelName}'
                            : '# ${model.channelName}',
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.21,
                            color: Theme.of(context).disabledColor),
                      ),
                    ],
                  ),
                ),
                sizeHeight6,
                _deadLineWidget(context, int.parse(model.expireTime ?? '0'),
                    int.parse(model.numberLess ?? '0')),
                if (model.remark != null && model.remark.isNotEmpty) ...[
                  sizeHeight12,
                  Text(
                    '备注: ${model.remark}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyText2
                        .copyWith(color: const Color(0xFF363940), fontSize: 14),
                  ),
                ],
                sizeHeight16,
                Divider(
                  color: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .color
                      .withOpacity(0.2),
                ),
                Container(
                  color: Colors.transparent,
                  height: 44,
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: inviterInfoCallback,
                        child: SizedBox(
                          height: 44,
                          child: Row(
                            children: [
                              RealtimeAvatar(
                                userId: model.inviterId,
                                size: 20,
                                showNftFlag: false,
                              ),
                              sizeWidth8,
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: (model.hasInvited ?? '0') != '0'
                              ? detailCallback
                              : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '%s 已邀请%s位好友'.trArgs([
                                  model.getNickName(),
                                  model.hasInvited.toString()
                                ]),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText2
                                    .copyWith(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 14),
                              ),
                              SizedBox(
                                height: 42,
                                width: 20,
                                child: Visibility(
                                  visible: (model.hasInvited ?? '0') != '0',
                                  child: const MoreIcon(
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: !isExpire,
            child: Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                onPressed: moreCallback,
                iconSize: 20,
                icon: const Icon(IconFont.buffMoreHorizontal),
              ),
            ),
          )
        ],
      ),
    );
  }
}
