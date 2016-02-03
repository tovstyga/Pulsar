//
//  PRLocalNewArticle.h
//  Pulsar
//
//  Created by fantom on 26.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PRLocalCategory.h"
#import "PRLocalGeoPoint.h"
#import "InterestCategory.h"

@interface PRLocalNewArticle : NSObject

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *annotation;
@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) InterestCategory *category;
@property (strong, nonatomic) NSArray<UIImage *> *images;
@property (strong, nonatomic) PRLocalGeoPoint *location;

@end
