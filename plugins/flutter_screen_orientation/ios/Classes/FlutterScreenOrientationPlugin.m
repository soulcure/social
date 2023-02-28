#import "FlutterScreenOrientationPlugin.h"
static FlutterMethodChannel *methodChannel;
@implementation FlutterScreenOrientationPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    methodChannel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_screen_orientation"
            binaryMessenger:[registrar messenger]];
  FlutterScreenOrientationPlugin* instance = [[FlutterScreenOrientationPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:methodChannel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"init" isEqualToString:call.method]) {
      [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientaionDidChange:) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
   } else {
        result(FlutterMethodNotImplemented);
  }
}

- (void)deviceOrientaionDidChange:(NSNotification *)noty {

    UIDevice *device = [UIDevice currentDevice] ;
    NSLog(@"%ld", device.orientation);
    switch (device.orientation) {
        case UIDeviceOrientationPortrait:
           [methodChannel invokeMethod:@"orientationCallback" arguments:@"1"];
           break;
        case UIDeviceOrientationPortraitUpsideDown:
           [methodChannel invokeMethod:@"orientationCallback" arguments:@"2"];
           break;
        case UIDeviceOrientationLandscapeLeft:
            [methodChannel invokeMethod:@"orientationCallback" arguments:@"3"];
             break;
        case UIDeviceOrientationLandscapeRight:
            [methodChannel invokeMethod:@"orientationCallback" arguments:@"4"];
            break;
        default:
            [methodChannel invokeMethod:@"orientationCallback" arguments:@"0"];
            break;
    }
}

@end
