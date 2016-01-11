//
//  PRRemoteRegistrationRequest.h
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRJsonCompatable.h"

@interface PRRemoteRegistrationRequest : NSObject<PRJsonCompatable>

@property (strong, nonatomic, readonly) NSString *userName;
@property (strong, nonatomic, readonly) NSString *password;
@property (strong, nonatomic, readonly) NSString *email;

- (instancetype)initWithUserName:(NSString *)name password:(NSString *)password email:(NSString *)email;

@end
