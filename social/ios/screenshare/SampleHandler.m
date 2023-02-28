//
//  SampleHandler.m
//  FBScreenShareExtention
//
//  Created by Patrick Fu on 2020/10/26.
//

#import "SampleHandler.h"
#import "ZGScreenCaptureManager.h"
#import "FBScreenCaptureManager.h"

@interface SampleHandler ()
{
    BOOL    _isFanbookScreen;    //是否为自研屏幕共享功能
}

@end

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.idreamsky.buff"];
    NSDictionary *dataDic = [userDefaults objectForKey:@"FB_KEY_BXL_DEFAULT_SCREEN_TYPE"];
    BOOL needWait = NO;
    if (!dataDic || ![dataDic objectForKey:@"screenType"]) {
        needWait = YES;
        //发送通知，获取screenType
        [self registerNotificationsWithIdentifier:@"fb_FanbookScreen"];
        [self sendNotificationWithIdentifier:@"fb_broadcastStartedWithSetupInfo"];
    } else {
        needWait = NO;
        NSString *typeStr = [dataDic objectForKey:@"screenType"];
        _isFanbookScreen = [typeStr isEqualToString:@"Fanbook"] ? YES : NO;
    }
   
    // Note:
    // If you want to experience this feature, please click the [Runner] project in the project
    // navigator on the left of Xcode, find the [App Groups] column in the [Signing & Capabilities] tab of
    // both Target [Runner] and [FBScreenShareExtention], click the `+` to add a custom
    // App Group ID and enable it; then fill in this App Group ID to below
    //
    // This demo has encapsulated the logic of calling the ZegoExpressEngine SDK in the [ZGScreenCaptureManager] class.
    // Please refer to it to implement [SampleHandler] class in your own project
    //
    //
    // 注意：
    // 若需要体验此功能，请点击 Xcode 左侧项目导航栏中的 [Runner] 工程项目，
    // 找到 Target [Runner] 以及 [FBScreenShareExtention] 的
    // [Signing & Capabilities] 选项中的 App Groups 栏目，点击 `+` 号添加一个您自定义的 App Group ID 并启用；
    // 然后将此 ID 填写到下面替换
    //
    // 本 Demo 已将调用 ZegoExpressEngine SDK 的逻辑都封装在了 [ZGScreenCaptureManager] 类中
    // 请参考该类以在您自己的项目中实现 [SampleHandler]
    
    if (needWait) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startBroadcast];
        });
    } else {
        [self startBroadcast];
    }
}

- (void)startBroadcast {
    if (_isFanbookScreen) {
        [[FBScreenCaptureManager sharedManager] startBroadcastWithAppGroup:@"group.com.idreamsky.buff" sampleHandler:self];
    } else {
        [[ZGScreenCaptureManager sharedManager] startBroadcastWithAppGroup:@"group.com.idreamsky.buff" sampleHandler:self];
    }
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
    if (_isFanbookScreen) {
        [[FBScreenCaptureManager sharedManager] sendNotificationWithIdentifier:@"fb_broadcastPaused"];
    }
}

- (void)broadcastResumed {
    if (_isFanbookScreen) {
        [[FBScreenCaptureManager sharedManager] sendNotificationWithIdentifier:@"fb_broadcastResumed"];
    }
}

- (void)broadcastFinished {
    if (_isFanbookScreen) {
        [[FBScreenCaptureManager sharedManager] sendNotificationWithIdentifier:@"fb_broadcastFinished"];
    } else {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"ZGFinishBroadcastUploadExtensionProcessENDNotification", NULL, nil, YES);

        NSLog(@"自己打印 ==> broadcastFinished ==> 外面提示结束");

        // User has requested to finish the broadcast.
        [[ZGScreenCaptureManager sharedManager] stopBroadcast:nil];
    }
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    if (_isFanbookScreen) {
        [[FBScreenCaptureManager sharedManager] handleSampleBuffer:sampleBuffer withType:sampleBufferType];
    } else {
        [[ZGScreenCaptureManager sharedManager] handleSampleBuffer:sampleBuffer withType:sampleBufferType];
    }
}


#pragma mark 通知的处理
//发通知
- (void)sendNotificationWithIdentifier:(nullable NSString *)identifier {
    CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
    BOOL const deliverImmediately = YES;
    CFStringRef identifierRef = (__bridge CFStringRef)identifier;
    CFNotificationCenterPostNotification(center, identifierRef, NULL, NULL, deliverImmediately);
}

//注册通知
- (void)registerNotificationsWithIdentifier:(nullable NSString *)identifier {
    if (identifier.length == 0) {
        return;
    }
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(self),
                                    fb_appNotificationCallback,
                                    (CFStringRef)identifier,
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
}

void fb_appNotificationCallback(CFNotificationCenterRef center,
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
    if ([identifier isEqualToString:@"fb_FanbookScreen"]) {
        _isFanbookScreen = YES;
    }
}

@end
