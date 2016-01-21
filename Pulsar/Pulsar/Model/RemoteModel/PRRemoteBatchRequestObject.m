//
//  PRRemoteBatchRequestObject.m
//  Pulsar
//
//  Created by fantom on 20.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemoteBatchRequestObject.h"
#import "PRConstants.h"

@implementation PRRemoteBatchRequestObject

- (instancetype)initWithMethod:(NSString *)method targetClass:(NSString *)remoteClass body:(NSDictionary *)body
{
    self = [super init];
    if (self) {
        _method = method;
        _remoteClass = remoteClass;
        _body = body;
    }
    return self;
}

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
    return [super init];
}

- (id)toJSONCompatable
{
    return @{@"method" : self.method, @"path" : [NSString stringWithFormat:@"/%ld/classes/%@", (long)kPRParseAPIVersion, self.remoteClass], @"body" : self.body};
}

@end
