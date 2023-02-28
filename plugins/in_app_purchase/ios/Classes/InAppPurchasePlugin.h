#import <Flutter/Flutter.h>

@class FBIAPaymentQueueHandler;
@class FBIAPReceiptManager;

@interface InAppPurchasePlugin : NSObject<FlutterPlugin>

@property (strong, nonatomic) FBIAPaymentQueueHandler *paymentQueueHandler;

- (instancetype)initWithReceiptManager:(FBIAPReceiptManager *)receiptManager
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
