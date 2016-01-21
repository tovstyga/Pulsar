//
//  PRRemoteCategories.m
//  Pulsar
//
//  Created by fantom on 12.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemoteCategory.h"
#import "PRConstants.h"

@implementation PRRemoteCategory

static NSString * const kCreatedAtKey = @"createdAt";
static NSString * const kObjectIdKey = @"objectId";
static NSString * const kUpdatedAtKey = @"updatedAt";
static NSString * const kNameKey = @"name";

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
    self = [super init];
    if (self && [jsonCompatableOblect isKindOfClass:[NSDictionary class]]) {
        NSDictionary *source = (NSDictionary *)jsonCompatableOblect;
        NSDateFormatter *formatter = [NSDateFormatter new];
        [formatter setDateFormat:kParseDateFormat];
        
        _createdAt = [formatter dateFromString:[source objectForKey:kCreatedAtKey]];
        _objectId = [source objectForKey:kObjectIdKey];
        _updatedAt = [formatter dateFromString:[source objectForKey:kUpdatedAtKey]];
        _name = [source objectForKey:kNameKey];
    }
    
    return self;
}

- (id)toJSONCompatable
{
    return nil;
}

@end
