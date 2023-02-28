//
//  FBAudioSessionCacheManager.h
//  Runner
//
//  Created by jason.duan on 2022/2/24.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBAudioSessionCacheManager : NSObject

//更改audioSession前缓存RTC当下的设置
+ (void)cacheCurrentAudioSession;

//重置到缓存的audioSession设置
+ (void)resetToCachedAudioSession;

@end

NS_ASSUME_NONNULL_END
