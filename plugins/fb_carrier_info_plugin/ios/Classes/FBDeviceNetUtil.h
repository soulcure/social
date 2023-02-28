//
//  FBDeviceNetUtil.h
//  fb_carrier_info_plugin
//
//  Created by Soto.Poul on 2021/3/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface FBDeviceNetUtil : NSObject

+ (NSString *)getNetWorkStatus;

+ (NSString *)getOperatorType;

@end

NS_ASSUME_NONNULL_END
