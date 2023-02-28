//
//  FBIAPObjectTranslator.h
//  in_app_purchase
//
//  Created by Soto.Poul on 2021/1/20.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBIAPObjectTranslator : NSObject

/// SKProduct 转换为 NSDictionary
+ (NSDictionary *)getMapFromSKProduct:(SKProduct *)product;

/// SKProductSubscriptionPeriod 转换为 NSDictionary
+ (NSDictionary *)getMapFromSKProductSubscriptionPeriod:(SKProductSubscriptionPeriod *)period
    API_AVAILABLE(ios(11.2));

/// SKProductDiscount 转换为 NSDictionary
+ (NSDictionary *)getMapFromSKProductDiscount:(SKProductDiscount *)discount
    API_AVAILABLE(ios(11.2));

/// SKProductsResponse 转换为 NSDictionary
+ (NSDictionary *)getMapFromSKProductsResponse:(SKProductsResponse *)productResponse;

/// SKPayment 转换为 NSDictionary
+ (NSDictionary *)getMapFromSKPayment:(SKPayment *)payment;

/// NSLocale 转换为 NSDictionary
+ (NSDictionary *)getMapFromNSLocale:(NSLocale *)locale;

/// NSDictionary 转换为 SKMutablePayment
+ (SKMutablePayment *)getSKMutablePaymentFromMap:(NSDictionary *)map;

/// SKPaymentTransaction 转换为 NSDictionary
+ (NSDictionary *)getMapFromSKPaymentTransaction:(SKPaymentTransaction *)transaction;

/// NSError 转换为 NSDictionary
+ (NSDictionary *)getMapFromNSError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
