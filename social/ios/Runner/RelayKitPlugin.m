//
//  RelayKitPlugin.m
//  Runner
//
//  Created by red on 2021/12/11.
//

#import "RelayKitPlugin.h"

@implementation RelayKitPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"com.nativeToFlutter" binaryMessenger:[registrar messenger]];
    RelayKitPlugin* instance = [[RelayKitPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    instance.channel = channel;
}

- (void)NotificationAction:(NSNotification *)noti {

   NSError *err = nil;
    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.idreamsky.buff"];
    containerURL = [containerURL URLByAppendingPathComponent:@"Library/Caches/data"];
    NSString *value = [NSString stringWithContentsOfURL:containerURL encoding:NSUTF8StringEncoding error:&err];

    if (err != nil) {
         NSLog(@"xxxx %@",err);
        return;
    }

    [self.channel invokeMethod:@"GroupDataFlutter" arguments:value];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([call.method isEqualToString:@"stopGetData"]) {
        NSLog(@"ios -- 移除 GetGroupData 通知");
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"GetGroupData" object:nil];
    } else if ([call.method isEqualToString:@"startGetData"]) {
        NSLog(@"ios -- 监听 GetGroupData 通知");
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(NotificationAction:) name:@"GetGroupData" object:nil];
    }
}
@end
