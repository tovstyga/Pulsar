//
//  PRRemoteFile.m
//  Pulsar
//
//  Created by fantom on 28.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemoteFile.h"

@implementation PRRemoteFile

static NSString * const kFileNameKey = @"name";
static NSString * const kUrlKey = @"url";

- (instancetype)initWithName:(NSString *)fileName url:(NSURL *)remoteUrl
{
    self = [super init];
    if (self) {
        _name = fileName;
        _url = remoteUrl;
    }
    return self;
}

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
    self = [super init];
    if (self && [jsonCompatableOblect isKindOfClass:[NSDictionary class]]) {
        _name = [(NSDictionary *)jsonCompatableOblect objectForKey:kFileNameKey];
        _url = [NSURL URLWithString:[(NSDictionary *)jsonCompatableOblect objectForKey:kUrlKey]];
    }
    return self;
}

- (id)toJSONCompatable
{
    NSMutableDictionary *result = [NSMutableDictionary new];
    [result setObject:@"File" forKey:@"__type"];
    [result setObject:self.name forKey:kFileNameKey];
    if (self.url) {
        [result setObject:[self.url absoluteString] forKey:kUrlKey];
    }
    return result;
}

@end
