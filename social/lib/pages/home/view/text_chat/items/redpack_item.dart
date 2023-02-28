import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/redpack/open_pack/models/open_redpack_detail_model.dart';
import 'package:im/app/modules/redpack/open_pack/views/open_redpack_dialog.dart';
import 'package:im/app/modules/redpack/redpack_item/redpack_info_ben.dart';
import 'package:im/app/modules/redpack/redpack_item/redpack_item_bean.dart';
import 'package:im/app/modules/redpack/redpack_item/redpack_util.dart';
import 'package:im/app/theme/app_colors.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/json/redpack_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/services/server_side_configuration.dart';
import 'package:im/ws/ws.dart';

///拆红包dialog入参，返回int结果
class RedPackParams {
  final String guildId;
  final String channelId;
  final String messageId;
  final String redPackId;
  final String userId;

  const RedPackParams({
    @required this.guildId,
    @required this.channelId,
    @required this.messageId,
    @required this.redPackId,
    @required this.userId,
  });
}

class RedPackItem extends StatelessWidget {
  final RedPackEntity entity;
  final MessageEntity message;

  const RedPackItem({Key key, this.entity, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeButton(
      width: 160,
      height: 240,
      onTap: () {
        FocusScope.of(context).unfocus();
        openRedPack(context);
      },
      child: _buildRedPack(),
    );
  }

  Future<void> openRedPack(BuildContext context) async {
    final String guildId = message.guildId;
    final String channelId = message.channelId;
    final String messageId = message.messageId;
    final String redPackId = entity.id;
    final String userId = message.userId;

    //  获取当前红包状态
    final int status = RedPackUtil().openRedPackStatus(channelId, redPackId);
    //  红包总金额
    final String amount = entity.money.toStringAsFixed(2);
    //  获取用户信息补充头像和昵称
    final UserInfo userInfo = await UserInfo.get(userId);
    //  执行领取红包
    await OpenRedPackDialog.open(status,
        context: context,
        detail: OpenRedPackDetailModel(
          messageEntity: message,
          guildId: guildId,
          channelId: channelId,
          messageId: messageId,
          redPackId: redPackId,
          type: entity.redPackType,
          userId: userId,
          userHeader: userInfo.avatar,
          userName: userInfo.showName(guildId: guildId),
          isOwner: Global.user.id == userId,
          remark: entity.redPackGreetings,
          amount: amount,
        ));
  }

  Widget _buildRedPack() {
    return ValueListenableBuilder<Box<RedPackItemBean>>(
      valueListenable: RedPackUtil().redPackValueListenable(message.channelId),
      builder: (c, box, child) {
        //红包状态   0 未开封， 1超时未领取， 2红包领完， 3成功领取，4 红包未领取（只针对私信单发状态）
        int status = RedPackUtil()
            .getRedPackStatus(box, message.channelId, message.messageId);

        if (status != RedPackStatus.expiredRedPack && _checkIsExpired()) {
          status = RedPackStatus.expiredRedPack;

          RedPackUtil().putRedPack(message.channelId, message.messageId,
              entity.id, RedPackStatus.expiredRedPack, '0.00');
        }

        //1 群拼手气红吧 ,2群普通红包，3私信红包
        final int redType = entity.redPackType;
        return Opacity(
          opacity: status == RedPackStatus.newRedPack ? 1 : 0.6,
          child: Container(
            width: 160,
            height: 240,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              //装饰图片/背景图片
              image: DecorationImage(
                image: AssetImage('assets/images/red_pack_item.png'),
                fit: BoxFit.cover, //图片填充方式
                alignment: Alignment.topCenter, //图片位置
                repeat: ImageRepeat.repeatY, //图片平铺方式
              ),
              borderRadius: BorderRadius.all(Radius.circular(7)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _redPackStatus(status, redType),
                _redPackButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _redPackStatus(int status, int redType) {
    final List<Widget> res = [
      const SizedBox(height: 36),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          entity.redPackGreetings ?? "恭喜发财，万事如意".tr,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: goldColor, fontWeight: FontWeight.w500, fontSize: 14),
        ),
      )
    ];
    switch (status) {
      //红包已过期
      case RedPackStatus.expiredRedPack:
        res.addAll([
          const SizedBox(height: 10),
          Text(
            '红包已过期'.tr,
            style: const TextStyle(color: goldColor, fontSize: 12),
          ),
        ]);
        break;
      //红包已领完
      case RedPackStatus.noneLeftRedPack:
        res.addAll([
          const SizedBox(height: 10),
          Text(
            '红包已领完'.tr,
            style: const TextStyle(color: goldColor, fontSize: 12),
          ),
        ]);
        break;
      //红包已领取
      case RedPackStatus.GrabbedRedPack:
        res.addAll([
          const SizedBox(height: 10),
          Text(
            '红包已领取'.tr,
            style: const TextStyle(color: goldColor, fontSize: 12),
          ),
        ]);
        break;
      default:
        break;
    }
    res.addAll(_redPackStatusText(redType));

    return Column(
      children: res,
    );
  }

  List<Widget> _redPackStatusText(int redType) {
    final List<Widget> list = [];
    Widget redPackWidgetType;
    //1 群拼手气红包 ,2群普通红包，3私信红包
    switch (redType) {
      case 1:
        redPackWidgetType = Text(
          '拼手气红包'.tr,
          style: const TextStyle(color: goldColor, fontSize: 12),
        );
        break;
      case 2:
      case 3:
        redPackWidgetType = Text(
          '普通红包'.tr,
          style: const TextStyle(color: goldColor, fontSize: 12),
        );
        break;
      default:
        redPackWidgetType = const SizedBox();
        break;
    }

    list.addAll([
      const Spacer(),
      Opacity(
        opacity: 0.75,
        child: redPackWidgetType,
      ),
      const SizedBox(height: 10),
    ]);
    return list;
  }

  Widget _redPackButton() {
    return Positioned(
      left: 56,
      top: 149,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: goldColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            IconFont.buffIconOpen,
            size: 24,
            color: redDeepTextColor,
          ),
        ),
      ),
    );
  }

  ///true表示红包已经过期
  bool _checkIsExpired() {
    final int configTime = ServerSideConfiguration.to.period;

    final DateTime sendTime = message.time;

    DateTime nowTime;
    if (Ws.serverTime < 0) {
      //此时未收到ws pong消息，只能暂时使用手机当前时间
      nowTime = DateTime.now();
    } else {
      //此时已经有了服务器时间,服务器时间可能是30秒前的数据
      final int serverTime = Ws.serverTime + 30;
      nowTime = DateTime.fromMillisecondsSinceEpoch(serverTime * 1000);
    }

    if (nowTime.difference(sendTime).inSeconds > configTime) {
      //超出服务器配置的过期时间
      return true;
    }
    return false;
  }
}
