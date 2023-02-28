//
//  FBIAPaymentQueueHandler.m
//  in_app_purchase
//
//  Created by Soto.Poul on 2021/1/20.
//

#import "FBIAPaymentQueueHandler.h"

@interface FBIAPaymentQueueHandler ()

/// 支付队列
@property (strong, nonatomic) SKPaymentQueue *queue;

@property (nullable, copy, nonatomic) TransactionsUpdated transactionsUpdated;
@property (nullable, copy, nonatomic) TransactionsRemoved transactionsRemoved;
@property (nullable, copy, nonatomic) RestoreTransactionFailed restoreTransactionFailed;
@property (nullable, copy, nonatomic)
RestoreCompletedTransactionsFinished paymentQueueRestoreCompletedTransactionsFinished;
@property (nullable, copy, nonatomic) ShouldAddStorePayment shouldAddStorePayment;
@property (nullable, copy, nonatomic) UpdatedDownloads updatedDownloads;

@end

@implementation FBIAPaymentQueueHandler

- (instancetype)           initWithQueue:(nonnull SKPaymentQueue *)queue
                     transactionsUpdated:(nullable TransactionsUpdated)transactionsUpdated
                      transactionRemoved:(nullable TransactionsRemoved)transactionsRemoved
                restoreTransactionFailed:(nullable RestoreTransactionFailed)restoreTransactionFailed
    restoreCompletedTransactionsFinished:
    (nullable RestoreCompletedTransactionsFinished)restoreCompletedTransactionsFinished
                   shouldAddStorePayment:(nullable ShouldAddStorePayment)shouldAddStorePayment
                        updatedDownloads:(nullable UpdatedDownloads)updatedDownloads {
    self = [super init];
    if (self) {
        _queue = queue;
        _transactionsUpdated = transactionsUpdated;
        _transactionsRemoved = transactionsRemoved;
        _restoreTransactionFailed = restoreTransactionFailed;
        _paymentQueueRestoreCompletedTransactionsFinished = restoreCompletedTransactionsFinished;
        _shouldAddStorePayment = shouldAddStorePayment;
        _updatedDownloads = updatedDownloads;
    }
    return self;
}

/// 苹果支付队列添加监听
- (void)startObservingPaymentQueue {

    if (@available(iOS 14.0, *)) {
        /// iOS14有的特性, 判断是否已经添加过监听对象了
        if ([_queue.transactionObservers containsObject:self]) {
            return;
        }
    }

    [_queue addTransactionObserver:self];
}

/// 苹果支付队列移除监听
- (void)removeObservingPaymentQueue {
    [_queue removeTransactionObserver:self];
}

// 支付(添加付费事务对象)
- (BOOL)addPayment:(SKPayment *)payment {
    for (SKPaymentTransaction *transaction in self.queue.transactions) {
        if ([transaction.payment.productIdentifier isEqualToString:payment.productIdentifier]) {
            return NO;
        }
    }
    [self.queue addPayment:payment];
    return YES;
}

// 结束交易(从队列中异步删除已完成的交易票据(失败 / 成功)
// 如果交易再购买中(purchasing),则会抛出异常(可以用 @try 获取异常信息)
- (void)finishTransaction:(SKPaymentTransaction *)transaction {
    [self.queue finishTransaction:transaction];
}

/// 恢复购买
/// @param applicationName 根据支付时SKPayment中传入的applicationName恢复购买
/// 如果你的应用中有非消耗品 / 自动订阅 / 非自动订阅 必须提供UI给用户提供恢复功能
- (void)restoreTransactions:(nullable NSString *)applicationName {
    if (applicationName) {
        [self.queue restoreCompletedTransactionsWithApplicationUsername:applicationName];
    } else {
        [self.queue restoreCompletedTransactions];
    }
}

#pragma mark - SKPaymentTransactionObserver

// 当观察者队列中的交易状态(添加或状态改变)发生变化时发送
- (void)   paymentQueue:(SKPaymentQueue *)queue
    updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    // 回调通知dart层
    self.transactionsUpdated(transactions);
}

/// 通知观察者一个或者多个交易被移除队列(通过 finishTransaction)
- (void)   paymentQueue:(SKPaymentQueue *)queue
    removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    self.transactionsRemoved(transactions);
}

// 恢复购买失败回调
- (void)                           paymentQueue:(SKPaymentQueue *)queue
    restoreCompletedTransactionsFailedWithError:(NSError *)error {
    self.restoreTransactionFailed(error);
}

// 恢复购买成功回调
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    self.paymentQueueRestoreCompletedTransactionsFinished();
}

// 队列更新一个或多个下载对象时回调
- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray<SKDownload *> *)downloads {
    self.updatedDownloads(downloads);
}

// 用户从AppStore发起内购时回调
- (BOOL)     paymentQueue:(SKPaymentQueue *)queue
    shouldAddStorePayment:(SKPayment *)payment
               forProduct:(SKProduct *)product {
    return (self.shouldAddStorePayment(payment, product));
}

#pragma mark - 自定义方法

// 获取未finished的交易凭证(票据)
- (NSArray<SKPaymentTransaction *> *)getUnfinishedTransactions {
    return self.queue.transactions;
}

@end
