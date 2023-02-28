//
//  QiAudioPlayer.h
//  QiAppRunInBackground
//
//  Created by wangyongwang on 2019/12/30.
//  Copyright © 2019 WYW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QiAudioPlayer : NSObject{
    NSTimer     *_timer;
}

+ (instancetype)sharedInstance;

@property (nonatomic, strong) AVAudioPlayer *player;

- (void) resumePlay;
- (void) stopPlay;
- (void) keepAliveTimeOut;
@end

NS_ASSUME_NONNULL_END
