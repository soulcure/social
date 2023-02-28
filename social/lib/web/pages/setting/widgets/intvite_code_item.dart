import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/invite_code.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/mouse_hover_builder.dart';

class InviteCodeItemWeb extends StatelessWidget {
  final EntityInviteCode model;
  final void Function(BuildContext) moreCallback;
  final void Function(BuildContext) inviterInfoCallback;
  final VoidCallback detailCallback;

  const InviteCodeItemWeb({
    @required this.model,
    @required this.moreCallback,
    @required this.inviterInfoCallback,
    @required this.detailCallback,
  });

  Widget _timesWidget(BuildContext context, int deadLine, int times) {
    String value = '';
    if (times == -1) {
      value = '无限次数'.tr;
    } else {
      value = '%s次'.trArgs([times.toString()]);
    }
    final _theme = Theme.of(context);
    final isExpire = deadLine == 0 || times == 0;
    return Text(
      value,
      style: TextStyle(
          fontSize: 14,
          height: 1,
          color: isExpire
              ? _theme.errorColor
              : Theme.of(context).textTheme.bodyText1.color),
    );
  }

  Widget _dateWidget(BuildContext context, int deadLine, int times) {
    String value = '';
    if (deadLine == -1) {
      value = '永久'.tr;
    } else {
      value = formatSecond(deadLine);
    }
    final _theme = Theme.of(context);
    final isExpire = deadLine == 0 || times == 0;
    return Text(
      value,
      style: TextStyle(
          fontSize: 14,
          height: 1,
          color: isExpire
              ? _theme.errorColor
              : Theme.of(context).textTheme.bodyText1.color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpire = model.expireTime == '0' || model.numberLess == '0';
    final hasInvited = model.hasInvited ?? '0';
    return MouseHoverBuilder(
      builder: (_, hover) {
        return Stack(
          children: [
            Container(
              height: 72,
              decoration: BoxDecoration(
                  color: hover ? const Color(0x7FDEE0E3) : null,
                  borderRadius: BorderRadius.circular(4)),
              child: Row(
                children: [
                  sizeWidth16,
                  Container(
                    width: 206,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Builder(
                          builder: (context) {
                            return GestureDetector(
                              onTap: () => inviterInfoCallback(context),
                              child: Avatar(
                                url: model.avatar,
                                radius: 20,
                              ),
                            );
                          },
                        ),
                        sizeWidth10,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              model.getNickName(),
                              style: Theme.of(context).textTheme.bodyText2,
                            ),
                            Visibility(
                              visible: model.channelName != null &&
                                  model.channelName.isNotEmpty,
                              child: Column(
                                children: [
                                  sizeHeight6,
                                  Text(
                                    '# ${model.channelName}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyText1
                                        .copyWith(height: 1, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  Container(
                    width: 94,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      model.code,
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ),
                  Container(
                    width: 76,
                    alignment: Alignment.centerRight,
                    child: _timesWidget(
                        context,
                        int.parse(model.expireTime ?? '0'),
                        int.parse(model.numberLess ?? '0')),
                  ),
                  Container(
                    width: 80,
                    alignment: Alignment.centerRight,
                    child: _dateWidget(
                        context,
                        int.parse(model.expireTime ?? '0'),
                        int.parse(model.numberLess ?? '0')),
                  ),
                  MouseRegion(
                    cursor: hasInvited == '0'
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: hasInvited == '0' ? null : detailCallback,
                      child: Container(
                          width: 80,
                          alignment: Alignment.centerRight,
                          child: Text(
                            hasInvited,
                            style: hasInvited == '0'
                                ? Theme.of(context).textTheme.bodyText1
                                : Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    .copyWith(
                                        color: Theme.of(context).primaryColor),
                          )),
                    ),
                  ),
                  Container(
                    width: 112,
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        model?.remark ?? '',
                        textAlign: TextAlign.right,
                        style: Theme.of(context)
                            .textTheme
                            .bodyText2
                            .copyWith(color: Theme.of(context).disabledColor),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: !isExpire,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Builder(builder: (context) {
                        return IconButton(
                          onPressed: () => moreCallback(context),
                          iconSize: 20,
                          icon: const Icon(IconFont.buffMoreHorizontal),
                        );
                      }),
                    ),
                  )
                ],
              ),
            ),
            const Positioned(
              bottom: 0,
              right: 50,
              left: 16,
              child: divider,
            )
          ],
        );
      },
    );
  }
}
