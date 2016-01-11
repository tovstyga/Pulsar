//
//  PRRemoteResetPasswordRequest.m
//  Pulsar
//
//  Created by fantom on 04.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemoteResetPasswordRequest.h"

static NSString *kEmailKey = @"email";

@implementation PRRemoteResetPasswordRequest

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
    return [super init];
}

- (instancetype)initWithEmail:(NSString *)email
{
    self = [super init];
    if (self) {
        _email = email;
    }
    return self;
}

- (id)toJSONCompatable
{
    return @{kEmailKey : self.email};
}

@end
