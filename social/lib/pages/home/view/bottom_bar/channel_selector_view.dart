import 'package:flutter/material.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_prompt/channel_selector_model.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/mouse_hover_builder.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:provider/provider.dart';

class ChannelSelectorView extends StatefulWidget {
  @override
  _ChannelSelectorViewState createState() => _ChannelSelectorViewState();
}

class _ChannelSelectorViewState extends State<ChannelSelectorView> {
  final Map<int, ChatChannel> _categoryMap = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChannelSelectorModel>(
      builder: (_, model, child) {
        if (!model.visible) return const SizedBox();
        ChatChannel category;
        for (int i = 0; i < model.list.length; i++) {
          if (model.list[i].type == ChatChannelType.guildCategory) {
            category = model.list[i];
          }
          _categoryMap[i] = category;
        }
        return Container(
          alignment: Alignment.bottomCenter,
          padding: OrientationUtil.landscape
              ? const EdgeInsets.fromLTRB(24, 0, 24, 8)
              : const EdgeInsets.all(0),
          child: Container(
            height: OrientationUtil.landscape ? 300 : double.infinity,
            decoration: BoxDecoration(
                color: OrientationUtil.portrait
                    ? Theme.of(context).scaffoldBackgroundColor
                    : Theme.of(context).backgroundColor,
                borderRadius: OrientationUtil.portrait
                    ? BorderRadius.circular(0)
                    : BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                      blurRadius: 26,
                      spreadRadius: 7,
                      offset: Offset(0, 7),
                      color: Color(0x1F717D8D))
                ]),
            child: Scrollbar(
              child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: model.list.length,
                  itemBuilder: (_, index) {
                    final channel = model.list[index];
                    if (channel.type == ChatChannelType.guildCategory) {
                      category = channel;
                      return const SizedBox();
                    }
                    return MouseHoverBuilder(
                      builder: (context, isSelected) => FadeButton(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        onTap: () {
                          model.insertChannelBlock(channel);
                        },
                        backgroundColor: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).backgroundColor,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                                child: RealtimeChannelName(
                              channel.id,
                              prefix: "# ",
                              style: OrientationUtil.portrait
                                  ? null
                                  : TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white
                                          : Theme.of(context)
                                              .textTheme
                                              .bodyText2
                                              .color),
                            )),
                            if (_categoryMap[index] != null) ...[
                              const SizedBox(width: 16),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxWidth:
                                        (MediaQuery.of(context).size.width -
                                                32) /
                                            2),
                                child: Text(_categoryMap[index].name,
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyText1
                                        .copyWith(
                                            fontSize: 12,
                                            color: isSelected
                                                ? Colors.white
                                                : Theme.of(context)
                                                    .textTheme
                                                    .bodyText2
                                                    .color)),
                              )
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
            ),
          ),
        );
      },
    );
  }
}
