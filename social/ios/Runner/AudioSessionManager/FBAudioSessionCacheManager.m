//
//  FBAudioSessionCacheManager.m
//  Runner
//
//  Created by jason.duan on 2022/2/24.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "FBAudioSessionCacheManager.h"

static AVAudioSessionCategory cachedCategory = nil;
static AVAudioSessionCategoryOptions cachedCategoryOptions = nil;

@implementation FBAudioSessionCacheManager

//更改audioSession前缓存RTC当下的设置
+ (void)cacheCurrentAudioSession {
    if (![[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayback] && ![[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
        return;
    }
    @synchronized (self) {
        cachedCategory = [AVAudioSession sharedInstance].category;
        cachedCategoryOptions = [AVAudioSession sharedInstance].categoryOptions;
    }
}

//重置到缓存的audioSession设置
+ (void)resetToCachedAudioSession {
    if (!cachedCategory) {
        return;
    }
    BOOL needResetAudioSession = ![[AVAudioSession sharedInstance].category isEqualToString:cachedCategory] || [AVAudioSession sharedInstance].categoryOptions != cachedCategoryOptions;
    if (needResetAudioSession) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[AVAudioSession sharedInstance] setCategory:cachedCategory withOptions:cachedCategoryOptions error:nil];
            [[AVAudioSession sharedInstance] setActive:YES error:nil];
            @synchronized (self) {
                cachedCategory = nil;
                cachedCategoryOptions = nil;
            }
        });
    }
}


@end
