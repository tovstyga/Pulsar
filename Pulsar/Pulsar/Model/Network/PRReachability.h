//
//  PRReachability.h
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint8_t, PRReachabilityState) {
    PRReachabilityStateNotReachable,
    PRReachabilityStateReachableViaWiFi,
    PRReachabilityStateReachableViaWWAN,
};

@interface PRReachability : NSObject

@property (atomic, assign, readonly) PRReachabilityState networkState;
@property (atomic, assign, readonly, getter=isNetworkAvailable) BOOL networkAvailable;

- (instancetype)initWithURL:(NSURL *)url;

@end
