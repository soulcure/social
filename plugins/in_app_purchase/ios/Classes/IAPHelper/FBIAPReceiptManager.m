//
//  FBIAPReceiptManager.m
//  in_app_purchase
//
//  Created by Soto.Poul on 2021/1/20.
//

#import "FBIAPReceiptManager.h"
#import <Flutter/Flutter.h>

@implementation FBIAPReceiptManager

- (NSString *)retrieveReceiptWithError:(FlutterError **)error {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [self getReceiptData:receiptURL];
    if (!receipt) {
        *error = [FlutterError errorWithCode:@"storekit_no_receipt"
                                     message:@"Cannot find receipt for the current main bundle."
                                     details:nil];
        return nil;
    }
    return [receipt base64EncodedStringWithOptions:kNilOptions];
}

- (NSData *)getReceiptData:(NSURL *)url {
    return [NSData dataWithContentsOfURL:url];
}

@end
