import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/themes/const.dart';
import 'package:im/web/widgets/button/web_bg_icon_button.dart';

class WebFormTabView extends StatefulWidget {
  final String title;
  final String desc; // 描述
  final Widget child;
  WebFormTabView({
    int index,
    @required this.title,
    @required this.child,
    this.desc,
  }) : super(key: ValueKey(index));
  @override
  _WebFormTabViewState createState() => _WebFormTabViewState();
}

class _WebFormTabViewState extends State<WebFormTabView> {
  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 94),
          _buildTitle(),
          if (widget.desc == null)
            const SizedBox(height: 32)
          else
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                widget.desc,
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ),
          Expanded(
            child: widget.child,
          )
        ],
      ),
    );

    return child;
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Text(
          widget.title ?? '',
          style: Theme.of(context)
              .textTheme
              .bodyText2
              .copyWith(fontWeight: FontWeight.w500, fontSize: 20),
        ),
        spacer,
        WebBgIconButton(
          icon: Icons.close,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          size: 18,
          validForm: true,
          onTap: Get.back,
        )
      ],
    );
  }
}
