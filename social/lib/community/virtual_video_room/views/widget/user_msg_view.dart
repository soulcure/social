import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:im/themes/const.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../svg_icons.dart';

class UserMsgView extends StatelessWidget {
  final String userName;
  final bool isLoading;
  final bool isMute;

  const UserMsgView(
      {Key key, this.userName, this.isLoading = true, this.isMute = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2126).withOpacity(0.75),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading) const CupertinoActivityIndicator(radius: 6),
          if (isMute)
            WebsafeSvg.asset(SvgIcons.virtualCloseMic, width: 12, height: 12),
          sizeWidth2,
          Flexible(
            child: Text(
              userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFDADBE6), fontSize: 11),
            ),
          ),
          sizeWidth4,
        ],
      ),
    );
  }
}
