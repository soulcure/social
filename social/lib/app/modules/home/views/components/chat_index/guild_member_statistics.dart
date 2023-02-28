import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/themes/const.dart';

class GuildMemberStatistics extends StatefulWidget {
  final String guildId;
  final TextStyle textStyle;
  final double dotSize;
  final Color dotColor;
  final bool needShadow;
  final bool needDot;

  const GuildMemberStatistics({
    Key key,
    @required this.guildId,
    this.textStyle,
    this.dotSize,
    this.dotColor,
    this.needShadow = false,
    this.needDot = true,
  }) : super(key: key);

  @override
  _GuildMemberStatisticsState createState() => _GuildMemberStatisticsState();
}

class _GuildMemberStatisticsState extends State<GuildMemberStatistics> {
  static final Map<String, RxInt> _guildMemberCountMap = {};

  RxInt _currentMemberCount;

  @override
  void initState() {
    if (widget.guildId == null) return;
    if (_guildMemberCountMap.containsKey(widget.guildId)) {
      _currentMemberCount = _guildMemberCountMap[widget.guildId];
    } else {
      _guildMemberCountMap[widget.guildId] = RxInt(0);
      _currentMemberCount = _guildMemberCountMap[widget.guildId];
    }
    GuildApi.getGuildMemberCount(widget.guildId).then((value) {
      _currentMemberCount.value = value;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentMemberCount == null) return sizedBox;
    final textStyle = widget.textStyle ??
        const TextStyle(
          color: Color(0xFF8F959E),
          fontSize: 14,
        );

    final double size = widget.dotSize ?? 8;
    return ObxValue<RxInt>((currentMemberCount) {
      if (currentMemberCount.value <= 0) return sizedBox;
      return Row(
        children: [
          if (widget.needDot) ...[
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                  boxShadow: [
                    if (widget.needShadow)
                      BoxShadow(
                        color: Colors.black.withOpacity(.3),
                        blurRadius: 1,
                      )
                  ],
                  color: widget.dotColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(size / 2)),
            ),
            sizeWidth5,
          ],
          Text(
            currentMemberCount.value <= 0
                ? ''
                : '%s位成员'.trArgs([currentMemberCount.value.toString()]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle.copyWith(
              shadows: [
                if (widget.needShadow)
                  Shadow(
                    color: Colors.black.withOpacity(.3),
                    blurRadius: 2,
                  )
              ],
            ),
          ),
        ],
      );
    }, _currentMemberCount);
  }
}
