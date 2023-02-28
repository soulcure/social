import 'package:event_bus/event_bus.dart';

EventBus goodsAddBus = EventBus();

class GoodsAddEvenModel {
  final int index;
  final String searchText;

  GoodsAddEvenModel(this.index, this.searchText);
}

class GoodsAddTabChangeEvenModel {
  final int index;
  final String searchText;

  GoodsAddTabChangeEvenModel(this.index, this.searchText);
}

class SelectAllEventModel {
  final int index;

  SelectAllEventModel(this.index);
}

class GoodsRefreshModel {
  final int index;

  GoodsRefreshModel(this.index);
}
