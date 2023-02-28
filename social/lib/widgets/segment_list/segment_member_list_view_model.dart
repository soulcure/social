import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/widgets/segment_list/segment_member_list_data_model.dart';
import 'package:im/widgets/segment_list/segment_member_list_service.dart';
import 'package:rxdart/rxdart.dart';

import '../../loggers.dart';

/*
* 1. WS数据通知机制未实现。已实现框架,未联调
* 2. 首页数据缓存。
* 3.
* */
class UserGroup {
  final String id;
  final int count;
  final int memberStartIndex;
  final String name;
  final List<UserInfo> members;

  UserGroup({
    @required this.id,
    @required this.count,
    this.memberStartIndex,
    this.name = '',
  }) : members = [];
}

// 分段成员列表ViewModel,提供列表UI展示数据和页面交互逻辑
// 其他逻辑（缓存，网路，监听等，放入SegmentMemberListService中统一处理）
class SegmentMemberListViewModel extends GetxController {
  final String guildId;
  final String channelId;
  final ChatChannelType channelType;

  ScrollController get scrollController => _scrollController;
  ScrollController _scrollController;

  BehaviorSubject<List<int>> _pageSubject;

  SegmentMemberListDataModel _dataModel;

  SegmentMemberListDataModel get dataModel => _dataModel;

  StreamSubscription _memberListEventSubscription;
  StreamSubscription _dataModelSubscription;

  SegmentMemberListViewModel(this.guildId, this.channelId, this.channelType) {
    _scrollController = ScrollController();

    _memberListEventSubscription =
        SegmentMemberListService.to.memberListEvent.listen((event) {
      // 监听成员列表公私转换
      if (event is ChangeToPrivateNotice || event is ChangeToPublicNotice) {
        // 如果转换了，则需要重新加载自己的dataModel
        bindDataModel();
      }
    });

    _pageSubject = BehaviorSubject<List<int>>();

    _pageSubject
        .debounceTime(const Duration(milliseconds: 100)) // 防抖:400ms内如果有变化，放弃前面的
        .map((e) {
      logger.info("_pageSubject after debounceTime:$e");
      return e;
    }).distinct((previous, next) {
      //去重, 滚动过程中，需要的页码无变化，需要去重
      logger.info("_pageSubject pre:$previous,next:$next");
      //去重
      final sp = previous.toSet();
      final np = next.toSet();
      if (np.difference(sp).isBlank) {
        //不加 sp.difference(np).isBlank 后面请求的集合是前面集合的子集，认为请求过
        return true;
      } else {
        return false;
      }
    }).map((e) {
      logger.info("_pageSubject item:$e");
      return e;
    }).listen((event) {
      logger.info("_pageSubject refresh pages:$event");
      _dataModel.refresh(pages: event);
    });

    bindDataModel();
  }

  void bindDataModel() {
    // _dataModel?.updateCallback = null;
    _dataModel = SegmentMemberListService.to
        .getDataModel(guildId, channelId, channelType);
    _dataModelSubscription?.cancel();
    _dataModelSubscription = _dataModel.notify.listen((v) {
      // logger.info("data:$v");
      update();
    }, onDone: () {
      // logger.info("done");
    }, onError: () {
      logger.info("error");
    });
    update();
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }

  @override
  void onClose() {
    _pageSubject.close();
    _memberListEventSubscription?.cancel();
    _dataModelSubscription?.cancel();
    super.onClose();
  }

  bool onScrollNotification(ScrollNotification notification) {
    calculateCurrentPages(notification);

    //
    // if (notification is UserScrollNotification) {
    //   timer = Timer(const Duration(milliseconds: 500), () {
    //     _sendSubject.add(_segmentSubject.values);
    //   });
    // }
    // // 滚动过程中，如果是速度很小了，就要更新
    // // 或者停止了
    // if (notification is ScrollUpdateNotification &&
    //     !(notification.scrollDelta == null ||
    //         notification.scrollDelta > 5 ||
    //         notification.scrollDelta < -5)
    // // || notification is ScrollEndNotification
    // ) {
    //   _sendSubject.add(_segmentSubject.values);
    // }

    return false;
  }

  void calculateCurrentPages(ScrollNotification notification) {
    final double viewDimension = notification.metrics.viewportDimension;
    final pixels = notification.metrics.pixels;
    final pixelsGuess = SegmentMemberListService.listHeight * 3;
    final int pageIndex = pixels ~/
        (SegmentMemberListService.listHeight *
            SegmentMemberListService.segmentSize);
    final int pageIndexNext = (pixels + viewDimension + pixelsGuess) ~/
        (SegmentMemberListService.listHeight *
            SegmentMemberListService.segmentSize);
    final int pageIndexPre = (pixels - pixelsGuess) ~/
        (SegmentMemberListService.listHeight *
            SegmentMemberListService.segmentSize);

    // 虽然会计算出三个页码来，但实际上，大部分情况下，三个都相同，在分界处，会有两个相同
    // 正常业务情况下，不会有三个不同的情况（一段100个，一页显示三段的数据）
    final List<int> pages =
        List<int>.from({pageIndexPre, pageIndex, pageIndexNext});
    _pageSubject.add(pages);
  }

  // List memberSnapshot() {
  //   if (_dataModel.itemList != null) {
  //     _dataModel.memberSnapshot();
  //   }
  //   return [];
  // }

  int itemCount() {
    return _dataModel.itemCount;
  }

  dynamic itemOfIndex(int index) {
    if (index >= _dataModel.itemList.length) return null;
    final item = _dataModel.itemList[index];
    if (item == null) return null;
    if (item['User'] != null) {
      // todo 在 build 时 fromJson
      final UserInfo userInfo =
          UserInfo.fromJson(item['User'], fromMemberList: true);
      if (userInfo.guildNickNames == null) {
        userInfo.guildNickNames = {guildId: userInfo.gnick};
      } else {
        userInfo.guildNickNames[guildId] = userInfo.gnick;
      }
      return userInfo;
    } else if (item['Group'] != null) {
      final gid = item['Group']['id'];
      int count = item['Group']['count'];
      String name = item['Group']['name'];
      try {
        count = _dataModel.groupMap[gid]['count'];
      } catch (e) {
        logger.severe("item of index", e);
      }
      try {
        name = _dataModel.groupMap[gid]['name'];
      } catch (e) {
        logger.severe("item of index", e);
      }
      return UserGroup(id: item['Group']['id'], name: name, count: count);
    } else {
      return null;
    }
  }
}
