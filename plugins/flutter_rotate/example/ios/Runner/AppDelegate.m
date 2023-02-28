#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    
//    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(375/2, 400, 100, 100)];
//        view.backgroundColor = [UIColor greenColor];
////        view.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
//        [self.window addSubview:view];
//        view.layer.zPosition = FLT_MAX;
//    self.window.layer.zPosition=FLT_MAX;
//
//
    
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
