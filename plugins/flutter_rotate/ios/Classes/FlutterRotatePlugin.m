#import "FlutterRotatePlugin.h"

@interface FlutterRotatePlugin()

@property (strong,nonatomic) id observer1;
@property (strong,nonatomic) id observer2;

@end

@implementation FlutterRotatePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_rotate"
            binaryMessenger:[registrar messenger]];
  FlutterRotatePlugin* instance = [[FlutterRotatePlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

// 切换横屏
- (void)changeHorizontal {

        UIView *view= [UIApplication sharedApplication].keyWindow.rootViewController.view;
        CGSize size=view.frame.size;
        UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
        NSLog(@"UIDeviceOrientation:%ld", (long)deviceOrientation);
        // 横向
            if(size.height>size.width){
                view.frame=CGRectMake(0, 0, size.height, size.width);
                [view sizeToFit];
            }


}

// 切换竖屏
- (void)changeVertical {

        UIView *view= [UIApplication sharedApplication].keyWindow.rootViewController.view;
        CGSize size=view.frame.size;
        UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
        NSLog(@"UIDeviceOrientation:%ld", (long)deviceOrientation);
        // 竖屏
            if(size.width>size.height){
                view.frame=CGRectMake(0, 0, size.height, size.width);
                [view sizeToFit];
            }

}

// 注销监听
- (void)unreg {
    if (self.observer1) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.observer1];
        self.observer1=nil;

    }
    if (self.observer2) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.observer2];
        self.observer2=nil;
    }
}

// 注册监听
- (void)reg {
    // 检测是否需要移除监听
    if (self.observer1||self.observer2) {
        [self unreg];
    }
    // 添加监听
    self.observer1=[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillChangeStatusBarOrientationNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSLog(@"UIApplicationWillChangeStatusBarOrientationNotification:%@", note);
        [UIApplication sharedApplication].keyWindow.rootViewController.view.autoresizingMask=UIViewAutoresizingNone;
    }];
    
    self.observer2=[[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
       // NSLog(@"UIDeviceOrientationDidChangeNotification:%@", note);
       // UIView *view= [UIApplication sharedApplication].keyWindow.rootViewController.view;
       // CGSize size=view.frame.size;
       // UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
       // NSLog(@"UIDeviceOrientation:%ld", (long)deviceOrientation);
       // // 横向
       // if (deviceOrientation==UIDeviceOrientationLandscapeLeft||deviceOrientation==UIDeviceOrientationLandscapeRight) {
       //     if(size.height>size.width){
       //         view.frame=CGRectMake(0, 0, size.height, size.width);
       //         [view sizeToFit];
       //     }
       // }else if (deviceOrientation==UIDeviceOrientationPortrait||deviceOrientation==UIDeviceOrientationPortraitUpsideDown) {
       //     if(size.width>size.height){
       //         view.frame=CGRectMake(0, 0, size.height, size.width);
       //         [view sizeToFit];
       //     }
       // }
    }];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {

    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
      
      [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillChangeStatusBarFrameNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
              NSLog(@"%@", note);
          }];
      
  }else if([@"autoresizingMaskFlexibleWidth" isEqualToString:call.method]) {
      [UIApplication sharedApplication].keyWindow.rootViewController.view.autoresizingMask=UIViewAutoresizingFlexibleWidth;
  }else if([@"reg" isEqualToString:call.method]) {
      [self reg];
      result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  }else if([@"unreg" isEqualToString:call.method]) {
      [self unreg];
      result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  }else if([@"changeHorizontal" isEqualToString:call.method]) {
      [self changeHorizontal];
      result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  }else if([@"changeVertical" isEqualToString:call.method]) {
      [self changeVertical];
      result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  }else {
    result(FlutterMethodNotImplemented);
  }
}

@end
