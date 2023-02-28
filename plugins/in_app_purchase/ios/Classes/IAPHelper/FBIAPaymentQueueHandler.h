//
//  FBIAPaymentQueueHandler.h
//  in_app_purchase
//
//  Created by Soto.Poul on 2021/1/20.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@class SKPaymentTransaction;

NS_ASSUME_NONNULL_BEGIN

typedef void (^TransactionsUpdated)(NSArray<SKPaymentTransaction *> *transactions);
typedef void (^TransactionsRemoved)(NSArray<SKPaymentTransaction *> *transactions);
typedef void (^RestoreTransactionFailed)(NSError *error);
typedef void (^RestoreCompletedTransactionsFinished)(void);
typedef BOOL (^ShouldAddStorePayment)(SKPayment *payment, SKProduct *product);
typedef void (^UpdatedDownloads)(NSArray<SKDownload *> *downloads);

@interface FBIAPaymentQueueHandler : NSObject <SKPaymentTransactionObserver>

- (instancetype)           initWithQueue:(nonnull SKPaymentQueue *)queue
                     transactionsUpdated:(nullable TransactionsUpdated)transactionsUpdated
                      transactionRemoved:(nullable TransactionsRemoved)transactionsRemoved
                restoreTransactionFailed:(nullable RestoreTransactionFailed)restoreTransactionFailed
    restoreCompletedTransactionsFinished:
    (nullable RestoreCompletedTransactionsFinished)restoreCompletedTransactionsFinished
                   shouldAddStorePayment:(nullable ShouldAddStorePayment)shouldAddStorePayment
                        updatedDownloads:(nullable UpdatedDownloads)updatedDownloads;

// 结束交易(从队列中异步删除已完成的交易票据(失败 / 成功)
// 如果交易再购买中(purchasing),则会抛出异常(可以用 @try 获取异常信息)
- (void)finishTransaction:(nonnull SKPaymentTransaction *)transaction;

/// 恢复购买
/// @param applicationName 根据支付时SKPayment中传入的applicationName恢复购买
/// applicationName 为空时,恢复以前完成的所有交易
/// 如果你的应用中有非消耗品 / 自动订阅 / 非自动订阅 必须提供UI给用户提供恢复功能
- (void)restoreTransactions:(nullable NSString *)applicationName;

// 获取未finished的交易凭证(票据)
- (NSArray<SKPaymentTransaction *> *)getUnfinishedTransactions;

/// 苹果支付队列添加监听
- (void)startObservingPaymentQueue;

/// 苹果支付队列移除监听
- (void)removeObservingPaymentQueue;

// 支付(添加付费事务对象)
- (BOOL)addPayment:(SKPayment *)payment;

@end

NS_ASSUME_NONNULL_END
