#import "InAppPurchasePlugin.h"

#import <StoreKit/StoreKit.h>
#import "FBIAPObjectTranslator.h"
#import "FBIAPReceiptManager.h"
#import "FBIAPRequestHandler.h"
#import "FBIAPaymentQueueHandler.h"
#import "FBNullDataTool.h"

@interface InAppPurchasePlugin ()

// 保存FBIAPRequestHandler对象,在请求完成后从集合中移除
@property (strong, nonatomic, readonly) NSMutableSet *requestHandlers;

// 保存查询到的道具信息(SKProduct),可以避免在本生命周期内重新获取,提高支付速度
@property (strong, nonatomic, readonly) NSMutableDictionary *productsCache;

// 回调dart层的监听渠道
@property (strong, nonatomic, readonly) FlutterMethodChannel *callbackChannel;
@property (strong, nonatomic, readonly) NSObject<FlutterTextureRegistry> *registry;
@property (strong, nonatomic, readonly) NSObject<FlutterBinaryMessenger> *messenger;
@property (strong, nonatomic, readonly) NSObject<FlutterPluginRegistrar> *registrar;

@property (strong, nonatomic, readonly) FBIAPReceiptManager *receiptManager;

@end

@implementation InAppPurchasePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
                                     methodChannelWithName:@"plugins.flutter.io/in_app_purchase"
                                           binaryMessenger:[registrar messenger]];
    InAppPurchasePlugin *instance = [[InAppPurchasePlugin alloc] initWithRegistrar:registrar];
    [registrar addMethodCallDelegate:instance channel:channel];
}

// 票据管理类初始化
- (instancetype)initWithReceiptManager:(FBIAPReceiptManager *)receiptManager {
    self = [super init];
    _receiptManager = receiptManager;
    _requestHandlers = [NSMutableSet new];
    _productsCache = [NSMutableDictionary new];
    return self;
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  self = [self initWithReceiptManager:[FBIAPReceiptManager new]];
  _registrar = registrar;
  _registry = [registrar textures];
  _messenger = [registrar messenger];

  __weak typeof(self) weakSelf = self;
  _paymentQueueHandler = [[FBIAPaymentQueueHandler alloc] initWithQueue:[SKPaymentQueue defaultQueue]
      transactionsUpdated:^(NSArray<SKPaymentTransaction *> *_Nonnull transactions) {
      __strong __typeof(self) strongSelf = weakSelf;
        [strongSelf handleTransactionsUpdated:transactions];
      }
      transactionRemoved:^(NSArray<SKPaymentTransaction *> *_Nonnull transactions) {
      __strong __typeof(self) strongSelf = self;
        [strongSelf handleTransactionsRemoved:transactions];
      }
      restoreTransactionFailed:^(NSError *_Nonnull error) {
      __strong __typeof(self) strongSelf = self;
        [strongSelf handleTransactionRestoreFailed:error];
      }
      restoreCompletedTransactionsFinished:^{
      __strong __typeof(self) strongSelf = self;
        [strongSelf restoreCompletedTransactionsFinished];
      }
      shouldAddStorePayment:^BOOL(SKPayment *payment, SKProduct *product) {
      __strong __typeof(self) strongSelf = self;
        return [strongSelf shouldAddStorePayment:payment product:product];
      }
      updatedDownloads:^void(NSArray<SKDownload *> *_Nonnull downloads) {
      __strong __typeof(self) strongSelf = self;
        [strongSelf updatedDownloads:downloads];
      }];
  [_paymentQueueHandler startObservingPaymentQueue];
  _callbackChannel =
      [FlutterMethodChannel methodChannelWithName:@"plugins.flutter.io/in_app_purchase_callback"
                                  binaryMessenger:[registrar messenger]];
  return self;
}

#pragma mark - dart层调用到原生层

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  }else if ([@"-[SKPaymentQueue canMakePayments:]" isEqualToString:call.method]) {
    [self canMakePayments:result];
  } else if ([@"-[SKPaymentQueue transactions]" isEqualToString:call.method]) {
    [self getPendingTransactions:result];
  } else if ([@"-[InAppPurchasePlugin startProductRequest:result:]" isEqualToString:call.method]) {
    [self handleProductRequestMethodCall:call result:result];
  } else if ([@"-[InAppPurchasePlugin addPayment:result:]" isEqualToString:call.method]) {
    [self addPayment:call result:result];
  } else if ([@"-[InAppPurchasePlugin finishTransaction:result:]" isEqualToString:call.method]) {
    [self finishTransaction:call result:result];
  } else if ([@"-[InAppPurchasePlugin restoreTransactions:result:]" isEqualToString:call.method]) {
    [self restoreTransactions:call result:result];
  } else if ([@"-[InAppPurchasePlugin retrieveReceiptData:result:]" isEqualToString:call.method]) {
    [self retrieveReceiptData:call result:result];
  } else if ([@"-[InAppPurchasePlugin refreshReceipt:result:]" isEqualToString:call.method]) {
    [self refreshReceipt:call result:result];
  } else if ([@"-[FBIAPaymentQueueHandler startObservingPaymentQueue:result:]" isEqualToString:call.method]) {
    [_paymentQueueHandler startObservingPaymentQueue];
  } else if ([@"-[FBIAPaymentQueueHandler removeObservingPaymentQueue:result:]" isEqualToString:call.method]) {
    [_paymentQueueHandler removeObservingPaymentQueue];
  }  else {
    result(FlutterMethodNotImplemented);
  }
}

#pragma mark -  定义的原生层方法

/// 支付是否可用
- (void)canMakePayments:(FlutterResult)result {
  result([NSNumber numberWithBool:[SKPaymentQueue canMakePayments]]);
}


/// 获取未结束的交易
- (void)getPendingTransactions:(FlutterResult)result {
  NSArray<SKPaymentTransaction *> *transactions =
      [self.paymentQueueHandler getUnfinishedTransactions];
  NSMutableArray *transactionMaps = [[NSMutableArray alloc] init];
  for (SKPaymentTransaction *transaction in transactions) {
    [transactionMaps addObject:[FBIAPObjectTranslator getMapFromSKPaymentTransaction:transaction]];
  }
  result(transactionMaps);
}

/// 获取道具信息
- (void)handleProductRequestMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if (![call.arguments isKindOfClass:[NSArray class]]) {
    result([FlutterError errorWithCode:@"storekit_invalid_argument"
                               message:@"Argument type of startRequest is not array"
                               details:call.arguments]);
    return;
  }
  NSArray *productIdentifiers = (NSArray *)call.arguments;
  SKProductsRequest *request =
      [self getProductRequestWithIdentifiers:[NSSet setWithArray:productIdentifiers]];
  FBIAPRequestHandler *handler = [[FBIAPRequestHandler alloc] initWithRequest:request];
  [self.requestHandlers addObject:handler];
  __weak typeof(self) weakSelf = self;
  [handler startProductRequestWithCompletionHandler:^(SKProductsResponse *_Nullable response,
                                                      NSError *_Nullable error) {
      
    if (error) {
      result([FlutterError errorWithCode:@"storekit_getproductrequest_platform_error"
                                 message:error.localizedDescription
                                 details:error.description]);
      return;
    }
    if (!response) {
      result([FlutterError errorWithCode:@"storekit_platform_no_response"
                                 message:@"Failed to get SKProductResponse in startRequest "
                                         @"call. Error occured on iOS platform"
                                 details:call.arguments]);
      return;
    }
      
    __strong __typeof(self) strongSelf = weakSelf;
    for (SKProduct *product in response.products) {
      [self.productsCache setObject:product forKey:product.productIdentifier];
    }
    result([FBIAPObjectTranslator getMapFromSKProductsResponse:response]);
    [strongSelf.requestHandlers removeObject:handler];
  }];
}

/// 进行道具支付
- (void)addPayment:(FlutterMethodCall *)call result:(FlutterResult)result {
  if (![call.arguments isKindOfClass:[NSDictionary class]]) {
    result([FlutterError errorWithCode:@"storekit_invalid_argument"
                               message:@"Argument type of addPayment is not a Dictionary"
                               details:call.arguments]);
    return;
  }
  NSDictionary *paymentMap = (NSDictionary *)call.arguments;
  NSString *productID = [paymentMap objectForKey:@"productIdentifier"];
  // When a product is already fetched, we create a payment object with
  // the product to process the payment.
  SKProduct *product = [self getProduct:productID];
  if (!product) {
    result([FlutterError
        errorWithCode:@"storekit_invalid_payment_object"
              message:
                  @"You have requested a payment for an invalid product. Either the "
                  @"`productIdentifier` of the payment is not valid or the product has not been "
                  @"fetched before adding the payment to the payment queue."
              details:call.arguments]);
    return;
  }
  SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
  payment.applicationUsername = [FBNullDataTool replaceNullData:[paymentMap objectForKey:@"applicationUsername"]];
  NSString *requestDataStr =  [FBNullDataTool replaceNullData:[paymentMap objectForKey:@"requestData"]];
  if (requestDataStr.length >0) {
    payment.requestData = [requestDataStr dataUsingEncoding:NSUTF8StringEncoding];
  }
  NSNumber *quantity = [FBNullDataTool replaceNullData:[paymentMap objectForKey:@"quantity"]];
  payment.quantity = (quantity != nil) ? quantity.integerValue : 1;
  if (@available(iOS 8.3, *)) {
      NSNumber *simulatesAskToBuyInSandbox = [FBNullDataTool replaceNullData:[paymentMap objectForKey:@"simulatesAskToBuyInSandbox"]];
    payment.simulatesAskToBuyInSandbox = (id)simulatesAskToBuyInSandbox == (id)[NSNull null]
                                             ? NO
                                             : [simulatesAskToBuyInSandbox boolValue];
  }

  if (![self.paymentQueueHandler addPayment:payment]) {
    result([FlutterError
        errorWithCode:@"storekit_duplicate_product_object"
              message:@"有一个相同的商品在待处理中,请等待它完成或者使用 completePurchase 手动完成它,以免发生重复购买情况"

              details:call.arguments]);
    return;
  }
  result(nil);
}

// 结束交易(从队列中异步删除已完成的交易票据(失败 / 成功)
// 如果交易再购买中(purchasing),则会抛出异常(可以用 @try 获取异常信息)
- (void)finishTransaction:(FlutterMethodCall *)call result:(FlutterResult)result {
  if (![call.arguments isKindOfClass:[NSDictionary class]]) {
    result([FlutterError errorWithCode:@"storekit_invalid_argument"
                               message:@"Argument type of finishTransaction is not a Dictionary"
                               details:call.arguments]);
    return;
  }
  NSDictionary *paymentMap = (NSDictionary *)call.arguments;
  NSString *transactionIdentifier = [paymentMap objectForKey:@"transactionIdentifier"];
  NSString *productIdentifier = [paymentMap objectForKey:@"productIdentifier"];

  NSArray<SKPaymentTransaction *> *pendingTransactions =
      [self.paymentQueueHandler getUnfinishedTransactions];

  for (SKPaymentTransaction *transaction in pendingTransactions) {
    // If the user cancels the purchase dialog we won't have a transactionIdentifier.
    // So if it is null AND a transaction in the pendingTransactions list has
    // also a null transactionIdentifier we check for equal product identifiers.
    if ([transaction.transactionIdentifier isEqualToString:transactionIdentifier] ||
        ([transactionIdentifier isEqual:[NSNull null]] &&
         transaction.transactionIdentifier == nil &&
         [transaction.payment.productIdentifier isEqualToString:productIdentifier])) {
      @try {
        [self.paymentQueueHandler finishTransaction:transaction];
      } @catch (NSException *e) {
        result([FlutterError errorWithCode:@"storekit_finish_transaction_exception"
                                   message:e.name
                                   details:e.description]);
        return;
      }
    }
  }

  result(nil);
}

/// 恢复购买
- (void)restoreTransactions:(FlutterMethodCall *)call result:(FlutterResult)result {
  if (call.arguments && ![call.arguments isKindOfClass:[NSString class]]) {
    result([FlutterError
        errorWithCode:@"storekit_invalid_argument"
              message:@"Argument is not nil and the type of finishTransaction is not a string."
              details:call.arguments]);
    return;
  }
  [self.paymentQueueHandler restoreTransactions:call.arguments];
  result(nil);
}

/// 获取票据信息(appStoreReceiptURL 方式)
- (void)retrieveReceiptData:(FlutterMethodCall *)call result:(FlutterResult)result {
  FlutterError *error = nil;
  NSString *receiptData = [self.receiptManager retrieveReceiptWithError:&error];
  if (error) {
    result(error);
    return;
  }
  result(receiptData);
}

/// 刷新票据结果
- (void)refreshReceipt:(FlutterMethodCall *)call result:(FlutterResult)result {
  NSDictionary *arguments = call.arguments;
  SKReceiptRefreshRequest *request;
  if (arguments) {
    if (![arguments isKindOfClass:[NSDictionary class]]) {
      result([FlutterError errorWithCode:@"storekit_invalid_argument"
                                 message:@"Argument type of startRequest is not array"
                                 details:call.arguments]);
      return;
    }
    NSMutableDictionary *properties = [NSMutableDictionary new];
    properties[SKReceiptPropertyIsExpired] = arguments[@"isExpired"];
    properties[SKReceiptPropertyIsRevoked] = arguments[@"isRevoked"];
    properties[SKReceiptPropertyIsVolumePurchase] = arguments[@"isVolumePurchase"];
    request = [self getRefreshReceiptRequest:properties];
  } else {
    request = [self getRefreshReceiptRequest:nil];
  }
  FBIAPRequestHandler *handler = [[FBIAPRequestHandler alloc] initWithRequest:request];
  [self.requestHandlers addObject:handler];
  __weak typeof(self) weakSelf = self;
  [handler startProductRequestWithCompletionHandler:^(SKProductsResponse *_Nullable response,
                                                      NSError *_Nullable error) {
    if (error) {
      result([FlutterError errorWithCode:@"storekit_refreshreceiptrequest_platform_error"
                                 message:error.localizedDescription
                                 details:error.description]);
      return;
    }
    result(nil);
    [weakSelf.requestHandlers removeObject:handler];
  }];
}

#pragma mark - handle delegate 原生回调到dart层方法

/// 交易状态更新
- (void)handleTransactionsUpdated:(NSArray<SKPaymentTransaction *> *)transactions {
  NSMutableArray *maps = [NSMutableArray new];
  for (SKPaymentTransaction *transaction in transactions) {
    [maps addObject:[FBIAPObjectTranslator getMapFromSKPaymentTransaction:transaction]];
  }
  [self.callbackChannel invokeMethod:@"updatedTransactions" arguments:maps];
}

/// 交易被移出
- (void)handleTransactionsRemoved:(NSArray<SKPaymentTransaction *> *)transactions {
  NSMutableArray *maps = [NSMutableArray new];
  for (SKPaymentTransaction *transaction in transactions) {
    [maps addObject:[FBIAPObjectTranslator getMapFromSKPaymentTransaction:transaction]];
  }
  [self.callbackChannel invokeMethod:@"removedTransactions" arguments:maps];
}

/// 恢复购买失败
- (void)handleTransactionRestoreFailed:(NSError *)error {
  [self.callbackChannel invokeMethod:@"restoreCompletedTransactionsFailed"
                           arguments:[FBIAPObjectTranslator getMapFromNSError:error]];
}

/// 恢复购买成功
- (void)restoreCompletedTransactionsFinished {
  [self.callbackChannel invokeMethod:@"paymentQueueRestoreCompletedTransactionsFinished"
                           arguments:nil];
}

// 队列更新一个或多个下载对象时回调
- (void)updatedDownloads:(NSArray<SKDownload *> *)downloads {
  NSLog(@"Received an updatedDownloads callback, but downloads are not supported.");
}

// 用户从AppStore发起内购时回调
- (BOOL)shouldAddStorePayment:(SKPayment *)payment product:(SKProduct *)product {
  // We always return NO here. And we send the message to dart to process the payment; and we will
  // have a interception method that deciding if the payment should be processed (implemented by the
  // programmer).
  [self.productsCache setObject:product forKey:product.productIdentifier];
  [self.callbackChannel invokeMethod:@"shouldAddStorePayment"
                           arguments:@{
                             @"payment" : [FBIAPObjectTranslator getMapFromSKPayment:payment],
                             @"product" : [FBIAPObjectTranslator getMapFromSKProduct:product]
                           }];
  return NO;
}

#pragma mark - dependency injection (for unit testing)

/// 获取一个新的道具信息的请求
- (SKProductsRequest *)getProductRequestWithIdentifiers:(NSSet *)identifiers {
  return [[SKProductsRequest alloc] initWithProductIdentifiers:identifiers];
}

/// 从缓存中获取道具信息(SKProduct)
- (SKProduct *)getProduct:(NSString *)productID {
  return [self.productsCache objectForKey:productID];
}

/// 获取一个新的刷新票据请求
- (SKReceiptRefreshRequest *)getRefreshReceiptRequest:(NSDictionary *)properties {
  return [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:properties];
}

@end
