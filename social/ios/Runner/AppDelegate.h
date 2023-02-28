#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import "WXApi.h"
#import "QiAudioPlayer.h"

@interface AppDelegate : FlutterAppDelegate<WXApiDelegate> {
    NSString  *_backgroundId;
}

@end
