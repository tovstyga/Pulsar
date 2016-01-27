//
//  PRRemoteUploadFileResponse.m
//  Pulsar
//
//  Created by fantom on 26.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemoteUploadFileResponse.h"

@implementation PRRemoteUploadFileResponse

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
    self = [super init];
    if (self && [jsonCompatableOblect isKindOfClass:[NSDictionary class]]) {
        _resourceIdentifier = [(NSDictionary *)jsonCompatableOblect objectForKey:@"name"];
        _resourceUrl = [NSURL URLWithString:[(NSDictionary *)jsonCompatableOblect objectForKey:@"url"]];
    }
    return self;
}

- (id)toJSONCompatable
{
    return nil;
}

@end
