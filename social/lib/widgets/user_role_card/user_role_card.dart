import 'package:flutter/material.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/credits_bean.dart';
import 'package:im/api/entity/user_role_card_bean.dart';
import 'package:im/api/relation_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

import '../user_info/popup/user_info_popup.dart';

class UserRoleCard extends StatefulWidget {
  final UserInfo user;
  final EnterType enterType;
  final String guildId;
  final String channelId;

  const UserRoleCard(
      {Key key,
      @required this.user,
      this.enterType = EnterType.fromDefault,
      this.guildId,
      this.channelId})
      : super(key: key);

  @override
  _UserRoleCardState createState() => _UserRoleCardState();
}

class _UserRoleCardState extends State<UserRoleCard> {
  String get key => '${widget.user.userId}-$guildId';
  // 如果 widget.guildId == '0' 那就代表是部落。
  String get guildId =>
      widget.guildId == '0' ? widget.channelId : widget.guildId;
  // 这里是内存缓存，多卡槽数据经讨论无需存储到本地。
  static final Map<String, CreditsBean> _cache = {};
  CreditsBean _bean;

  Future updateInfo() async {
    if (guildId.noValue) return;
    final userId = widget.user.userId;
    // 先取内存中的数据
    _bean = _cache[key];
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 350)); // 避免在弹出来的瞬间加载出来
    final List res = await RelationApi.getCredits(
        widget.guildId,
        [
          {"user_id": userId}
        ],
        onlyTitle: false,
        channelId: widget.guildId == '0' ? widget.channelId : null,
        channelType:
            widget.guildId == '0' ? ChatChannelType.group_dm.index : null);
    final beanList = res.map((e) => CreditsBean.fromJson(e)).toList();
    if (mounted && beanList != null && beanList.isNotEmpty) {
      _bean = beanList.first;
      await _bean.saveToBox(guildId); // 缓存徽章到本地, 其余数据没缓存
      _cache[key] = beanList.first;
      setState(() {});
      SheetController.of(context)?.rebuild();
      // unawaited();
    }
  }

  @override
  void initState() {
    updateInfo();
    super.initState();
  }

  bool get hideCard {
    return widget.enterType == EnterType.fromDefault || GlobalState.isDmChannel;
  }

  Widget _item(GuildCardBean bean) {
    if (bean == null) return sizedBox;
    final slots = bean.slots;
    final authority = bean.authority;
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8), color: Colors.white),
      padding: const EdgeInsets.only(bottom: 12),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffE0E2E6),
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image:
                          CachedProviderBuilder(authority?.icon ?? '').provider,
                      fit: BoxFit.cover,
                    ),
                  ),
                  width: 32,
                  height: 32,
                ),
                sizeWidth12,
                Expanded(
                    child: Text(
                  authority?.name ?? '',
                  style: const TextStyle(
                      color: Color(0xff1F2125),
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                )),
              ],
            ),
          ),
          ...List.generate(slots.length, (index) {
            final slotList = slots[index];
            final isFirst = index == 0;
            final l = slotList.length;
            final isLast = index == -1;
            final hasImage = slotList
                    .where((e) => e.img != null && e.img.isNotEmpty)
                    ?.toList()
                    ?.isNotEmpty ??
                false;
            if (hasImage)
              return Column(
                children: [
                  sizeHeight5,
                  Container(
                    color: const Color(0xffF2F3F5),
                    height: 0.5,
                    margin: const EdgeInsets.only(left: 16, right: 16),
                  ),
                  sizeHeight12,
                  Row(
                    children: List.generate(l, (index) {
                      return Expanded(
                          child: Center(
                              child: buildTextWithImage(slotList[index])));
                    }),
                  ),
                ],
              );
            return Padding(
              padding:
                  EdgeInsets.only(bottom: isLast ? 0 : 6, top: isFirst ? 9 : 0),
              child: rowSlotWidget(slotList),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (hideCard) return sizedBox;
    final beans = _bean?.cardBeans ?? [];
    if (beans.isEmpty) return sizedBox;
    return Column(
      children: beans.map(_item).toList(),
    );
  }

  Widget oneSlotWidget(SlotsBean curSlot) {
    if (curSlot == null) return sizedBox;
    final hasImage = curSlot.img != null && curSlot.img.isNotEmpty;
    return hasImage
        ? buildTextWithImage(curSlot)
        : buildTextWithoutImage(curSlot);
  }

  Widget rowSlotWidget(List<SlotsBean> slots) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(slots.length, (index) {
        final cur = slots[index];
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            child: buildTextWithoutImage(cur),
          ),
        );
      }),
    );
  }

  Widget buildTextWithoutImage(SlotsBean curSlot) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${curSlot.label}：',
          style: const TextStyle(color: Color(0xff8F959E), fontSize: 14),
        ),
        Expanded(
            child: Text(
          curSlot.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xff1F2125), fontSize: 14),
        )),
      ],
    );
  }

  Widget buildTextWithImage(SlotsBean curSlot) {
    final url = curSlot.img ?? '';
    final showText = curSlot.label ?? curSlot.value ?? '';
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: CachedProviderBuilder(url).provider,
              fit: BoxFit.cover,
            ),
          ),
          width: 40,
          height: 40,
        ),
        sizeHeight6,
        Text(
          showText,
          style: const TextStyle(color: Color(0xff1F2125), fontSize: 12),
        ),
      ],
    );
  }
}
