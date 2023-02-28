//
//  FBScreenCaptureManager.m
//  webrtcReplayKit
//
//  Created by jason.duan on 2022/5/11.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#import "FBScreenCaptureManager.h"
#import "NTESYUVConverter.h"
#import "NTESI420Frame.h"
#import "NTESSocketPacket.h"
#import "NTESTPCircularBuffer.h"
#import "FBSocketClientManage.h"

static FBScreenCaptureManager *_sharedManager = nil;

@interface FBScreenCaptureManager () <FBSocketClientManageDelegate>
{
    CGFloat                     _cropRate;
    CGSize                      _targetSize;
    NSTimeInterval              _lastTimeInterval;
    NTESVideoPackOrientation   _orientation;
    
}

@property (nonatomic, weak) RPBroadcastSampleHandler    *sampleHandler;
@property (nonatomic, strong) FBSocketClientManage      *socketManage;
@property (nonatomic, strong) NSUserDefaults            *userDefaults;
@property (nonatomic, strong) dispatch_queue_t           videoQueue;

@end

@implementation FBScreenCaptureManager

+ (instancetype)sharedManager {
    if (!_sharedManager) {
        @synchronized (self) {
            if (!_sharedManager) {
                _sharedManager = [[self alloc] init];
            }
        }
    }
    return _sharedManager;
}

- (instancetype)init {
    if(self = [super init]) {
        self.socketManage = [[FBSocketClientManage alloc] init];
        self.socketManage.delegate = self;
        _targetSize = CGSizeMake(720, 1280);
        _cropRate = 16 / 9.0;
        _orientation = NTESVideoPackOrientationPortrait;
        _lastTimeInterval = [[NSDate date] timeIntervalSince1970] * 1000;
        _videoQueue = dispatch_queue_create("com.idreamsky.buff.webrtcReplayKit.videoprocess", DISPATCH_QUEUE_SERIAL);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeRotate:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    }
    return self;
}

- (void)didChangeRotate:(NSNotification*)notice {
    if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortrait
        || [[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortraitUpsideDown) {
        _orientation = 0;
        //竖屏
    } else if([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
        _orientation = 1;
        //横屏
    }else if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft) {
        _orientation = 1;
    }
}

- (void)startBroadcastWithAppGroup:(NSString *)appGroup sampleHandler:(RPBroadcastSampleHandler *)sampleHandler {
    self.sampleHandler = sampleHandler;
    [self.socketManage connectToHost];
    
    // 通过UserDefaults建立数据通道，接收Extension传递来的视频帧
    _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroup];
    [self registerNotificationsWithIdentifier:@"app_finishBroadcast"];
    [self registerNotificationsWithIdentifier:@"applicationWillTerminate"];
}

- (void)handleSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    if (!sampleBuffer) {
        return;
    }
    NSTimeInterval curTimeInterval = [[NSDate date] timeIntervalSince1970] * 1000; //毫秒
    if ((curTimeInterval - _lastTimeInterval) > 32) {   //控制帧率
        _lastTimeInterval = curTimeInterval;
        [self sendVideoBufferToHostApp:sampleBuffer];
    }
}

- (void)sendVideoBufferToHostApp:(CMSampleBufferRef)sampleBuffer {
    //为了防止屏幕共享扩展还没初始化，用户就杀掉了App,主App存的标记，用来给扩展端使用
    NSDictionary *dataDic = [self.userDefaults objectForKey:@"FB_KEY_BXL_DEFAULT_SCREEN_STATE"];
    BOOL isFinished = [[dataDic objectForKey:@"fb_finished"] boolValue];
    if (isFinished) {
        [self finish];
        return;
    }
    
    CFRetain(sampleBuffer);
    dispatch_async(self.videoQueue, ^{ // queue optimal
        @autoreleasepool {
            CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            
            //从数据中获取屏幕方向
            CFStringRef RPVideoSampleOrientationKeyRef = (__bridge CFStringRef)RPVideoSampleOrientationKey;
            NSNumber *orientation = (NSNumber *)CMGetAttachment(sampleBuffer, RPVideoSampleOrientationKeyRef,NULL);
            
            switch ([orientation integerValue]) {
                case 1:
                    self->_orientation = NTESVideoPackOrientationPortrait;
                    break;
                case 6:
                    self->_orientation = NTESVideoPackOrientationLandscapeRight;
                    break;
                case 8:
                    self->_orientation = NTESVideoPackOrientationLandscapeLeft;
                    break;
                default:
                    break;
            }
            
            // To data
            NTESI420Frame *videoFrame = nil;
            videoFrame = [NTESYUVConverter pixelBufferToI420:pixelBuffer withCrop:self->_cropRate targetSize:self->_targetSize andOrientation:self->_orientation];
            CFRelease(sampleBuffer);
            
            if (videoFrame) {
                if (self.socketManage.connected) {  //socket连接，使用socket传递数据
                    __block NSInteger length = 0;
                    [videoFrame getBytesQueue:^(NSData *data, NSInteger index) {
                        length += data.length;
                        [self.socketManage sendMessage:data timeOut:0];
                        data = nil;
                    }];
                    
                    @autoreleasepool {
                        NSData *headerData = [NTESSocketPacket packetWithBufferLength:length];
                        [self.socketManage sendMessage:headerData timeOut:0];
                        headerData = nil;
                    }
                } else {    //socket断开，使用userDefaults传递数据
                    @autoreleasepool {
                        NSData *raw = [videoFrame bytes];
                        NSData *headerData = nil;
                        if (raw) {
                            headerData = [NTESSocketPacket packetWithBuffer:raw];
                        }
                        
                        if (raw && headerData) {
                            NSDictionary *dataDic = @{@"headerData": headerData, @"videoData" : raw};
                            [self.userDefaults setObject:dataDic forKey:@"FB_KEY_BXL_DEFAULT_FRAME"];//屏幕流数据
                            [self.userDefaults synchronize];
           
                            [self sendNotificationWithIdentifier:@"fb_processSampleBuffer"];
                        }
                        
                        raw = nil;
                        headerData = nil;
                    }
                }
            }
            videoFrame = nil;
        }
    });
}

- (void)sendNotificationWithIdentifier:(nullable NSString *)identifier {
    CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
    BOOL const deliverImmediately = YES;
    CFStringRef identifierRef = (__bridge CFStringRef)identifier;
    CFNotificationCenterPostNotification(center, identifierRef, NULL, NULL, deliverImmediately);
}

- (void)registerNotificationsWithIdentifier:(nullable NSString *)identifier {
    if (identifier.length == 0) {
        return;
    }
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(self),
                                    appNotificationCallback,
                                    (CFStringRef)identifier,
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
}

void appNotificationCallback(CFNotificationCenterRef center,
                                   void * observer,
                                   CFStringRef name,
                                   void const * object,
                                   CFDictionaryRef userInfo) {
    NSString *identifier = (__bridge NSString *)name;
    NSObject *sender = (__bridge NSObject *)observer;
    NSDictionary *notiUserInfo = @{@"identifier" : (identifier ? identifier : @"")};

    if ([sender respondsToSelector:@selector(appNotificationAction:)]) {
        [sender performSelector:@selector(appNotificationAction:) withObject:notiUserInfo];
    }
}

- (void)appNotificationAction:(NSDictionary *)userInfo {
    NSString *identifier = userInfo[@"identifier"];

    if ([identifier isEqualToString:@"app_finishBroadcast"]) {
        [self finish];
    } else if ([identifier isEqualToString:@"applicationWillTerminate"]) {
        [self finish];
    }
}

- (void)finish {
    //断开socket
    [self.socketManage disconnect];
    //标记恢复
    [self.userDefaults setObject:@{@"fb_finished": @(NO)} forKey:@"FB_KEY_BXL_DEFAULT_SCREEN_STATE"];
    [self.userDefaults synchronize];
    
    NSError *error;
    if([UIDevice currentDevice].systemVersion.doubleValue >= 12 && [UIDevice currentDevice].systemVersion.doubleValue < 13) {
        error = [NSError errorWithDomain:@"SampleHandler" code:0 userInfo:@{ NSLocalizedFailureReasonErrorKey:@"您停止了屏幕共享"}];
    }else{
      error = nil;
    }
    [self.sampleHandler finishBroadcastWithError:error];

    CFNotificationCenterRef noti = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterRemoveObserver(noti, (__bridge  const void *)(self), CFSTR("app_finishBroadcast"), NULL);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark FBSocketClientManageDelegate
- (void)socketClientManage:(FBSocketClientManage *)socketManager didReceiveMessage:(NSData *)messageData head:(NTESPacketHead *)head {
    if (!messageData) { return; }
    switch (head->command_id) {
        case 1: {   //1：分辨率
            NSString *qualityStr = [NSString stringWithUTF8String:[messageData bytes]];
            int qualit = [qualityStr intValue];
            switch (qualit) {
                case 0: //标清
                    _targetSize = CGSizeMake(720, 960);
                    break;
                case 1: //高清
                    _targetSize = CGSizeMake(720, 1280);
                    break;
                case 2: //超高清
                    _targetSize = CGSizeMake(1080, 1920);
                    break;
                default:
                    break;
            }
            break;
        }
        case 2: {   //2：裁剪比例
            break;
        }
        case 3: {   //3：视频方向
            NSString *orientationStr = [NSString stringWithUTF8String:[messageData bytes]];
            int orient = [orientationStr intValue];
            switch (orient) {
                case 0:
                    _orientation = NTESVideoPackOrientationPortrait;
                    break;
                case 1:
                    _orientation = NTESVideoPackOrientationLandscapeLeft;
                    break;
                case 2:
                    _orientation = NTESVideoPackOrientationPortraitUpsideDown;
                    break;
                case 3:
                    _orientation = NTESVideoPackOrientationLandscapeRight;
                    break;
                default:
                    break;
            };
            break;
        }
        default: {
            break;
        }
    }
}

@end
