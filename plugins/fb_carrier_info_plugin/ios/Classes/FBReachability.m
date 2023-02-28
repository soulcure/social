/*
 Copyright (c) 2011, Tony Million.
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

#import "FBReachability.h"

NSString *const kFBReachabilityChangedNotification = @"kFBReachabilityChangedNotification";

@interface FBReachability ()

@property (nonatomic, assign) SCNetworkReachabilityRef reachabilityRef;

#if NEEDS_DISPATCH_RETAIN_RELEASE
@property (nonatomic, assign) dispatch_queue_t reachabilitySerialQueue;
#else
@property (nonatomic, strong) dispatch_queue_t reachabilitySerialQueue;
#endif

@property (nonatomic, strong) id reachabilityObject;

- (void)_reachabilityChanged:(SCNetworkReachabilityFlags)flags;
- (BOOL)_isReachableWithFlags:(SCNetworkReachabilityFlags)flags;

@end

static NSString * reachabilityFlags(SCNetworkReachabilityFlags flags)
{
    return [NSString stringWithFormat:@"%c%c %c%c%c%c%c%c%c",
#if     TARGET_OS_IPHONE
            (flags & kSCNetworkReachabilityFlagsIsWWAN) ? 'W' : '-',
#else
            'X',
#endif
            (flags & kSCNetworkReachabilityFlagsReachable) ? 'R' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionRequired) ? 'c' : '-',
            (flags & kSCNetworkReachabilityFlagsTransientConnection) ? 't' : '-',
            (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) ? 'C' : '-',
            (flags & kSCNetworkReachabilityFlagsConnectionOnDemand) ? 'D' : '-',
            (flags & kSCNetworkReachabilityFlagsIsLocalAddress) ? 'l' : '-',
            (flags & kSCNetworkReachabilityFlagsIsDirect) ? 'd' : '-'];
}

//Start listening for reachability notifications on the current run loop
static void TMReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
#pragma unused (target)
#if __has_feature(objc_arc)
    FBReachability *reachability = ((__bridge FBReachability *)info);
#else
    FBReachability *reachability = ((FBReachability *)info);
#endif

    // we probably dont need an autoreleasepool here as GCD docs state each queue has its own autorelease pool
    // but what the heck eh?
    @autoreleasepool
    {
        [reachability _reachabilityChanged:flags];
    }
}

@implementation FBReachability

@synthesize reachabilityRef;
@synthesize reachabilitySerialQueue;

@synthesize fb_reachableOnWWAN;

@synthesize fb_reachableBlock;
@synthesize fb_unreachableBlock;

@synthesize reachabilityObject;

#pragma mark - class constructor methods
+ (FBReachability *)fb_reachabilityWithHostname:(NSString *)hostname
{
    SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithName(NULL, [hostname UTF8String]);
    if (ref) {
        id reachability = [[self alloc] initWithReachabilityRef:ref];

#if __has_feature(objc_arc)
        return reachability;
#else
        return [reachability autorelease];
#endif
    }

    return nil;
}

+ (FBReachability *)fb_reachabilityWithAddress:(const struct sockaddr_in *)hostAddress
{
    SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)hostAddress);
    if (ref) {
        id reachability = [[self alloc] initWithReachabilityRef:ref];

#if __has_feature(objc_arc)
        return reachability;
#else
        return [reachability autorelease];
#endif
    }

    return nil;
}

+ (FBReachability *)fb_reachabilityForInternetConnection
{
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;

    return [self fb_reachabilityWithAddress:&zeroAddress];
}

+ (FBReachability *)fb_reachabilityForLocalWiFi
{
    struct sockaddr_in localWifiAddress;
    bzero(&localWifiAddress, sizeof(localWifiAddress));
    localWifiAddress.sin_len = sizeof(localWifiAddress);
    localWifiAddress.sin_family = AF_INET;
    // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
    localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);

    return [self fb_reachabilityWithAddress:&localWifiAddress];
}

// initialization methods

- (FBReachability *)initWithReachabilityRef:(SCNetworkReachabilityRef)ref
{
    self = [super init];
    if (self != nil) {
        self.fb_reachableOnWWAN = YES;
        self.reachabilityRef = ref;
    }

    return self;
}

- (void)dealloc
{
    [self fb_stopNotifier];

    if (self.reachabilityRef) {
        CFRelease(self.reachabilityRef);
        self.reachabilityRef = nil;
    }

#if !(__has_feature(objc_arc))
    [super dealloc];
#endif
}

#pragma mark - notifier methods

// Notifier
// NOTE: this uses GCD to trigger the blocks - they *WILL NOT* be called on THE MAIN THREAD
// - In other words DO NOT DO ANY UI UPDATES IN THE BLOCKS.
//   INSTEAD USE dispatch_async(dispatch_get_main_queue(), ^{UISTUFF}) (or dispatch_sync if you want)

- (BOOL)fb_startNotifier
{
    SCNetworkReachabilityContext context = { 0, NULL, NULL, NULL, NULL };

    // this should do a retain on ourself, so as long as we're in notifier mode we shouldn't disappear out from under ourselves
    // woah
    self.reachabilityObject = self;

    // first we need to create a serial queue
    // we allocate this once for the lifetime of the notifier
    self.reachabilitySerialQueue = dispatch_queue_create("com.tonymillion.reachability", NULL);
    if (!self.reachabilitySerialQueue) {
        return NO;
    }

#if __has_feature(objc_arc)
    context.info = (__bridge void *)self;
#else
    context.info = (void *)self;
#endif

    if (!SCNetworkReachabilitySetCallback(self.reachabilityRef, TMReachabilityCallback, &context)) {
#ifdef DEBUG
        //NSLog(@"SCNetworkReachabilitySetCallback() failed: %s", SCErrorString(SCError()));
#endif

        //clear out the dispatch queue
        if (self.reachabilitySerialQueue) {
#if NEEDS_DISPATCH_RETAIN_RELEASE
            dispatch_release(self.reachabilitySerialQueue);
#endif
            self.reachabilitySerialQueue = nil;
        }

        self.reachabilityObject = nil;

        return NO;
    }

    // set it as our reachability queue which will retain the queue
    if (!SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, self.reachabilitySerialQueue)) {
#ifdef DEBUG
        //NSLog(@"SCNetworkReachabilitySetDispatchQueue() failed: %s", SCErrorString(SCError()));
#endif

        //UH OH - FAILURE!

        // first stop any callbacks!
        SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);

        // then clear out the dispatch queue
        if (self.reachabilitySerialQueue) {
#if NEEDS_DISPATCH_RETAIN_RELEASE
            dispatch_release(self.reachabilitySerialQueue);
#endif
            self.reachabilitySerialQueue = nil;
        }

        self.reachabilityObject = nil;

        return NO;
    }

    return YES;
}

- (void)fb_stopNotifier
{
    // first stop any callbacks!
    SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);

    // unregister target from the GCD serial dispatch queue
    SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, NULL);

    if (self.reachabilitySerialQueue) {
#if NEEDS_DISPATCH_RETAIN_RELEASE
        dispatch_release(self.reachabilitySerialQueue);
#endif
        self.reachabilitySerialQueue = nil;
    }

    self.reachabilityObject = nil;
}

#pragma mark - reachability tests

// this is for the case where you flick the airplane mode
// you end up getting something like this:
//Reachability: WR ct-----
//Reachability: -- -------
//Reachability: WR ct-----
//Reachability: -- -------
// we treat this as 4 UNREACHABLE triggers - really apple should do better than this

#define testcase (kSCNetworkReachabilityFlagsConnectionRequired | kSCNetworkReachabilityFlagsTransientConnection)

- (BOOL)_isReachableWithFlags:(SCNetworkReachabilityFlags)flags
{
    BOOL connectionUP = YES;

    if (!(flags & kSCNetworkReachabilityFlagsReachable)) connectionUP = NO;

    if ( (flags & testcase) == testcase) connectionUP = NO;

#if     TARGET_OS_IPHONE
    if (flags & kSCNetworkReachabilityFlagsIsWWAN) {
        // we're on 3G
        if (!self.fb_reachableOnWWAN) {
            // we dont want to connect when on 3G
            connectionUP = NO;
        }
    }
#endif

    return connectionUP;
}

- (BOOL)fb_isReachable
{
    SCNetworkReachabilityFlags flags;

    if (!SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) return NO;

    return [self _isReachableWithFlags:flags];
}

- (BOOL)fb_isReachableViaWWAN
{
#if TARGET_OS_IPHONE

    SCNetworkReachabilityFlags flags = 0;

    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        // check we're REACHABLE
        if (flags & kSCNetworkReachabilityFlagsReachable) {
            // now, check we're on WWAN
            if (flags & kSCNetworkReachabilityFlagsIsWWAN) {
                return YES;
            }
            /*
            if (flags & kSCNetworkReachabilityFlagsIsWWAN) {
                if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
                    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
                    NSString *currentRadioAccessTechnology = info.currentRadioAccessTechnology;
                    if (currentRadioAccessTechnology) {
                        if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE]) {
                            return kReachableVia4G;
                        } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge] || [currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS]) {
                            return kReachableVia2G;
                        } else {
                            return kReachableVia3G;
                        }
                    }
                }

                if ((flags & kSCNetworkReachabilityFlagsTransientConnection) == kSCNetworkReachabilityFlagsTransientConnection) {
                    if((flags & kSCNetworkReachabilityFlagsConnectionRequired) == kSCNetworkReachabilityFlagsConnectionRequired) {
                        return kReachableVia2G;
                    }
                    return kReachableVia3G;
                }
                return kReachableViaWWAN;
            }
             */
        }
    }
#endif

    return NO;
}

- (BOOL)fb_isReachableViaWiFi
{
    SCNetworkReachabilityFlags flags = 0;

    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        // check we're reachable
        if ((flags & kSCNetworkReachabilityFlagsReachable)) {
#if     TARGET_OS_IPHONE
            // check we're NOT on WWAN
            if ((flags & kSCNetworkReachabilityFlagsIsWWAN)) {
                return NO;
            }
#endif
            return YES;
        }
    }

    return NO;
}

// WWAN may be available, but not active until a connection has been established.
// WiFi may require a connection for VPN on Demand.
- (BOOL)fb_isConnectionRequired
{
    return [self fb_connectionRequired];
}

- (BOOL)fb_connectionRequired
{
    SCNetworkReachabilityFlags flags;

    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
    }

    return NO;
}

+ (BOOL)fb_netWorkIsOk
{
    BOOL netWorkConnectIsOk = YES;
    if (([FBReachability fb_reachabilityForInternetConnection].fb_currentReachabilityStatus == FBNotReachable) &&
        ([FBReachability fb_reachabilityForLocalWiFi].fb_currentReachabilityStatus == FBNotReachable)) {
        netWorkConnectIsOk = NO;
    } else {
        netWorkConnectIsOk = YES;
    }
    return netWorkConnectIsOk;
}

// Dynamic, on demand connection?
- (BOOL)fb_isConnectionOnDemand
{
    SCNetworkReachabilityFlags flags;

    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        return ((flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
                (flags & (kSCNetworkReachabilityFlagsConnectionOnTraffic | kSCNetworkReachabilityFlagsConnectionOnDemand)));
    }

    return NO;
}

// Is user intervention required?
- (BOOL)fb_isInterventionRequired
{
    SCNetworkReachabilityFlags flags;

    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        return ((flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
                (flags & kSCNetworkReachabilityFlagsInterventionRequired));
    }

    return NO;
}

#pragma mark - reachability status stuff

- (FBNetworkStatus)fb_currentReachabilityStatus
{
    if ([self fb_isReachable]) {
        if ([self fb_isReachableViaWiFi]) return FBReachableViaWiFi;

#if     TARGET_OS_IPHONE
        return FBReachableViaWWAN;
#endif
    }

    return FBNotReachable;
}

- (SCNetworkReachabilityFlags)fb_reachabilityFlags
{
    SCNetworkReachabilityFlags flags = 0;

    if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        return flags;
    }

    return 0;
}

- (NSString *)fb_currentReachabilityString
{
    FBNetworkStatus temp = [self fb_currentReachabilityStatus];

    if (temp == fb_reachableOnWWAN) {
        // updated for the fact we have CDMA phones now!
        return NSLocalizedString(@"Cellular", @"");
    }
    if (temp == FBReachableViaWiFi) {
        return NSLocalizedString(@"WiFi", @"");
    }

    return NSLocalizedString(@"No Connection", @"");
}

- (NSString *)fb_currentReachabilityFlags
{
    return reachabilityFlags([self fb_reachabilityFlags]);
}

#pragma mark - callback function calls this method

- (void)_reachabilityChanged:(SCNetworkReachabilityFlags)flags
{
    if ([self _isReachableWithFlags:flags]) {
        if (self.fb_reachableBlock) {
            self.fb_reachableBlock(self);
        }
    } else {
        if (self.fb_unreachableBlock) {
            self.fb_unreachableBlock(self);
        }
    }

    // this makes sure the change notification happens on the MAIN THREAD
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kFBReachabilityChangedNotification
                                                            object:self];
    });
}

#pragma mark - Debug Description

- (NSString *)description
{
    NSString *description = [NSString stringWithFormat:@"<%@: %#x (%@)>",
                             NSStringFromClass([self class]), (unsigned int)self, [self fb_currentReachabilityFlags]];
    return description;
}

@end
