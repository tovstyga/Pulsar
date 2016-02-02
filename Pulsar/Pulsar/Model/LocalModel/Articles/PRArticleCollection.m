//
//  PRArticleCollection.m
//  Pulsar
//
//  Created by fantom on 02.02.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRArticleCollection.h"

@implementation PRArticleCollection {
    NSMutableDictionary *_internalData;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _internalData = [NSMutableDictionary new];
    }
    return self;
}

- (void)setFetchResult:(NSArray *)result forKey:(PRArticleFetch)key
{
    [_internalData setObject:result forKey:@(key)];
}

- (NSArray *)fetchResultForKey:(PRArticleFetch)key
{
    return [_internalData objectForKey:@(key)];
}

@end
