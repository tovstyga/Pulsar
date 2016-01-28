//
//  PRLocalArticle.h
//  Pulsar
//
//  Created by fantom on 28.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRLocalCategory.h"
#import "PRLocalGeoPoint.h"
#import "PRLocalMedia.h"
#import "PRRemoteArticle.h"

@interface PRLocalArticle : NSObject

@property (strong, nonatomic, readonly) NSString *objectId;
@property (strong, nonatomic, readonly) NSDate *createdAt;

@property (strong, nonatomic, readonly) NSString *author;
@property (strong, nonatomic, readonly) NSString *title;
@property (strong, nonatomic, readonly) NSString *annotation;
@property (strong, nonatomic, readonly) NSString *text;

@property (strong, nonatomic, readonly) PRLocalCategory *category;
@property (strong, nonatomic, readonly) PRLocalGeoPoint *location;
@property (strong, nonatomic, readonly) PRLocalMedia *image;

@property (nonatomic, readonly) NSInteger rating;
@property (strong, nonatomic, readonly) NSArray *likes;
@property (strong, nonatomic, readonly) NSArray *disLikes;

- (instancetype)initWithRemoteArticle:(PRRemoteArticle *)article;

@end
