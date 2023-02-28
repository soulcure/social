#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import "WXApi.h"
#import <openinstall_flutter_plugin/OpeninstallFlutterPlugin.h>
//#import <fluwx/FluwxResponseHandler.h>
//#import <WebRTC/RTCLogging.h>
#import <AVFoundation/AVFoundation.h>
#import "RelayKitPlugin.h"
#import <objc/runtime.h>
#import "FBAudioSessionCacheManager.h"
#import "AVAudioSession+FBExtension.h"

@implementation AppDelegate 

+ (void)load {
    SEL newSelector = @selector(new_addObserver:selector:name:object:);
    Method backMehtod = class_getInstanceMethod([NSNotificationCenter class], @selector(addObserver:selector:name:object:));
    Method newMethod = class_getInstanceMethod([self class], newSelector);
    class_addMethod([NSNotificationCenter class], newSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
    method_exchangeImplementations(backMehtod, class_getInstanceMethod([NSNotificationCenter class], newSelector));
}

- (void) new_addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSNotificationName)aName object:(nullable id)anObject {
    if (aName == AVAudioSessionRouteChangeNotification) {
        [[NSNotificationCenter defaultCenter] addObserverForName:aName object:anObject queue: [[NSOperationQueue alloc] init] usingBlock:^(NSNotification * _Nonnull note) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [observer performSelector:aSelector withObject:note];
            });
        }];
        return;
    }
    [self new_addObserver:observer selector:aSelector name:aName object:anObject];
}

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    [RelayKitPlugin registerWithRegistrar:[self registrarForPlugin:@"RelayKitPlugin"]];
    [self receiveNotification];
    
//    RTCSetMinDebugLogLevel(RTCLoggingSeverityInfo);
    FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;
    FlutterMethodChannel* socialChannel = [FlutterMethodChannel methodChannelWithName:@"buff.com/social" binaryMessenger:controller];
    [socialChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
        if ([@"acquireWakeLock" isEqualToString:call.method]) {
            [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
            result(nil);
        }else if([@"releaseWakeLock" isEqualToString:call.method]) {
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            result(nil);
        }
    }];
    
    [QiAudioPlayer sharedInstance];
    [self configNav];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WebRTC_Initialize) name:@"WebRTC_Initialize" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WebRTC_deInitialize) name:@"WebRTC_deInitialize" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(Unity_active) name:@"Unity_active" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(Unity_inactive) name:@"Unity_inactive" object:nil];
    [[AVAudioSession sharedInstance] enableSessionRouteNotification];
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

//Unity活跃
- (void)Unity_active {
    [AVAudioSession sharedInstance].isUnityActive = true;
}

//Unity不活跃
- (void)Unity_inactive {
    [AVAudioSession sharedInstance].isUnityActive = false;
}

//webRTC初始化
- (void)WebRTC_Initialize {
    //保存当前AVAudioSession的Category和categoryOptions
    [FBAudioSessionCacheManager cacheCurrentAudioSession];
    //设置为通话模式
    [AVAudioSession sharedInstance].type = AVAudioSessionTypeCall;
}

- (void)WebRTC_deInitialize {
    //设置为正常模式
    [AVAudioSession sharedInstance].type = AVAudioSessionTypeNormal;
    //恢复通话前AVAudioSession的Category和categoryOptions
    [FBAudioSessionCacheManager resetToCachedAudioSession];
}

- (void)configNav {
    //设置Navbar的背景色
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance setBackgroundColor:[UIColor whiteColor]];
        appearance.titleTextAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:18.0f weight:UIFontWeightSemibold],NSForegroundColorAttributeName: [UIColor blackColor]};
        [[UINavigationBar appearance] setScrollEdgeAppearance: appearance];
        [[UINavigationBar appearance] setStandardAppearance:appearance];
    }
}

//添加此方法以获取拉起参数
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler{
    //判断是否通过OpenInstall Universal Link 唤起App
    NSString *webpageURL = userActivity.webpageURL.absoluteString;
    if ([webpageURL containsString:@"wx5a6ce7e89c14128d"]) {
        return [super application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
    }
    if ([OpeninstallFlutterPlugin continueUserActivity:userActivity]){
        return YES;
    }
    //其他第三方回调；
    return YES;
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity  API_AVAILABLE(ios(13.0)){
    [WXApi handleOpenUniversalLink:userActivity delegate:self];
}

//适用目前所有iOS版本
-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    // wx
    if ([url.absoluteString containsString:@"wx5a6ce7e89c14128d"]) {
        return [WXApi handleOpenURL:url delegate:self];
    }
    //其他第三方回调；
    return [super application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

//iOS9以上，会优先走这个方法
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(nonnull NSDictionary *)options{
    //判断是否通过OpenInstall URL Scheme 唤起App
    if ([url.absoluteString containsString:@"wx5a6ce7e89c14128d"]) {
        return [WXApi handleOpenURL:url delegate:self];
    }
    //其他第三方回调；
    return [super application:app openURL:url options:options];
}

//- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
//    return UIInterfaceOrientationMaskPortrait;
//}

- (void) onReq:(BaseReq*)reqonReq{
    
}

- (void) onResp:(BaseResp*)resp {
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    _backgroundId = [[NSUUID UUID] UUIDString];
    __block NSString *backgroundId = _backgroundId;
    __weak typeof(self) ws = self;
    __block UIApplication *block_application = application;
    __block UIBackgroundTaskIdentifier backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
        if (ws != nil) {
            FlutterViewController* controller = (FlutterViewController*)ws.window.rootViewController;
            FlutterMethodChannel* wsChannel = [FlutterMethodChannel methodChannelWithName:@"buff.com/ws" binaryMessenger:controller];
            [wsChannel invokeMethod:@"ws_close" arguments:nil];
        }
        [block_application endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int i = 0;
        while (i <= 2400 && [self->_backgroundId isEqualToString:backgroundId]) {
            sleep(5);
            i += 5;
        }
        [block_application endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
    });
    @try {
        FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;
        __block FlutterMethodChannel* rtcChannel = [FlutterMethodChannel methodChannelWithName:@"buff.com/rtc" binaryMessenger:controller];
        [rtcChannel invokeMethod:@"mediaStreamState" arguments:nil result:^(id  _Nullable result) {
            if (result && [result isKindOfClass:[NSDictionary class]] && [[result valueForKey:@"state"] isEqualToString:@"open"]) {
                //开启音视频通话
                
            }else {
                [[QiAudioPlayer sharedInstance] resumePlay];
            }
            
            [rtcChannel invokeMethod:@"QiAudioPlayerState" arguments:@{@"isPlay" : @([QiAudioPlayer sharedInstance].player.isPlaying), @"mediaState" : result}];
        }];
    } @catch (NSException *exception) {
        
    }
    
    signal(SIGPIPE, SIG_IGN);
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    _backgroundId = @"";
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;
        FlutterMethodChannel* wsChannel = [FlutterMethodChannel methodChannelWithName:@"buff.com/ws" binaryMessenger:controller];
        [wsChannel invokeMethod:@"ws_reconnect" arguments:nil];
    });
    [[QiAudioPlayer sharedInstance] stopPlay];
    
    //WebRtc通话时，中途接听电话后，有一定机率收不到中断结束的通知，所以在这里重新激活AudioSession
    if ([AVAudioSession sharedInstance].type == AVAudioSessionTypeCall) {
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    signal(SIGPIPE, SIG_IGN);
}


// 接收通知
- (void)receiveNotification {

    CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
    CFStringRef identifierRef = (__bridge CFStringRef)@"DeviceOrientation";
    CFNotificationCenterAddObserver(center,
                                       (__bridge const void *)(self),
                                        NotificationCallback,
                                        identifierRef,
                                       NULL,
                                       CFNotificationSuspensionBehaviorDeliverImmediately);
}

void NotificationCallback(CFNotificationCenterRef center,
                                   void * observer,
                                   CFStringRef name,
                                   void const * object,
                                   CFDictionaryRef userInfo) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GetGroupData" object:nil];
}

-(void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"应用程序被杀死");
    [self postNotificaiton];
    
    //为了防止屏幕共享扩展还没初始化，用户就杀掉了App,这里存个标记，用来给扩展端使用
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.idreamsky.buff"];
    [userDefaults setObject:@{@"fb_finished": @(YES)} forKey:@"FB_KEY_BXL_DEFAULT_SCREEN_STATE"];
    [userDefaults synchronize];
}

- (void)postNotificaiton {
    CFNotificationCenterRef notification = CFNotificationCenterGetDarwinNotifyCenter ();
    CFNotificationCenterPostNotification(notification, CFSTR("applicationWillTerminate"), NULL,NULL, YES);
}

@end
