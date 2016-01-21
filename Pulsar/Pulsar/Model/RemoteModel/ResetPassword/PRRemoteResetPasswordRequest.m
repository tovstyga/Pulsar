//
//  PRRemoteResetPasswordRequest.m
//  Pulsar
//
//  Created by fantom on 04.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemoteResetPasswordRequest.h"

@implementation PRRemoteResetPasswordRequest

static NSString *kEmailKey = @"email";

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
