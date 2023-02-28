//
//  FBScreenCaptureManager.h
//  webrtcReplayKit
//
//  Created by jason.duan on 2022/5/11.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBScreenCaptureManager : NSObject

+ (FBScreenCaptureManager *)sharedManager;

- (void)startBroadcastWithAppGroup:(NSString *)appGroup sampleHandler:(RPBroadcastSampleHandler *)sampleHandler;

- (void)handleSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType;

- (void)sendNotificationWithIdentifier:(nullable NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
