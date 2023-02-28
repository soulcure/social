
import 'package:flutter/material.dart';

class HomePageModel extends ChangeNotifier {

  bool _scrollEnable = true;

  bool get scrollEnable => _scrollEnable;

  bool _extendUIVisable = false;

  bool get extendUIVisable => _extendUIVisable;

  void setScrollEnable(bool scrollEnable){
    _scrollEnable = scrollEnable;
    notifyListeners();
  }

  void setExtendUIVisable(bool visable){
    _extendUIVisable = visable;
    notifyListeners();
  }

}