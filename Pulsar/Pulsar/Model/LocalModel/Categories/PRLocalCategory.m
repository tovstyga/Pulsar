//
//  PRLocalCategory.m
//  Pulsar
//
//  Created by fantom on 20.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRLocalCategory.h"

@implementation PRLocalCategory

- (instancetype)initWithRemoteCategory:(PRRemoteCategory *)remoteCategory
{
    self = [super init];
    if (self) {
        _identifier = remoteCategory.objectId;
        _title = remoteCategory.name;
    }
    return self;
}

@end
