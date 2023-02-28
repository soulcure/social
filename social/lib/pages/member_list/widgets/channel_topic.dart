import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/widgets/realtime_user_info.dart';

class ChannelTopic extends StatefulWidget {
  final ChatChannel channel;

  const ChannelTopic(this.channel);

  @override
  _ChannelTopicState createState() => _ChannelTopicState();
}

class _ChannelTopicState extends State<ChannelTopic>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RealtimeChannelInfo(
      widget.channel.id,
      builder: (_, channel) {
        final style =
            Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14);
        return (channel?.topic == null || channel?.topic?.isEmpty == true)
            ? const SizedBox()
            : Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: FadeButton(
                  alignment: Alignment.centerLeft,
                  onTap: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    firstChild: Text(
                      channel.topic,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    ),
                    secondChild: Text(
                      channel.topic,
                      maxLines: 100,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    ),
                    crossFadeState: !_expanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                  ),
                ),
              );
      },
    );
  }
}
