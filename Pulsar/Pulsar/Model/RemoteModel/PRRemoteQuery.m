//
//  PRRemoteQuery.m
//  Pulsar
//
//  Created by fantom on 19.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemoteQuery.h"

@implementation PRRemoteQuery

static PRRemoteQuery *sharedInstance;

- (instancetype)init
{
    if (sharedInstance) {
        return sharedInstance;
    } else {
        return [super init];
    }
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[PRRemoteQuery alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Public

- (NSDictionary *)categoriesQueryForUser:(PRRemotePointer *)pointer
{
    return @{@"_method":@"GET", @"where":@{@"users": [pointer toJSONCompatable]}};
}

- (NSDictionary *)addRelationField:(NSString *)fieldName objects:(NSArray *)pointers
{
    return @{fieldName : @{@"__op" : @"AddRelation", @"objects" : [self convertObjects:pointers]}};
}

- (NSDictionary *)removeRelationField:(NSString *)fieldName objects:(NSArray *)pointers
{
    return @{fieldName : @{@"__op" : @"RemoveRelation", @"objects" : [self convertObjects:pointers]}};
}

- (NSDictionary *)batchQueryWithObjects:(NSArray *)batchRequestObjects
{
    return @{@"requests" : [self convertObjects:batchRequestObjects]};
}

#pragma mark - Internal

- (NSArray *)convertObjects:(NSArray *)objects
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (id<PRJsonCompatable> object in objects) {
        [result addObject:[object toJSONCompatable]];
    }
    return result;
}

@end
