//
//  FBIAPRequestHandler.m
//  in_app_purchase
//
//  Created by Soto.Poul on 2021/1/20.
//

#import "FBIAPRequestHandler.h"
#import <StoreKit/StoreKit.h>

@interface FBIAPRequestHandler () <SKProductsRequestDelegate>

@property (copy, nonatomic) ProductRequestCompletion completion;
@property (strong, nonatomic) SKRequest *request;

@end

@implementation FBIAPRequestHandler

- (instancetype)initWithRequest:(SKRequest *)request {
    self = [super init];
    if (self) {
        self.request = request;
        request.delegate = self;
    }
    return self;
}

- (void)startProductRequestWithCompletionHandler:(ProductRequestCompletion)completion {
    self.completion = completion;
    [self.request start];
}

- (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response {
    if (self.completion) {
        /// 获取商品相信信息
        self.completion(response, nil);
        // 此处self.completion需要设置为nil,以免重复调用
        self.completion = nil;
    }
}

- (void)requestDidFinish:(SKRequest *)request {
    if (self.completion) {
        self.completion(nil, nil);
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    if (self.completion) {
        self.completion(nil, error);
    }
}

@end
