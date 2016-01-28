//
//  PRRemoteArticle.m
//  Pulsar
//
//  Created by fantom on 28.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemoteArticle.h"
#import "PRConstants.h"

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

static NSString * const kUserNameKey = @"username";

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
    self = [super init];
    if (self && [jsonCompatableOblect isKindOfClass:[NSDictionary class]]) {
        NSDictionary *source = (NSDictionary *)jsonCompatableOblect;
        
        NSDateFormatter *formatter = [NSDateFormatter new];
        [formatter setDateFormat:kParseDateFormat];
        
        _objectId = [source objectForKey:kObjectIdKey];
        _createdAt = [formatter dateFromString:[source objectForKey:kCreatedAtKey]];
        
        _author = [(NSDictionary *)[source objectForKey:kAuthorKey] objectForKey:kUserNameKey];
        _title = [source objectForKey:kTitleKey];
        _annotation = [source objectForKey:kAnnotationKey];
        _text = [source objectForKey:kTextKey];
        
        _category = [[PRRemoteCategory alloc] initWithJSON:[source objectForKey:kTagKey]];
        _location = [[PRRemoteGeoPoint alloc] initWithJSON:[source objectForKey:kLocationKey]];
        _image = [[PRRemoteMedia alloc] initWithJSON:[source objectForKey:kImageKey]];
        
        _rating = [[source objectForKey:kRatingKey] integerValue];
        _likes = [source objectForKey:kLikesKey];
        _disLikes = [source objectForKey:kDislikesKey];
    }
    return self;
}

- (id)toJSONCompatable
{
    return nil;
}

@end
