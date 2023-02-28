//
//  FBIAPReceiptManager.h
//  in_app_purchase
//
//  Created by Soto.Poul on 2021/1/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FlutterError;

@interface FBIAPReceiptManager : NSObject

/// 获取票据信息
- (nullable NSString *)retrieveReceiptWithError:(FlutterError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
