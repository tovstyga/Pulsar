//
//  PRRemotePointer.m
//  Pulsar
//
//  Created by fantom on 19.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemotePointer.h"

@implementation PRRemotePointer

- (instancetype)initWithClass:(NSString *)remoteClassName remoteObjectId:(NSString *)objectId
{
    self = [super init];
    if (self) {
        _className = remoteClassName;
        _objectId = objectId;
    }
    return self;
}

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
    return [super init];
}

- (id)toJSONCompatable
{
    return @{@"__type":@"Pointer",@"className":self.className,@"objectId":self.objectId};
}

@end
