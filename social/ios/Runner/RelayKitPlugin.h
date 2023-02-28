//
//  RelayKitPlugin.h
//  Runner
//
//  Created by red on 2021/12/11.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface RelayKitPlugin : NSObject<FlutterPlugin>
@property(nonatomic,strong)FlutterMethodChannel* channel;
@end

NS_ASSUME_NONNULL_END
