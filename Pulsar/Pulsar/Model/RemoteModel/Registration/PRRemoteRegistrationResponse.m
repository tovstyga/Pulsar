//
//  PRRemoteRegistrationResponse.m
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRRemoteRegistrationResponse.h"

static NSString *kCreatedAtKey = @"createdAt";
static NSString *kObjectIdKey = @"objectId";
static NSString *kSessionTokenKey = @"sessionToken";

@implementation PRRemoteRegistrationResponse

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
    self = [super init];
    if (self && [jsonCompatableOblect isKindOfClass:[NSDictionary class]]) {
        _createdAt = [(NSDictionary *)jsonCompatableOblect objectForKey:kCreatedAtKey];
        _objectId = [(NSDictionary *)jsonCompatableOblect objectForKey:kObjectIdKey];
        _sessionToken = [(NSDictionary *)jsonCompatableOblect objectForKey:kSessionTokenKey];
    }
    return self;
}

- (id)toJSONCompatable
{
    return nil;
}


@end
