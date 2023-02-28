import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/pages/ledou/widgets/detail_item.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';

class TransactionDetailPage extends StatefulWidget {
  final TransactionDetailViewModel viewModel;

  const TransactionDetailPage(this.viewModel, {Key key}) : super(key: key);

  @override
  _TransactionDetailPageState createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        title: widget.viewModel.title,
      ),
      body: FutureBuilder<TransactionDetailViewModel>(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            /// 加载中
            return _buildLoadingView();
          }
          if (snapshot.hasError) {
            /// 请求失败
            return _buildRetryView();
          }

          /// 请求成功
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// 详情内容
              ..._buildDetailContent(),

              /// 详情列表
              _buildDetailList(),
            ],
          );
        },
      ),
    );
  }

  Future<TransactionDetailViewModel> _fetchData() async {
    final value = await JiGouLiveAPI.tradeDetail(widget.viewModel.tradeId);
    if (value == null) {
      return null;
    }
    final code = value["code"];
    if (code != 200) {
      throw RequestArgumentError(code);
    }

    final data = value["data"];
    widget.viewModel.updateFromJson(data);
    return widget.viewModel;
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildRetryView() {
    return Center(
      child: TextButton(
        onPressed: () => setState(() {}),
        child: Text("网络加载失败，点击重试".tr),
      ),
    );
  }

  List<Widget> _buildDetailContent() {
    const textBlack = Color(0xFF363940);
    return [
      sizeHeight32,
      Text(
        widget.viewModel.content,
        style: const TextStyle(fontSize: 17, color: textBlack),
        textAlign: TextAlign.center,
      ),
      sizeHeight12,
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(color: textBlack),
          children: [
            TextSpan(
              text: widget.viewModel.amount,
              style: const TextStyle(fontSize: 32),
            ),
            const WidgetSpan(child: sizeWidth4),
            TextSpan(
              text: "乐豆".tr,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      const SizedBox(height: 38),
    ];
  }

  /// 构建详情item列表
  Widget _buildDetailList() {
    final data = widget.viewModel.details;
    return Expanded(
      child: ListView.separated(
        separatorBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(left: 16),
          child: divider,
        ),
        itemCount: data.length,
        itemBuilder: (_, i) => DetailItem(data[i]),
      ),
    );
  }
}

class TransactionDetailViewModel {
  /// tradeId
  final String tradeId;

  /// 详情页标题
  String title;

  /// 详情页展示的内容
  String content;

  /// 展示金额，单位：乐豆
  String amount;

  /// 详情列表的item数据集合
  List<DetailItemViewModel> details;

  TransactionDetailViewModel(this.tradeId,
      {this.title = "", this.content = "", this.amount = ""}) {
    details = [];
  }

  String _tradeTypeString(int tradeType) {
    if (tradeType == 1) {
      return "充值".tr;
    } else if (tradeType == 2) {
      return "直播打赏".tr;
    } else if (tradeType == 3) {
      return "直播收入".tr;
    } else {
      return "未知".tr;
    }
  }

  String _contentString(int tradeType, String giftName) {
    if (tradeType == 1) {
      return "充值".tr;
    } else if (tradeType == 2) {
      return "送出-%s".trArgs([giftName]);
    } else if (tradeType == 3) {
      return "收到-%s".trArgs([giftName]);
    } else {
      return "未知".tr;
    }
  }

  String _titleString(int tradeType) {
    if (tradeType == 1) {
      return "充值详情".tr;
    } else if (tradeType == 2) {
      return "消费详情".tr;
    } else if (tradeType == 3) {
      return "收益详情".tr;
    } else {
      return "详情".tr;
    }
  }

  String _amountString(int tradeType, double coin, int giftPrice, int giftQt,
      double platformFee) {
    if (tradeType == 1) {
      return "+$coin";
    } else if (tradeType == 2) {
      return "-$coin";
    } else if (tradeType == 3) {
      return "+${giftPrice * giftQt}";
    } else {
      return coin.toString();
    }
  }

  void updateFromJson(Map json) {
    final bizId = json["bizId"]; // 所属业务单号
    // if(bizId != tradeId) return;

    final anchorNickName = json["anchorNickName"]; //主播昵称
    final tradeType = json["tradeType"]; //类型：1=充值、2=打赏礼物、3=直播收入交易类型
    final coin = double.parse(json["coin"]); //交易的虚拟币数
    final amountRMB = json["amount"]; //本次交易的金额(人民币)
    final createdAt = json["createdAt"]; //交易时间
    final giftName = json["giftName"] ?? ""; //礼物名称
    final giftQt = json["giftQt"] as int; //直播间送礼物数量
    final giftPrice = json["giftPrice"] as int; //礼物单价
    final platformFee = double.parse(json["platformFee"]); //平台抽成
    final roomTitle = json["roomTitle"]; //所属直播间
    final customerNickName = json["customerNickName"]; //客户昵称
    // 暂时未使用的数据
    // final roomLogo = json["roomLogo"]; //直播间封面URL
    // final anchorAvatarUrl = json["anchorAvatarUrl"]; //主播头像
    // final customerAvatarUrl = json["customerAvatarUrl"]; //客户头像

    title = _titleString(tradeType);
    content = _contentString(tradeType, giftName);
    amount = _amountString(tradeType, coin, giftPrice, giftQt, platformFee);

    details.clear();
    details.add(DetailItemViewModel("订单号".tr, bizId));
    details.add(DetailItemViewModel("交易类型".tr, _tradeTypeString(tradeType)));
    if (tradeType == 1) {
      details.add(DetailItemViewModel("金额".tr, "%s元".trArgs([amountRMB.toString()])));
    }

    if (tradeType == 2 || tradeType == 3) {
      details.add(DetailItemViewModel("礼物名称".tr, giftName));
      details.add(DetailItemViewModel("单价".tr, "%s乐豆".trArgs([giftPrice.toString()])));
      details.add(DetailItemViewModel("数量".tr, giftQt.toString()));
    }

    if (tradeType == 3) {
      details.add(DetailItemViewModel(
          "分成比例".tr, "${(platformFee * 100).toStringAsFixed(0)}%"));
    }

    if (tradeType == 2 || tradeType == 3) {
      details.add(DetailItemViewModel("所在直播间".tr, roomTitle, maxLine: 2));
    }
    if (tradeType == 2) {
      details.add(DetailItemViewModel("主播昵称".tr, anchorNickName, maxLine: 2));
    }
    if (tradeType == 3) {
      details.add(DetailItemViewModel("用户昵称".tr, customerNickName, maxLine: 2));
    }
    details.add(DetailItemViewModel("交易时间".tr, createdAt));
  }
}
