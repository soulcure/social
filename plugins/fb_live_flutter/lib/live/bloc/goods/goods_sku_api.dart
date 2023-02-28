import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/model/goods/goods_add.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:fb_live_flutter/live/utils/other/goods_util.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:oktoast/oktoast.dart';

abstract class GoodsSkuApiRoomInfo {
  RoomInfon get roomInfoObject;
}

mixin GoodsSkuApi on BaseAppCubit<int>, BaseAppCubitState, GoodsSkuApiRoomInfo {
  GoodsListModel? detModel;

  RxString price = ''.obs;
  RxString image = ''.obs;

  RxInt stockNum = 0.obs;
  RxInt currentCount = 0.obs;

  RxBool enableSubtract = false.obs;
  RxBool enableAdd = true.obs;
  RxBool isInputCount = false.obs;

  /// 当前已经选择了的规格
  List<int?> selectValueIdList = [];

  /// 限购数量[详情模型]
  int get maxCountDet {
    return detModel?.buyQuota ?? 0;
  }

  void handleEnable() {
    enableSubtract.value = currentCount.value > (detModel?.startSaleNum ?? 1);

    if (currentCount.value >= stockNum.value) {
      /// 已经是最大的库存数量了
      enableAdd.value = false;
    } else if (maxCountDet == 0) {
      /// 0表示不限购
      enableAdd.value = true;
    } else {
      enableAdd.value = currentCount.value < maxCountDet;
    }
  }

  /// 两个数组进行对比，判断是否都包含
  bool isContain(List<int> propValues, List<int?> skuList) {
    final List<int?> newList = [];
    skuList.forEach((element) {
      if (propValues.contains(element)) {
        newList.add(element);
      }
    });

    /// 如果两个长度相等则表示所有的都包含了
    return newList.length == propValues.length;
  }

  /*
  * 处理规格，检测未选中的，如果库存为空则致灰
  * */
  void handleProp() {
    /// 未选择规格数量
    int count = 0;

    /// 如果未选择规格数量为1，则是那个未选择的组索引，
    /// 比如我第二组未选择，索引为1；
    int i = 0;

    /// 规格第一层序列【规格标题等】
    for (int index = 0; index < detModel!.skuProps!.length; index++) {
      /// 判断是否选择为空，为空则未选择的【组】数量加1
      if (detModel!.skuProps![index].selectValueId == null) {
        count += 1;
        i = index;
      }
    }

    /// 只有1组没选择时
    if (count == 1) {
      /// 规格第二层序列【规格item等】
      for (int a = 0; a < detModel!.skuProps![i].values!.length; a++) {
        /// 当前【未选择的规格组的id数组】
        final List<int?> sku = [];

        /// 获取唯一未选择规格的规格组
        final List<SkuValues> values = detModel!.skuProps![i].values!;

        /// 把id添加到【未选择的规格组的id数组】
        for (int index = 0; index < values.length; index++) {
          sku.add(values[index].valueId);
        }

        /// 使用【未选择的规格组的id数组】遍历
        sku.forEach((element) {
          /// 获取当前选择了的sku列表，使用【新的列表】接收
          final List<int?> newSkuList = List.from(selectValueIdList);

          /// 再插入当前遍历的id到【新的列表】
          newSkuList.insert(i, element);

          /// 要改变的当前规格组列表索引值，如当前遍历未选择的为第一个，值为0
          final int changeIndex = sku.indexOf(element);

          /// 拿sku列表【取价格与库存的列表】进行遍历
          detModel!.skuList!.forEach((element) {
            /// 判断当前遍历的sku列表【取价格与库存的列表】
            /// 是否与当前未选择的规格组所遍历的规格【组合的新id列表】相等
            if (isContain(element.propValues!, newSkuList)) {
              /// 相等且当前规格组库存为0
              if (element.stockNum! <= 0) {
                /// 设置当前规格状态为禁用【不可选择】
                detModel!.skuProps![i].values![changeIndex].status = 3;
              } else if (detModel!.skuProps![i].values![changeIndex].status ==
                  3) {
                /// 设置当前规格状态为不禁用【可选择】
                /// 防止出现上次处理好的的禁用，这次还是禁用，实际是有库存的，
                ///
                /// 如：
                /// 1.粉色 + 512G + 5.2寸 = 有库存；
                /// 2.粉色 + 128G + 5.2寸 = 无库存；
                ///
                /// 这时候选择2后再选择1【5.2寸】也变成禁用了；
                detModel!.skuProps![i].values![changeIndex].status = 1;
              }
            }
          });
        });
      }

      /// 当所有属性都有选时
    } else if (count == 0) {
      /// 规格第一层序列【规格标题等】
      detModel!.skuProps!.forEach((elementProp) {
        /// 当前规格组索引
        final int propsIndex = detModel!.skuProps!.indexOf(elementProp);

        /// 【当前规格组未选择的id数组】
        final List<int?> sku = [];

        /// 规格第二层序列【规格item等】
        for (int index = 0; index < elementProp.values!.length; index++) {
          /// 判断是否未选择的
          if (elementProp.values![index].status != 2) {
            /// 把id添加到【当前规格组未选择的id数组】
            sku.add(elementProp.values![index].valueId);
          }
        }

        /// 使用【当前规格组未选择的id数组】遍历
        sku.forEach((element) {
          /// 获取当前选择了的sku列表，使用【新的列表】接收
          final List<int?> newSkuList = List.from(selectValueIdList);

          /// 把当前规格组的已选择替换为未选择的规格Id
          newSkuList[propsIndex] = element;

          /// 把当前模型内【当前规格组】的规格列表替换为纯规格id形式的列表
          final List<int?> newValues = detModel!.skuProps![propsIndex].values!
              .map<int?>((e) => e.valueId)
              .toList();

          /// 从【当前规格组】id列表找到当前遍历的未选择id的索引，
          /// 比如【当前规格组】的第一个未选择规格索引值为0
          final int changeIndex = newValues.indexOf(element);

          /// 拿sku列表【取价格与库存的列表】进行遍历
          detModel!.skuList!.forEach((element) {
            /// 判断当前遍历的sku列表【取价格与库存的列表】
            /// 是否与【当前规格组】未选择的规格组所遍历的规格【组合的新id列表】相等
            if (isContain(element.propValues!, newSkuList)) {
              /// 相等且当前规格组库存为0
              if (element.stockNum! <= 0) {
                /// 设置当前规格状态为禁用【不可选择】
                detModel!.skuProps![propsIndex].values![changeIndex].status = 3;
              } else {
                /// 未选择的规格且库存不为0，设置规格状态为【未选择】，
                /// 防止出现与其他规格匹配的状态缓存还存在；
                detModel!.skuProps![propsIndex].values![changeIndex].status = 1;
              }
            }
          });
        });
      });
    } else {
      initHandlePropGrey();
    }
    onRefresh();
  }

  /*
  * 获取商品详情
  * */
  Future shopGoodsDetail(GoodsListModel item) async {
    final value = await Api.shopGoodsDetail(item.shopId, item.itemId);
    if (value['code'] != 200) {
      return;
    }
    detModel = GoodsListModel.fromJson(value['data']);

    initHandlePropGrey();

    price.value = detModel!.price!;
    image.value = detModel?.image ?? '';
    stockNum.value = detModel!.quantity!;
    currentCount.value = detModel?.startSaleNum ?? 1;

    handleEnable();

    onRefresh();
    return value;
  }

  /*
  * 初始化处理规格致灰
  *
  * 一开始就至灰，表示明确了某一个规格已经全部买完了；
  * 任何与这个规格的组合都没货时，那么这个规格就可以一开始就至灰;
  * */
  void initHandlePropGrey() {
    /// 与当前规格相关最大的库存数量，key-value存储
    final Map propMaxLengthMap = {};

    /// 拿sku列表进行遍历
    detModel!.skuList!.forEach((element) {
      /// 规格第一层序列【规格标题等】
      for (int i = 0; i < detModel!.skuProps!.length; i++) {
        /// 规格第二层序列【规格item等】
        for (int a = 0; a < detModel!.skuProps![i].values!.length; a++) {
          if (element.propValues!
              .contains(detModel!.skuProps![i].values![a].valueId)) {
            /// 规格的valueId
            final valueId = detModel!.skuProps![i].values![a].valueId;

            /// 判断【存储的最大库存数量】Map是否存储了当前库存id
            if (propMaxLengthMap.containsKey(valueId)) {
              /// 旧版存储的当前规格最大库存数量
              final int oldMaxStore = propMaxLengthMap[valueId];

              /// 判断旧版存储的最大数量是否小与当前读到的本规格库存数量
              if (oldMaxStore <= element.stockNum!) {
                /// 小于当前规格库存数量，把当前的设置为最大库存
                propMaxLengthMap[valueId] = element.stockNum;
              }
            } else {
              /// 存储当前规格库存数量为本规格最大库存数量
              propMaxLengthMap[valueId] = element.stockNum;
            }
          }
        }
      }
    });

    /// 拿存储规格最大库存进行key，value序列
    propMaxLengthMap.forEach((key, value) {
      /// key=规格的valueId，value=当前规格与所有其他规格在一起对比的最大库存数量
      for (int i = 0; i < detModel!.skuProps!.length; i++) {
        for (int a = 0; a < detModel!.skuProps![i].values!.length; a++) {
          /// 判断当前规格最大库存是否小于等于0
          final bool? isAllNotStock = value <= 0;
          if (detModel!.skuProps![i].values![a].valueId == key) {
            if (isAllNotStock!) {
              /// 设置规格的状态为禁用
              detModel!.skuProps![i].values![a].status = 3;
            } else if (detModel!.skuProps![i].values![a].status == 3) {
              /// 设置规格的状态为未选择
              detModel!.skuProps![i].values![a].status = 1;
            }
          }
        }
      }
    });
    onRefresh();
  }

  /*
  * 商品下单
  * */
  Future<void> liveGoodsOrder(BuildContext? context, int? skuId, int num,
      List<String?> messages) async {
    myLoadingToast(tips: '正在加载');
    final value = await Api.liveGoodsOrder(
        detModel!.itemId, skuId, num, messages, roomInfoObject.roomId);
    if (value['code'] != 200) {
      myFailToast(value['msg']);
      stockNot(value);
      return;
    }
    dismissAllToast();
    await fbApi.pushLinkPage(
        context!,

        /// [2021 11.24] 下单拼接kdt_id
        /// [2021 11.25] 下单不需要拼接kdt_id
        GoodsUtil.joinMiniProgramSuffix(value['data']['jumpUrl']),
        title: "确认订单");
  }

  /*
  * 库存不足相应处理
  * */
  void stockNot(Map value) {
    /// 700=处理库存不足ui效果
    if (value['code'] == 700) {
      detModel!.quantity = 0;
      stockNum.value = 0;
      onRefresh();
    }
  }

  /*
  * 向购物车添加商品
  * */
  Future<void> liveCartAdd(BuildContext? context, int? skuId, int num,
      VoidCallback? addSuccess, List<String?> messages) async {
    myLoadingToast(tips: '正在添加');
    final value = await Api.liveCartAdd(
        detModel!.itemId, skuId, num, messages, roomInfoObject.roomId);
    if (value['code'] != 200) {
      myFailToast(value['msg']);
      stockNot(value);
      return;
    }
    RouteUtil.pop();
    if (addSuccess != null) {
      addSuccess();
      dismissAllToast();
    } else {
      mySuccessToast("添加购物车成功");
    }
  }
}
