import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/pages/home/model/reaction_model.dart';
import 'package:im/pages/home/view/text_chat/items/components/message_reaction.dart';
import 'package:im/pages/home/view/text_chat/items/components/reaction_user_list.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/emo_util.dart';
import 'package:rxdart/subjects.dart';

class ReactionCountChange {
  final String name;
  final int count;
  bool me;

  ReactionCountChange(this.name, this.count, this.me);
}

class ReactionDetail extends StatefulWidget {
  final ReactionModel model;
  final ReactionEntity initReaction;

  const ReactionDetail(this.model, this.initReaction, {Key key})
      : super(key: key);

  @override
  _ReactionDetailState createState() => _ReactionDetailState();
}

class _ReactionDetailState extends State<ReactionDetail>
    with TickerProviderStateMixin {
  TabController _controller;
  int _initialIndex;
  final subject = PublishSubject<ReactionCountChange>();

  @override
  void initState() {
    subject.stream.listen((data) {
      widget.model.update(data);
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    subject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ObxValue<Rx<ReactionModel>>(
      (model) {
        return buildContentDefault(model.value.reactions);
      },
      widget.model.updater,
    );
  }

  Widget buildContentDefault(List<ReactionEntity> list) {
    if (_controller != null) _controller.dispose();

    _initialIndex = list.indexWhere((v) => v.name == widget.initReaction.name);
    _controller = TabController(
      initialIndex: _initialIndex == -1 ? 0 : _initialIndex,
      length: list.length,
      vsync: this,
    );

    final List<Tab> tabs = getTabs(list);

    final List<Widget> tabViews = getTabViews(list);

    return Container(
      color: Theme.of(context).backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            alignment: Alignment.centerLeft,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('详情'.tr, style: Theme.of(context).textTheme.bodyText1),
          ),
          divider,
          // ignore: sized_box_for_whitespace
          Container(
            height: Get.height * 0.35,
            child: TabBarView(controller: _controller, children: tabViews),
          ),
          Container(
            height: 56,
            padding: const EdgeInsets.all(12),
            child: TabBar(
              controller: _controller,
              isScrollable: true,
              indicatorColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3C3F46)
                    : Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              tabs: tabs,
            ),
          ),
        ],
      ),
    );
  }

  List<ReactionUserList> getTabViews(List<ReactionEntity> list) {
    return list
        .map((e) => ReactionUserList(widget.model.channelId,
            widget.model.messageId, e.name, e.count, e.me, subject,
            isCircleMessage: widget.model.isCircleMessage))
        .toList();
  }

  List<Tab> getTabs(List<ReactionEntity> list) {
    return list
        .map((v) => Tab(
                child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  EmoUtil.instance.getEmoIcon(v.name, size: 18),
                  sizeWidth5,
                  Text(
                    v.count.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(fontSize: 15),
                  ),
                ],
              ),
            )))
        .toList();
  }
}
