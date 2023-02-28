//
//  SampleHandler.m
//  BroadcastDemoExtension
//
//  Created by Patrick Fu on 2020/10/25.
//

#import "SampleHandler.h"

#import "ZGBroadcastManager.h"

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.

    [[ZGBroadcastManager sharedManager] startBroadcast:self];
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.

    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"ZGFinishBroadcastUploadExtensionProcessENDNotification", NULL, nil, YES);

    NSLog(@"自己打印 ==> broadcastFinished ==> 外面提示结束");
    
    [[ZGBroadcastManager sharedManager] stopBroadcast];
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    
    [[ZGBroadcastManager sharedManager] handleSampleBuffer:sampleBuffer withType:sampleBufferType];
}

@end
