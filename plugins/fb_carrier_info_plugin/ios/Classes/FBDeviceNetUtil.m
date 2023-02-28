//
//  FBDeviceNetUtil.m
//  fb_carrier_info_plugin
//
//  Created by Soto.Poul on 2021/3/6.
//

#import "FBDeviceNetUtil.h"

#import "FBReachability.h"

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>


NSString *const NETWORK_NONE = @"0";
NSString *const NETWORK_2G = @"1";
NSString *const NETWORK_3G = @"2";
NSString *const NETWORK_4G = @"3";
NSString *const NETWORK_5G = @"4";
NSString *const NETWORK_WIFI = @"5";
NSString *const NETWORK_UNKNOWN = @"6";

NSString *const OPERATOR_UNKNOWN = @"0";// 未知类型
NSString *const OPERATOR_CUCC = @"1";// 中国联通
NSString *const OPERATOR_CMCC = @"2";// 中国移动
NSString *const OPERATOR_CTCC = @"3"; // 中国电信

@implementation FBDeviceNetUtil

+ (NSString *)fb_getCTMobileNetworkCode
{
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc]init];
    CTCarrier *carrier = [info subscriberCellularProvider];

    return carrier.mobileNetworkCode;
}

+ (NSString *)getOperatorType
{
    //    1：中国移动
    //    2：中国联通
    //    3：中国电信
    //    4：中国网通
    //    5：中国铁通
    //    6：中国卫通
    //    99：其他

    NSString *networkCode = [FBDeviceNetUtil fb_getCTMobileNetworkCode];
    NSString *ret = OPERATOR_UNKNOWN;

    if ([networkCode isEqualToString:@"00"] || [networkCode isEqualToString:@"02"] || [networkCode isEqualToString:@"07"] || [networkCode isEqualToString:@"08"]) {
        ret = OPERATOR_CMCC;//中国移动
    } else if ([networkCode isEqualToString:@"01"] || [networkCode isEqualToString:@"06"] || [networkCode isEqualToString:@"09"]) {
        ret = OPERATOR_CUCC;//中国联通
    } else if ([networkCode isEqualToString:@"03"] || [networkCode isEqualToString:@"05"] || [networkCode isEqualToString:@"11"]) {
        ret = OPERATOR_CTCC;//中国电信
    } else {
        ret = OPERATOR_UNKNOWN;
    }

    return ret;
}


+ (NSString *)getNetWorkStatus {
    NSString *status = NETWORK_NONE;
    FBReachability *reachability = [FBReachability fb_reachabilityForInternetConnection];
    FBNetworkStatus reachabilityStatus = [reachability fb_currentReachabilityStatus];

    switch (reachabilityStatus) {
        case FBNotReachable:    // 没有网络
        {
            status = NETWORK_NONE;
        }
        break;

        case FBReachableViaWiFi:    // Wifi
        {
            status = NETWORK_WIFI;
        }
        break;

        case FBReachableViaWWAN:    // 手机自带网络
        {
            CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
            NSString *radioType = nil;
            if (@available(iOS 12.1, *)) {
                if (info && [info respondsToSelector:@selector(serviceCurrentRadioAccessTechnology)]) {
                    NSDictionary *radioDic = [info serviceCurrentRadioAccessTechnology];
                    if (radioDic.allKeys.count) {
                        radioType = [radioDic objectForKey:radioDic.allKeys[0]];
                    }
                }
            }else {
                radioType = [info currentRadioAccessTechnology];
            }
            
            // 获取手机网络类型
            if ([radioType isEqualToString:CTRadioAccessTechnologyGPRS] || [radioType isEqualToString:CTRadioAccessTechnologyEdge]) {
                status = NETWORK_2G;
            } else if ([radioType isEqualToString:CTRadioAccessTechnologyHSDPA]
                       || [radioType isEqualToString:CTRadioAccessTechnologyWCDMA]
                       || [radioType isEqualToString:CTRadioAccessTechnologyHSUPA]
                       || [radioType isEqualToString:CTRadioAccessTechnologyCDMA1x]
                       || [radioType isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]
                       || [radioType isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]
                       || [radioType isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]
                       || [radioType isEqualToString:CTRadioAccessTechnologyeHRPD]) {
                status = NETWORK_3G;
            } else if ([radioType isEqualToString:CTRadioAccessTechnologyLTE]) {
                status = NETWORK_4G;
            } else {
                if (@available(iOS 14.1, *)) {
                    if ([radioType isEqualToString:CTRadioAccessTechnologyNR] || [radioType isEqualToString:CTRadioAccessTechnologyNRNSA]) {
                        status = NETWORK_5G;
                    }
                }
            }
        }
        break;
        default:
            status = NETWORK_UNKNOWN;
            break;
    }

    return status;
}

@end
