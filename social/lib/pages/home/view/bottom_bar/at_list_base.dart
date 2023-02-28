import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/pages/home/view/bottom_bar/landscape_at_list.dart';
import 'package:im/utils/orientation_util.dart';

import 'portrait_at_list.dart';

class AtList extends StatefulWidget {
  @override
  _AtListState createState() => _AtListState();
}

class _AtListState extends State<AtList> {
  @override
  Widget build(BuildContext context) {
    return OrientationUtil.portrait ? PortraitAtList() : LandscapeAtList();
  }
}

