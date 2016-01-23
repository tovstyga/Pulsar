//
//  PRRemoteGeoPoint.h
//  Pulsar
//
//  Created by fantom on 21.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRJsonCompatable.h"
#import "PRLocalGeoPoint.h"

@class PRLocalGeoPoint;

@interface PRRemoteGeoPoint : NSObject<PRJsonCompatable>

@property (nonatomic, readonly) float latitude;
@property (nonatomic, readonly) float longitude;
@property (nonatomic, strong, readonly) NSString *title;

- (instancetype)initWithLatitude:(float)latitude longitude:(float)longitude title:(NSString *)title;
- (instancetype)initWithLocalGeoPoint:(PRLocalGeoPoint *)geoPoint;

@end
