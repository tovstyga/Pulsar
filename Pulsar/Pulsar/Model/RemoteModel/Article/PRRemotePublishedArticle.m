//
//  PRRemoteArticle.m
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemotePublishedArticle.h"

@implementation PRRemotePublishedArticle

static NSString * const kAuthorKey = @"author";
static NSString * const kTitleKey = @"title";
static NSString * const kAnnotationKey = @"annotation";
static NSString * const kTextKey = @"text";
static NSString * const kImageKey = @"image";
static NSString * const kTagKey = @"tag";
static NSString * const kLocationKey = @"location";

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
    self = [super init];
    return self;
}

- (id)toJSONCompatable
{
    NSMutableDictionary *result = [NSMutableDictionary new];
    [result setObject:[self.author toJSONCompatable] forKey:kAuthorKey];
    [result setObject:self.title forKey:kTitleKey];
    [result setObject:self.annotation forKey:kAnnotationKey];
    [result setObject:self.text forKey:kTextKey];
    [result setObject:[self.category toJSONCompatable] forKey:kTagKey];
    if (self.image) {
        [result setObject:[self.image toJSONCompatable] forKey:kImageKey];
    }
    [result setObject:[self.location toJSONCompatable] forKey:kLocationKey];
    return result;
}

@end
