//
//  PRRemoteArticle.h
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRRemotePointer.h"
#import "PRJsonCompatable.h"
#import "PRRemoteGeoPoint.h"

@interface PRRemoteArticle : NSObject<PRJsonCompatable>

@property (strong, nonatomic, readonly) NSData *createdDate;
@property (strong, nonatomic, readonly) NSString *objectId;
@property (strong, nonatomic) PRRemotePointer *author;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *annotation;
@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) PRRemotePointer *category;
@property (strong, nonatomic) PRRemotePointer *image;
@property (strong, nonatomic) PRRemoteGeoPoint *location;
@property (strong, nonatomic, readonly) NSArray *likes;
@property (strong, nonatomic, readonly) NSArray *disLikes;
@property (strong, nonatomic, readonly) NSNumber *rating;

@end
