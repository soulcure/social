import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

/// 监听输入框的输入，进行背压，过滤等处理，再发送输入变化事件
class SearchInputModel extends ChangeNotifier {
  // 有控制背压的流
  final Subject<String> _searchSubject;

  // 没有控制背压的流
  final Subject<String> _searchImmediateSubject;

  /// 输入限速，单位：ms
  final int debounceTime;

  String get input => _input;
  String _input;

  ///输入框焦点处理
  final inputFocusNode = FocusNode();

  SearchInputModel({
    this.debounceTime = 500,
  })  : _searchSubject = PublishSubject(),
        _searchImmediateSubject = PublishSubject();

  /// 处理后的输入流，限速和过滤特殊字符
  Stream<String> get searchStream => _searchSubject
      .debounceTime(Duration(milliseconds: debounceTime))
      .mergeWith([_searchImmediateSubject]);

  @override
  void dispose() {
    _searchSubject.close();
    _searchImmediateSubject.close();
    super.dispose();
  }

  /// 延迟发送数据，当搜索框输入发生变化时调用
  void onInput(String key) {
    _input = key;
    _searchSubject.add(input);
  }

  /// 立即重发数据，tab切换时调用
  void repeatLast() {
    _searchImmediateSubject.add(_input);
  }
}

/// 用于控制切换tab页
class SearchTabModel extends ChangeNotifier {
  int _currentTab = 0;
  final int messageTab = 0;
  final int memberTab = 1;

  bool isGroup = false;

  int get currentTab => _currentTab;

  void setCurrentTab(int tab) {
    if (_currentTab == tab) return;

    _currentTab = tab;
    notifyListeners();
  }

  ///不做校验
  bool isSelectMessageTab() {
    return _currentTab == messageTab;
  }

  ///不做校验
  bool isSelectMemberTab() {
    return _currentTab == memberTab;
  }
}
