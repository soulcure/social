import 'package:event_bus/event_bus.dart';

EventBus goodsCountBus = EventBus();

class GoodsCountModel {
  final int? count;

  GoodsCountModel(this.count);
}
