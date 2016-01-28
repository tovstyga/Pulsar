//
//  PRRemoteArticle.h
//  Pulsar
//
//  Created by fantom on 28.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRJsonCompatable.h"
#import "PRRemoteCategory.h"
#import "PRRemoteGeoPoint.h"
#import "PRRemoteMedia.h"

@interface PRRemoteArticle : NSObject<PRJsonCompatable>

@property (strong, nonatomic, readonly) NSString *objectId;
@property (strong, nonatomic, readonly) NSDate *createdAt;

@property (strong, nonatomic, readonly) NSString *author;
@property (strong, nonatomic, readonly) NSString *title;
@property (strong, nonatomic, readonly) NSString *annotation;
@property (strong, nonatomic, readonly) NSString *text;

@property (strong, nonatomic, readonly) PRRemoteCategory *category;
@property (strong, nonatomic, readonly) PRRemoteGeoPoint *location;
@property (strong, nonatomic, readonly) PRRemoteMedia *image;

@property (nonatomic, readonly) NSInteger rating;
@property (strong, nonatomic, readonly) NSArray *likes;
@property (strong, nonatomic, readonly) NSArray *disLikes;

@end
