//
//  FBSocketClientManage.m
//  screenshare
//
//  Created by jason.duan on 2022/6/2.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#import "FBSocketClientManage.h"
#import "CocoaAsyncSocket/GCDAsyncSocket.h"

@interface FBSocketClientManage ()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket            *socket;
@property (nonatomic, assign) NTESTPCircularBuffer      *recvBuffer;
@property (nonatomic, assign) BOOL                       connected;
@end

@implementation FBSocketClientManage

- (void)connectToHost {
    _recvBuffer = (NTESTPCircularBuffer *)malloc(sizeof(NTESTPCircularBuffer)); // 需要释放
    NTESTPCircularBufferInit(_recvBuffer, kRecvBufferMaxSize);
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create("com.idreamsky.buff.webrtcReplayKit.socket", DISPATCH_QUEUE_SERIAL)];
    NSError *error;
    [self.socket connectToHost:@"127.0.0.1" onPort:8989 error:&error];
    [self.socket readDataWithTimeout:-1 tag:0];
//    NSLog(@"setupSocket:%@",error);
//    if (error == nil) {
//        NSLog(@"====开启成功");
//    } else {
//        NSLog(@"=====开启失败");
//    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToUrl:(NSURL *)url {
    [self.socket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    [self.socket readDataWithTimeout:-1 tag:0];
    self.connected = YES;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NTESTPCircularBufferProduceBytes(self.recvBuffer, data.bytes, (int32_t)data.length);
    [self handleRecvBuffer];
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    self.connected = NO;
    [self.socket disconnect];
    self.socket = nil;
    [self connectToHost];
    [self.socket readDataWithTimeout:-1 tag:0];
}

- (void)handleRecvBuffer {
    if (!self.socket) {
        return;
    }
    
    int32_t availableBytes = 0;
    void * buffer = NTESTPCircularBufferTail(self.recvBuffer, &availableBytes);
    int32_t headSize = sizeof(NTESPacketHead);
    
    if (availableBytes <= headSize) {
        return;
    }
    
    NTESPacketHead head;
    memset(&head, 0, sizeof(head));
    memcpy(&head, buffer, headSize);
    uint64_t dataLen = head.data_len;
    
    if(dataLen > availableBytes - headSize && dataLen > 0) {
        return;
    }
    
    void *data = malloc(dataLen);
    memset(data, 0, dataLen);
    memcpy(data, buffer + headSize, dataLen);
    NTESTPCircularBufferConsume(self.recvBuffer, (int32_t)(headSize+dataLen));
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(socketClientManage:didReceiveMessage:head:)]) {
        @autoreleasepool {
            [self.delegate socketClientManage:self didReceiveMessage:[NSData dataWithBytes:data length:dataLen] head:&head];
        };
    }

    free(data);
    
    if (availableBytes - headSize - dataLen >= headSize) {
        [self handleRecvBuffer];
    }
}

//发送消息
- (void)sendMessage:(NSData *)messageData timeOut:(NSUInteger)timeOut {
    [self.socket writeData:messageData withTimeout:timeOut tag:0];
}

//断开连接
- (void)disconnect {
    _connected = NO;
    [self.socket disconnect];
}

- (void)dealloc {
    _connected = NO;
    
    if (_socket) {
        [_socket disconnect];
        _socket = nil;
        NTESTPCircularBufferCleanup(_recvBuffer);
    }
}

@end
