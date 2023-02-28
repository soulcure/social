#import "ReplayKitLauncherPlugin.h"
#import <ReplayKit/ReplayKit.h>


//#define ZG_NOTIFICATION_END_NAME @"ZGFinishBroadcastUploadExtensionProcessENDNotification"
#define PwdKey @"pwd"


@interface ReplayKitLauncherPlugin()<FlutterStreamHandler>
//@property FlutterEventSink eventSinkAction;
@end


@implementation ReplayKitLauncherPlugin
{
    FlutterEventSink eventSinkAction;
}

static ReplayKitLauncherPlugin* _instance = nil;
 
+(instancetype) shareInstance
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init] ;
    }) ;
    
    return _instance ;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    
      ReplayKitLauncherPlugin* instance = [[ReplayKitLauncherPlugin alloc] init];
    
      FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"replay_kit_launcher" binaryMessenger:[registrar messenger]];
    //设置消息处理器的代理
      [registrar addMethodCallDelegate:instance channel:channel];
    
    FlutterEventChannel* chargingChannel =
        [FlutterEventChannel eventChannelWithName:@"plugins.flutter.io/charging"
                                  binaryMessenger:[registrar messenger]];
    [chargingChannel setStreamHandler:instance];
    
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {

    
    if ([@"launchReplayKitBroadcast" isEqualToString:call.method]) {

        
        // Add an observer for stop broadcast notification
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        (__bridge const void *)(self),
                                        onBroadcastFinish,
                                        (CFStringRef)@"ZGFinishBroadcastUploadExtensionProcessENDNotification",
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
        
        //这样正常
//        [self notificationCallbackReceivedWithName:@"不单例正常"];
        
        //单例的就不正常【如测试正常情况注释我】
//        [[ReplayKitLauncherPlugin shareInstance] notificationCallbackReceivedWithName:@"发送事件-单例不正常"];
        
        
        [self launchReplayKitBroadcast:call.arguments[@"extensionName"] result:result];
        
    } else if ([@"isScrren" isEqualToString:call.method]) {
        UIScreen *mainScreen = [UIScreen mainScreen];
                if (@available(iOS 11.0, *)) {
                    //result(@(mainScreen.isCaptured));
                    if (mainScreen.isCaptured) {
                        if(eventSinkAction!=NULL)eventSinkAction(@"ScreenOpened");
                    } else {
                        if(eventSinkAction!=NULL)eventSinkAction(@"ScreenClosed");
                    }
                }
        
    }else if ([@"finishReplayKitBroadcast" isEqualToString:call.method]) {

        NSString *notificationName = call.arguments[@"notificationName"];
        
        NSLog(@"自己打印 ==> finishReplayKitBroadcast ==> %@",notificationName);
        
        
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)notificationName, NULL, nil, YES);
        
        result(@(YES));

    } else {
        result(FlutterMethodNotImplemented);
    }
}


//- (void)notificationCallbackReceivedWithName:(NSString *)name {
//
//    eventSinkAction(name);
//}



- (void)isScreen:(NSString *)name {
    
    UIScreen *mainScreen = [UIScreen mainScreen];
            if (@available(iOS 11.0, *)) {
                if (mainScreen.isCaptured) {
                    eventSinkAction(@"isCaptured");
                } else {
                    eventSinkAction(@"isCaptured 没有");
                }
            }

}


#pragma mark - Finish broadcast function

// Handle stop broadcast notification from main app process
void onBroadcastFinish(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    
                
    NSLog(@"监听到的 ==> onBroadcastFinish ==> IOS端");

//    [[ReplayKitLauncherPlugin shareInstance].eventSinkAction:@""];
//    [[ReplayKitLauncherPlugin shareInstance] notificationCallbackReceivedWithName:@"发送事件"];
//    eventSinkAction(@"launchReplayKitBroadcast");

    // Remove observer for stop broadcast notification
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                       NULL,//(__bridge const void *)(self)
                                       (CFStringRef)@"ZGFinishBroadcastUploadExtensionProcessENDNotification",
                                       NULL);
}


- (void)launchReplayKitBroadcast:(NSString *)extensionName result:(FlutterResult)result {
    if (@available(iOS 12.0, *)) {
        RPSystemBroadcastPickerView *broadcastPickerView = [[RPSystemBroadcastPickerView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:extensionName ofType:@"appex" inDirectory:@"PlugIns"];
        if (!bundlePath) {
            NSString *nullBundlePathErrorMessage = [NSString stringWithFormat:@"Can not find path for bundle `%@.appex`", extensionName];
            NSLog(@"%@", nullBundlePathErrorMessage);
            result([FlutterError errorWithCode:@"NULL_BUNDLE_PATH" message:nullBundlePathErrorMessage details:nil]);
            return;
        }

        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        if (!bundle) {
            NSString *nullBundleErrorMessage = [NSString stringWithFormat:@"Can not find bundle at path: `%@`", bundlePath];
            NSLog(@"%@", nullBundleErrorMessage);
            result([FlutterError errorWithCode:@"NULL_BUNDLE" message:nullBundleErrorMessage details:nil]);
            return;
        }

        broadcastPickerView.preferredExtension = bundle.bundleIdentifier;
        
        if (![UIScreen mainScreen].isCaptured) {
            NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.idreamsky.buff"];
            [userDefaults setObject:@{@"screenType": @"none"} forKey:@"FB_KEY_BXL_DEFAULT_SCREEN_TYPE"];
            [userDefaults synchronize];
        }

        // Traverse the subviews to find the button to skip the step of clicking the system view

        // This solution is not officially recommended by Apple, and may be invalid in future system updates

        // The safe solution is to directly add RPSystemBroadcastPickerView as subView to your view

        for (UIView *subView in broadcastPickerView.subviews) {
            if ([subView isMemberOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)subView;
                [button sendActionsForControlEvents:UIControlEventAllEvents];
            }
        }
        result(@(YES));

    } else {
        NSString *notAvailiableMessage = @"RPSystemBroadcastPickerView is only available on iOS 12.0 or above";
        NSLog(@"%@", notAvailiableMessage);
        result([FlutterError errorWithCode:@"NOT_AVAILIABLE" message:notAvailiableMessage details:nil]);
    }

}

- (void)clickButtonEvent:(UIButton *)sender
{
     NSLog(@"不用点我，我自己来！！！");
}

#pragma mark FlutterStreamHandler impl

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    NSLog(@"onListenWithArguments");
    eventSinkAction = eventSink;
//  [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
//  [self sendBatteryStateEvent];
//  [[NSNotificationCenter defaultCenter] addObserver:self
//                                           selector:@selector(onBatteryStateDidChange:)
//                                               name:UIDeviceBatteryStateDidChangeNotification
//                                             object:nil];
  return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
//  [[NSNotificationCenter defaultCenter] removeObserver:self];
    eventSinkAction = nil;
  return nil;
}

@end
