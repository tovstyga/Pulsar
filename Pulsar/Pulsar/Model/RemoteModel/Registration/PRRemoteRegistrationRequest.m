//
//  PRRemoteRegistrationRequest.m
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRRemoteRegistrationRequest.h"

@implementation PRRemoteRegistrationRequest

static NSString *kUserNameKey = @"username";
static NSString *kPasswordKey = @"password";
static NSString *kEmailKey = @"email";

- (instancetype)initWithUserName:(NSString *)name password:(NSString *)password email:(NSString *)email
{
    self = [super init];
    if (self) {
        _userName = name;
        _password = password;
        _email = email;
    }
    return self;
}

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
    return [super init];
}

- (id)toJSONCompatable
{
    NSMutableDictionary *body = [NSMutableDictionary new];
    if (self.userName) {
        [body setObject:self.userName forKey:kUserNameKey];
    }
    if (self.password) {
        [body setObject:self.password forKey:kPasswordKey];
    }
    if (self.email) {
        [body setObject:self.email forKey:kEmailKey];
    }
    return body;
}

@end
