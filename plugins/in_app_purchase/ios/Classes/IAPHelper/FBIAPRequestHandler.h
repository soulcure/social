//
//  FBIAPRequestHandler.h
//  in_app_purchase
//
//  Created by Soto.Poul on 2021/1/20.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ProductRequestCompletion)(SKProductsResponse *_Nullable response,
                                         NSError *_Nullable            errror);

@interface FBIAPRequestHandler : NSObject

/// 初始化道具信息请求
- (instancetype)initWithRequest:(SKRequest *)request;

/// 开始请求获取道具信息
- (void)startProductRequestWithCompletionHandler:(ProductRequestCompletion)completion;

@end

NS_ASSUME_NONNULL_END
