import 'package:event_bus/event_bus.dart';
import 'package:fb_live_flutter/live/model/room_giftsendsuc_model.dart';

EventBus sendGiftsEventBus = EventBus();

class SendGitsEvent {
  GiftSuccessModel giftSucModel;

  SendGitsEvent(this.giftSucModel);
}
