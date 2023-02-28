//
//  FBSocketClientManage.h
//  screenshare
//
//  Created by jason.duan on 2022/6/2.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTESSocketPacket.h"
#import "NTESTPCircularBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@class FBSocketClientManage;

@protocol FBSocketClientManageDelegate <NSObject>

//接收消息代理
- (void)socketClientManage:(FBSocketClientManage *)socketManager didReceiveMessage:(NSData *)messageData head:(NTESPacketHead *)head;

@end

@interface FBSocketClientManage : NSObject

@property (nonatomic, weak) id<FBSocketClientManageDelegate>        delegate;
@property (nonatomic, assign, readonly) BOOL                        connected;

//连接服务主机
- (void)connectToHost;

//断开连接
- (void)disconnect;

//发送消息
- (void)sendMessage:(NSData *)messageData timeOut:(NSUInteger)timeOut;

@end

NS_ASSUME_NONNULL_END
