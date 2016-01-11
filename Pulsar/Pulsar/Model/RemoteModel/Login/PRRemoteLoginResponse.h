//
//  PRRemoteLoginResponse.h
//  Pulsar
//
//  Created by fantom on 04.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRJsonCompatable.h"

@interface PRRemoteLoginResponse : NSObject<PRJsonCompatable>

@property (strong, nonatomic, readonly) NSDate *createdAt;
@property (strong, nonatomic, readonly) NSString *email;
@property (nonatomic, readonly, getter=isEmailVerified) BOOL emailVerified;
@property (strong, nonatomic, readonly) NSString *objectId;
@property (strong, nonatomic, readonly) NSString *sessionToken;
@property (strong, nonatomic, readonly) NSDate *updatedAt;
@property (strong, nonatomic, readonly) NSString *userName;

@end
