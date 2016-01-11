//
//  PRReachability.m
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRReachability.h"
#import "PRConstants.h"
#import <SystemConfiguration/SystemConfiguration.h>

@interface PRReachability()

@property (nonatomic, assign, readwrite) SCNetworkReachabilityFlags flags;

@end

@implementation PRReachability {
    dispatch_queue_t _synchronizationQueue;
    SCNetworkReachabilityRef _networkReachability;
}

static void _reachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
    PRReachability *reachability = (__bridge PRReachability *)info;
    reachability.flags = flags;
}

@synthesize flags = _flags;

- (instancetype)init
{
    NSString *serverUrlAsString = [NSString stringWithFormat:@"%@/%ld", kPRParseServer, (long)kPRParseAPIVersion];
    NSURL *serverUrl = [NSURL URLWithString:serverUrlAsString];
    self = [self initWithURL:serverUrl];
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (!self) return nil;
    
    _synchronizationQueue = dispatch_queue_create("reachability", DISPATCH_QUEUE_CONCURRENT);
    [self _startMonitoringReachabilityWithURL:url];
    
    return self;
}

- (void)dealloc
{
    if (_networkReachability != NULL) {
        SCNetworkReachabilitySetCallback(_networkReachability, NULL, NULL);
        SCNetworkReachabilitySetDispatchQueue(_networkReachability, NULL);
        CFRelease(_networkReachability);
        _networkReachability = NULL;
    }
}

#pragma mark - Accessors

- (void)setFlags:(SCNetworkReachabilityFlags)flags
{
    dispatch_barrier_async(_synchronizationQueue, ^{
        _flags = flags;
    });
}

- (SCNetworkReachabilityFlags)flags
{
    __block SCNetworkReachabilityFlags flags;
    dispatch_sync(_synchronizationQueue, ^{
        flags = _flags;
    });
    return flags;
}

- (PRReachabilityState)networkState
{
    return [[self class] _reachabilityStateForFlags:self.flags];
}

- (BOOL)isNetworkAvailable
{
    switch (self.networkState) {
        case PRReachabilityStateNotReachable:
            return NO;
            break;
        case PRReachabilityStateReachableViaWiFi:
            return YES;
            break;
        case PRReachabilityStateReachableViaWWAN:
            return YES;
            break;
        default:
            return NO;
            break;
    }
}

#pragma mark - Reachability

+ (BOOL)_reachabilityStateForFlags:(SCNetworkConnectionFlags)flags
{
    PRReachabilityState reachabilityState = PRReachabilityStateNotReachable;
    
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
        return reachabilityState;
    }
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        reachabilityState = PRReachabilityStateReachableViaWiFi;
    }
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            reachabilityState = PRReachabilityStateReachableViaWiFi;
        }
    }
    
    if (((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) &&
        ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)) {
        reachabilityState = PRReachabilityStateReachableViaWWAN;
    }
    
    return reachabilityState;
}

- (void)_startMonitoringReachabilityWithURL:(NSURL *)url {
    dispatch_barrier_async(_synchronizationQueue, ^{
        _networkReachability = SCNetworkReachabilityCreateWithName(NULL, [[url host] UTF8String]);
        if (_networkReachability != NULL) {
            SCNetworkReachabilityFlags flags;
            SCNetworkReachabilityGetFlags(_networkReachability, &flags);
            self.flags = flags;
        
            SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
            if (SCNetworkReachabilitySetCallback(_networkReachability, _reachabilityCallback, &context)) {
                if (!SCNetworkReachabilitySetDispatchQueue(_networkReachability, _synchronizationQueue)) {

                }
            }
        }
    });
}


@end
