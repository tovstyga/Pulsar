//
//  PRLocalGeoPoint.h
//  Pulsar
//
//  Created by fantom on 21.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRRemoteGeoPoint.h"

@class PRRemoteGeoPoint;

@interface PRLocalGeoPoint : NSObject

@property (nonatomic, readonly) float latitude;
@property (nonatomic, readonly) float longitude;
@property (nonatomic, strong, readonly) NSString *title;

- (instancetype)initWithLatitude:(float)latitude longitude:(float)longitude title:(NSString *)title;
- (instancetype)initWithRemoteGeoPoint:(PRRemoteGeoPoint *)geoPoint;

@end
