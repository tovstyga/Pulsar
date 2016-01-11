//
//  PRRemoteLoginResponse.m
//  Pulsar
//
//  Created by fantom on 04.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemoteLoginResponse.h"
#import "PRConstants.h"

static NSString *kCreatedAtKey = @"createdAt";
static NSString *kEmailKey = @"email";
static NSString *kEmailVerifiedKey = @"emailVerified";
static NSString *kObjectIdKey = @"objectId";
static NSString *kSessionTokenKey = @"sessionToken";
static NSString *kUpdatedAtKey = @"updatedAt";
static NSString *kUserNameKey = @"username";

@implementation PRRemoteLoginResponse

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
    self = [super init];
    if (self && [jsonCompatableOblect isKindOfClass:[NSDictionary class]]) {
        NSDictionary *source = (NSDictionary *)jsonCompatableOblect;
        NSDateFormatter *formatter = [NSDateFormatter new];
        [formatter setDateFormat:kParseDateFormat];
        
        _createdAt = [formatter dateFromString:[source objectForKey:kCreatedAtKey]];
        _email = [source objectForKey:kEmailKey];
        _emailVerified = [[source objectForKey:kEmailVerifiedKey] boolValue];
        _objectId = [source objectForKey:kObjectIdKey];
        _sessionToken = [source objectForKey:kSessionTokenKey];
        _updatedAt = [formatter dateFromString:[source objectForKey:kUpdatedAtKey]];
        _userName = [source objectForKey:kUserNameKey];
    }
    
    return self;
}

- (id)toJSONCompatable
{
    return nil;
}

@end
