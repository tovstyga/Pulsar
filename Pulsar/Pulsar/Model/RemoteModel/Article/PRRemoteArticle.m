//
//  PRRemoteArticle.m
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemoteArticle.h"

@implementation PRRemoteArticle

static NSString * const kObjectIdKey = @"objectId";
static NSString * const kAuthorKey = @"author";
static NSString * const kCreatedAtKey = @"createdAt";
static NSString * const kTitleKey = @"title";
static NSString * const kAnnotationKey = @"annotation";
static NSString * const kTextKey = @"text";
static NSString * const kImageKey = @"image";
static NSString * const kTagKey = @"tag";
static NSString * const kLocationKey = @"location";
static NSString * const kRatingKey = @"rating";
static NSString * const kLikesKey = @"likes";
static NSString * const kDislikesKey = @"dislikes";

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
#warning complete this;
    self = [super init];
    if (self && [jsonCompatableOblect isKindOfClass:[NSDictionary class]]) {
        _objectId = [(NSDictionary *)jsonCompatableOblect objectForKey:kObjectIdKey];
    }
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
