//
//  AVAudioSession+FBExtension.h
//  Runner
//
//  Created by jason.duan on 2022/2/24.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//


NS_ASSUME_NONNULL_BEGIN

/*!
 *  音频场景类型
 */
typedef enum{
    AVAudioSessionTypeNormal = 0,            //正常模式（Category和Options可更改）
    AVAudioSessionTypeCall   = 1,            //通话模式（强制Category==AVAudioSessionCategoryPlayAndRecord, categoryOptions强制开启混音, 不可更改）
} AVAudioSessionType;

@interface AVAudioSession (FBExtension)

/*!
 *  设置音频场景类型
 */
@property (nonatomic, assign) AVAudioSessionType type;

/*!
 *  设置扬声器状态
 */
@property (nonatomic, assign) BOOL                speakerOn;

/*!
 * Unity活跃状态
 */
@property (nonatomic, assign) BOOL                isUnityActive;

/*!
 *  开启SessionRoute的监听
 */
- (void)enableSessionRouteNotification;

/*!
 *  关闭SessionRoute的监听
 */
- (void)colseSessionRouteNotification;

@end

NS_ASSUME_NONNULL_END
