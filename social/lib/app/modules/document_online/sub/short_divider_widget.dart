import 'package:flutter/cupertino.dart';

class ShortDividerWidget extends StatelessWidget {
  const ShortDividerWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35,
      height: 4,
      decoration: const BoxDecoration(
        color: Color(0xFFE0E2E6),
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
      //    child: Divider(height: 4, thickness: 4, color: Color(0xFFE0E2E6)),
    );
  }
}
