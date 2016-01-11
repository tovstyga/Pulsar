//
//  PRRemoteRegistrationResponse.h
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRJsonCompatable.h"

@interface PRRemoteRegistrationResponse : NSObject<PRJsonCompatable>

@property (strong, nonatomic, readonly) NSDate *createdAt;
@property (strong, nonatomic, readonly) NSString *objectId;
@property (strong, nonatomic, readonly) NSString *sessionToken;

@end
