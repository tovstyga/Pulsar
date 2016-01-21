//
//  PRRemoteError.m
//  Pulsar
//
//  Created by fantom on 04.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemoteError.h"

@implementation PRRemoteError

static NSString * kErrorKey = @"error";
static NSString * kCodeKey = @"code";

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
    self = [super init];
    if ([jsonCompatableOblect isKindOfClass:[NSDictionary class]]) {
        _errorDescription = [(NSDictionary *)jsonCompatableOblect objectForKey:kErrorKey];
        _errorCode = [((NSString *)[(NSDictionary *)jsonCompatableOblect objectForKey:kCodeKey]) intValue];
    }
    return self;
}

- (id)toJSONCompatable
{
    return nil;
}

@end
