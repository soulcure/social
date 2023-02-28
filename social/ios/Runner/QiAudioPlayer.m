//
//  QiAudioPlayer.m
//  QiAppRunInBackground
//
//  Created by wangyongwang on 2019/12/30.
//  Copyright © 2019 WYW. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QiAudioPlayer.h"

static QiAudioPlayer *instance = nil;

@interface QiAudioPlayer ()

@end

@implementation QiAudioPlayer

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[QiAudioPlayer alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    [self initPlayer];
    return self;
}

- (void)initPlayer {
    [self.player prepareToPlay];
}

- (AVAudioPlayer *)player {
    if (!_player) {
        //后台播放音频设置
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *error;
        [session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
        [session setActive:YES error:&error];
        //播放背景音乐
        NSString *musicPath = [[NSBundle mainBundle] pathForResource:@"mute" ofType:@"wav"];
        NSURL *url = [[NSURL alloc] initFileURLWithPath:musicPath];
        // 创建播放器
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        [_player prepareToPlay];
        [_player setVolume:0.01];
        _player.numberOfLoops = -1; //设置音乐播放次数  -1为一直循环
    }
    return _player;
}

- (void)resumePlay {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (!_player.isPlaying) {
        NSError *error;
        [session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
        [session setActive:YES error:&error];
        [_player play];
        if (_timer) {
            [_timer invalidate];
            _timer = nil;
        }
        _timer = [NSTimer scheduledTimerWithTimeInterval:1800 target:self selector:@selector(keepAliveTimeOut) userInfo:nil repeats:NO];
    }
}

- (void)keepAliveTimeOut {
    [_player pause];
}

- (void)stopPlay {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    [_player pause];
}

@end
