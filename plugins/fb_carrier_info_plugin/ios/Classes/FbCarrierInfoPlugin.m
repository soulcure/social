#import "FbCarrierInfoPlugin.h"

#import "FBDeviceNetUtil.h"

@implementation FbCarrierInfoPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"fb_carrier_info_plugin"
            binaryMessenger:[registrar messenger]];
  FbCarrierInfoPlugin* instance = [[FbCarrierInfoPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getNetWorkType" isEqualToString:call.method]) {
      NSString *type = [FBDeviceNetUtil getNetWorkStatus];
    result(type);
  }else if ([@"getOperatorType" isEqualToString:call.method]) {
      NSString *type = [FBDeviceNetUtil getOperatorType];
      result(type);
    } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
