//
//  AVAudioSession+FBExtension.m
//  Runner
//
//  Created by jason.duan on 2022/2/24.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "AVAudioSession+FBExtension.h"
#import <objc/runtime.h>

#define kAVAudioSessionTypeKey @"kAVAudioSessionTypeKey"
#define kAVAudioSessionSpeakerOnKey @"kAVAudioSessionSpeakerOnKey"
#define kAVAudioSessionIsUnityActiveKey @"kAVAudioSessionIsUnityActiveKey"


@implementation AVAudioSession (FBExtension)

+ (void)load {
    [self swizzleInstanceMethod:@selector(setCategory:error:) with:@selector(fb_setCategory:error:)];

    [self swizzleInstanceMethod:@selector(setCategory:withOptions:error:) with:@selector(fb_setCategory:withOptions:error:)];

    [self swizzleInstanceMethod:@selector(setCategory:mode:options:error:) with:@selector(fb_setCategory:model:options:error:)];

    [self swizzleInstanceMethod:@selector(setCategory:mode:routeSharingPolicy:options:error:) with:@selector(fb_setCategory:model:routeSharingPolicy:options:error:)];

    [self swizzleInstanceMethod:@selector(setMode:error:) with:@selector(fb_setMode:error:)];

    [self swizzleInstanceMethod:@selector(setActive:error:) with:@selector(fb_setActive:error:)];

    [self swizzleInstanceMethod:@selector(setActive:withOptions:error:) with:@selector(fb_setActive:withOptions:error:)];
}

+ (void)swizzleInstanceMethod:(SEL)originalSel with:(SEL)swizzledSel {
    /**
     hook：钩子函数；
     "class_getInstanceMethod"方法的第一个参数不一定要写self，要看实际上是什么类型。比如NSMutableArray类的实例对象，它的实际类型不是NSMutableArray而是"__NSArrayM"。这种表面上是一种类型，而实际上是另外一种类型的类叫做“类簇”。NSString、NSArray、NSDictionary，都是类簇，他们的真实类型是其他类型。
     */
    Method originalMethod = class_getInstanceMethod(self, originalSel);
    Method swizzledMethod = class_getInstanceMethod(self, swizzledSel);
    
    BOOL didAddMethod =
    class_addMethod(self,
                    originalSel,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(self,
                            swizzledSel,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (BOOL)fb_setActive:(BOOL)active error:(NSError **)outError {
    if([self isUnityActive] && !active)
    {
        return NO;
    }
    
    BOOL isSucess = [self fb_setActive:active error:outError];
    return isSucess;
}

- (BOOL)fb_setActive:(BOOL)active withOptions:(AVAudioSessionSetActiveOptions)options error:(NSError **)outError {
    if([self isUnityActive] && !active)
    {
        return NO;
    }
    
    BOOL isSucess = [self fb_setActive:active withOptions:options error:outError];
    return isSucess;
}

- (BOOL)fb_setMode:(AVAudioSessionMode)mode error:(NSError **)outError {
    return [self fb_setMode:mode error:outError];
}

- (BOOL)fb_setCategory:(AVAudioSessionCategory)category model:(AVAudioSessionMode)model routeSharingPolicy:(AVAudioSessionRouteSharingPolicy)routeSharingPolicy options:(AVAudioSessionCategoryOptions)options error:(NSError **)outError {
    if (self.type == AVAudioSessionTypeCall) {   //webrtc通话中
        BOOL shouldFixMixWithOthers = [self shouldFixMixWithOthers];
        BOOL isPlayAndRecordCategory = [[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayAndRecord];
        if (isPlayAndRecordCategory && !shouldFixMixWithOthers) {
            //如果当前category==AVAudioSessionCategoryPlayAndRecord  categoryOptions 已经包含混音了，就不用重新设置
            return YES;
        } else {
            //在需要进行对audioSession进行修正的场景下（RTC直播），修改options时未包含mixWithOther，则给options追加mixWithOther
            return [self fb_setCategory:AVAudioSessionCategoryPlayAndRecord model:AVAudioSessionModeVideoChat routeSharingPolicy:routeSharingPolicy options:options | AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP | AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDuckOthers error:outError];
        }
    }
    
    return [self fb_setCategory:category model:model routeSharingPolicy:routeSharingPolicy options:options error:outError];
}

- (BOOL)fb_setCategory:(AVAudioSessionCategory)category model:(AVAudioSessionMode)model options:(AVAudioSessionCategoryOptions)options error:(NSError **)outError {
    if (self.type == AVAudioSessionTypeCall) {   //webrtc通话中
        BOOL shouldFixMixWithOthers = [self shouldFixMixWithOthers];
        BOOL isPlayAndRecordCategory = [[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayAndRecord];
        if (isPlayAndRecordCategory && !shouldFixMixWithOthers) {
            //如果当前category==AVAudioSessionCategoryPlayAndRecord  categoryOptions 已经包含混音了，就不用重新设置
            return YES;
        } else {
            //在需要进行对audioSession进行修正的场景下（RTC直播），修改options时未包含mixWithOther，则给options追加mixWithOther
            return [self fb_setCategory:AVAudioSessionCategoryPlayAndRecord model:AVAudioSessionModeVideoChat options:options | AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP | AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDuckOthers error:outError];
        }
    }
    
    return [self fb_setCategory:category model:model options:options error:outError];
}

- (BOOL)fb_setCategory:(AVAudioSessionCategory)category withOptions:(AVAudioSessionCategoryOptions)options error:(NSError **)outError {
    if (self.type == AVAudioSessionTypeCall) {   //webrtc通话中
        BOOL shouldFixMixWithOthers = [self shouldFixMixWithOthers];
        BOOL isPlayAndRecordCategory = [[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayAndRecord];
        if (isPlayAndRecordCategory && !shouldFixMixWithOthers) {
            //如果当前category==AVAudioSessionCategoryPlayAndRecord  categoryOptions 已经包含混音了，就不用重新设置
            return YES;
        } else {
            //在需要进行对audioSession进行修正的场景下（RTC直播），修改options时未包含mixWithOther，则给options追加mixWithOther
            return [self fb_setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:options | AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP | AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDuckOthers error:outError];
        }
    }

    return [self fb_setCategory:category withOptions:options error:outError];
}

- (BOOL)fb_setCategory:(AVAudioSessionCategory)category error:(NSError **)outError {
    if (self.type == AVAudioSessionTypeCall) {   //webrtc通话中
        BOOL isPlayAndRecordCategory = [[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayAndRecord];
        if (isPlayAndRecordCategory) {
            //如果当前category==AVAudioSessionCategoryPlayAndRecord就不用重新设置
            return YES;
        } else {
            //这里设置两次setCategory: 是为了解决iOS14.0以下系统会造成循环调用的问题。
            BOOL isSucess1 = [self fb_setCategory:AVAudioSessionCategoryPlayAndRecord error:outError];
            //在需要进行对audioSession进行修正的场景下（RTC直播），修改options时未包含mixWithOther，则给options追加mixWithOther
            BOOL isSucess2 = YES;
            BOOL shouldFixMixWithOthers = [self shouldFixMixWithOthers];
            if (shouldFixMixWithOthers) {
                isSucess2 = [self fb_setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:[AVAudioSession sharedInstance].categoryOptions | AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP | AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDuckOthers error:outError];
            }
            
            return isSucess1 && isSucess2;
        }
    }

    return [self fb_setCategory:category error:outError];
}

/*!
 *  是否需要添加混音支持
 */
- (BOOL)shouldFixMixWithOthers {
    BOOL isMixWithOther = [AVAudioSession sharedInstance].categoryOptions & AVAudioSessionCategoryOptionMixWithOthers;
    BOOL isDuckOthers = [AVAudioSession sharedInstance].categoryOptions & AVAudioSessionCategoryOptionDuckOthers;
    return !(isMixWithOther && isDuckOthers);
}

///*!
// *  支持添加混音的category
// */
//- (BOOL)shouldFixAudioSession:(AVAudioSessionCategory)category {
//    return [category isEqualToString:AVAudioSessionCategoryPlayAndRecord] || [category isEqualToString:AVAudioSessionCategoryPlayback] || [category isEqualToString:AVAudioSessionCategoryMultiRoute];
//}


#pragma mark 属性设置

/*!
 *  设置Unity激活状态
 */
- (void)setIsUnityActive:(BOOL)isUnityActive {
    objc_setAssociatedObject(self, kAVAudioSessionIsUnityActiveKey, @(isUnityActive), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

/*!
 *   获取Unity激活状态
 */
- (BOOL)isUnityActive {
    return [objc_getAssociatedObject(self, kAVAudioSessionIsUnityActiveKey) boolValue];
}

/*!
 *  设置音频场景类型
 */
- (void)setType:(AVAudioSessionType)type {
    objc_setAssociatedObject(self, kAVAudioSessionTypeKey, @(type), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    //通话模式默认开启扬声器
    if(type == AVAudioSessionTypeCall) {
        self.speakerOn = YES;
    }
}

/*!
 *  获取当前音频场景类型
 */
- (AVAudioSessionType)type {
    return [objc_getAssociatedObject(self, kAVAudioSessionTypeKey) intValue];
}

/*!
 *  设置扬声器
 */
- (void)setSpeakerOn:(BOOL)speakerOn {
    objc_setAssociatedObject(self, kAVAudioSessionSpeakerOnKey, @(speakerOn), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/*!
 *  获取扬声器状态
 */
- (BOOL)speakerOn {
    return [objc_getAssociatedObject(self, kAVAudioSessionSpeakerOnKey) boolValue];
}

#pragma mark AudioSession监听通知
/*!
 *  开启SessionRoute的监听
 */
- (void)enableSessionRouteNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
}

/*!
 *  关闭SessionRoute的监听
 */
- (void)colseSessionRouteNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
}


- (void)didSessionRouteChange:(NSNotification *)aNotification {
    NSDictionary *info = aNotification.userInfo;
    AVAudioSessionRouteChangeReason reason = [info[AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue];
    switch (reason) {
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable: {
            if (self.type == AVAudioSessionTypeCall) {
                //旧设备断开后，恢复到连接前的输出类型
                NSError* error;
                [[AVAudioSession sharedInstance] overrideOutputAudioPort:self.speakerOn? AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone error:&error];
            }

            break;
        }
        case AVAudioSessionRouteChangeReasonCategoryChange:
        case AVAudioSessionRouteChangeReasonOverride: {
            if (self.type == AVAudioSessionTypeCall) {
                //记录当前路由音频输出类型
                AVAudioSessionRouteDescription *currentRoute = [AVAudioSession sharedInstance].currentRoute;
                if(currentRoute.outputs.count > 0) {
                    AVAudioSessionPortDescription *currentOutput = currentRoute.outputs[0];
                    NSString *portType = currentOutput.portType;
                    if ([portType isEqualToString:@"Speaker"]) {
                        self.speakerOn = YES;
                    } else if ([portType isEqualToString:@"Receiver"]) {
                        self.speakerOn = NO;
                    }
                }
            }
            break;
        }
        default:
            break;
    }

}

//- (void)setPreferHeadphoneInput {
//    #if TARGET_OS_IPHONE
//    AVAudioSession *session = [AVAudioSession sharedInstance];
//    AVAudioSessionPortDescription *inputPort = nil;
//    for (AVAudioSessionPortDescription *port in session.availableInputs) {
//        if ([port.portType isEqualToString:AVAudioSessionPortHeadphones]) {
//            inputPort = port;
//            break;
//        }
//    }
//    if (inputPort != nil) {
//        [session setPreferredInput:inputPort error:nil];
//    }
//    #endif
//}

@end
