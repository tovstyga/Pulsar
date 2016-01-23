//
//  PRRemoteArray.m
//  Pulsar
//
//  Created by fantom on 22.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemoteArray.h"

@implementation PRRemoteArray {
    NSString *_fieldName;
    NSString *_action;
    NSArray *_objects;
}

- (instancetype)initWithField:(NSString *)remoteFieldName action:(PRRemoteArrayAction)action objects:(NSArray *)jsonCompatableObjects
{
    self = [super init];
    if (self) {
        _fieldName = remoteFieldName;
        _action = [self descriptionForAction:action];
        _objects = jsonCompatableObjects;
    }
    return self;
}

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
    return [self init];
}
- (id)toJSONCompatable
{
    NSMutableArray *objects = [NSMutableArray new];
    for (id<PRJsonCompatable> object in _objects) {
        [objects addObject:[object toJSONCompatable]];
    }
    return @{_fieldName : @{@"__op" : _action, @"objects" : objects}};
}

- (NSString *)descriptionForAction:(PRRemoteArrayAction)action
{
    switch (action) {
        case PRRemoteArrayActionAdd:
            return @"Add";
        case PRRemoteArrayActionAddUnique:
            return @"AddUnique";
        case PRRemoteArrayActionRemove:
            return @"Remove";
        default:
            return nil;
    }
}

@end
