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

//Unity??????
- (void)Unity_active {
    [AVAudioSession sharedInstance].isUnityActive = true;
}

//Unity?????????
- (void)Unity_inactive {
    [AVAudioSession sharedInstance].isUnityActive = false;
}

//webRTC?????????
- (void)WebRTC_Initialize {
    //????????????AVAudioSession???Category???categoryOptions
    [FBAudioSessionCacheManager cacheCurrentAudioSession];
    //?????????????????????
    [AVAudioSession sharedInstance].type = AVAudioSessionTypeCall;
}

- (void)WebRTC_deInitialize {
    //?????????????????????
    [AVAudioSession sharedInstance].type = AVAudioSessionTypeNormal;
    //???????????????AVAudioSession???Category???categoryOptions
    [FBAudioSessionCacheManager resetToCachedAudioSession];
}

- (void)configNav {
    //??????Navbar????????????
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance setBackgroundColor:[UIColor whiteColor]];
        appearance.titleTextAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:18.0f weight:UIFontWeightSemibold],NSForegroundColorAttributeName: [UIColor blackColor]};
        [[UINavigationBar appearance] setScrollEdgeAppearance: appearance];
        [[UINavigationBar appearance] setStandardAppearance:appearance];
    }
}

//????????????????????????????????????
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler{
    //??????????????????OpenInstall Universal Link ??????App
    NSString *webpageURL = userActivity.webpageURL.absoluteString;
    if ([webpageURL containsString:@"wx5a6ce7e89c14128d"]) {
        return [super application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
    }
    if ([OpeninstallFlutterPlugin continueUserActivity:userActivity]){
        return YES;
    }
    //????????????????????????
    return YES;
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity  API_AVAILABLE(ios(13.0)){
    [WXApi handleOpenUniversalLink:userActivity delegate:self];
}

//??????????????????iOS??????
-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    // wx
    if ([url.absoluteString containsString:@"wx5a6ce7e89c14128d"]) {
        return [WXApi handleOpenURL:url delegate:self];
    }
    //????????????????????????
    return [super application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

//iOS9?????????????????????????????????
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(nonnull NSDictionary *)options{
    //??????????????????OpenInstall URL Scheme ??????App
    if ([url.absoluteString containsString:@"wx5a6ce7e89c14128d"]) {
        return [WXApi handleOpenURL:url delegate:self];
    }
    //????????????????????????
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
                //?????????????????????
                
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
    
    //WebRtc???????????????????????????????????????????????????????????????????????????????????????????????????????????????AudioSession
    if ([AVAudioSession sharedInstance].type == AVAudioSessionTypeCall) {
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    signal(SIGPIPE, SIG_IGN);
}


// ????????????
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
    NSLog(@"?????????????????????");
    [self postNotificaiton];
    
    //??????????????????????????????????????????????????????????????????App,?????????????????????????????????????????????
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.idreamsky.buff"];
    [userDefaults setObject:@{@"fb_finished": @(YES)} forKey:@"FB_KEY_BXL_DEFAULT_SCREEN_STATE"];
    [userDefaults synchronize];
}

- (void)postNotificaiton {
    CFNotificationCenterRef notification = CFNotificationCenterGetDarwinNotifyCenter ();
    CFNotificationCenterPostNotification(notification, CFSTR("applicationWillTerminate"), NULL,NULL, YES);
}

@end
