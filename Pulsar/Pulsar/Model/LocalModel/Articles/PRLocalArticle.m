//
//  PRLocalArticle.m
//  Pulsar
//
//  Created by fantom on 28.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRLocalArticle.h"

@implementation PRLocalArticle

- (instancetype)initWithRemoteArticle:(PRRemoteArticle *)article
{
    self = [super init];
    if (self) {
        _objectId = article.objectId;
        _createdAt = article.createdAt;
        _author = article.author;
        _title = article.title;
        _annotation = article.annotation;
        _text = article.text;
        _category = [[PRLocalCategory alloc] initWithRemoteCategory:article.category];
        _location = [[PRLocalGeoPoint alloc] initWithRemoteGeoPoint:article.location];
        _image = [[PRLocalMedia alloc] initWithRemoteMedia:article.image];
        _rating = article.rating;
        _likes = article.likes;
        _disLikes = article.disLikes;
    }
    return self;
}

@end
