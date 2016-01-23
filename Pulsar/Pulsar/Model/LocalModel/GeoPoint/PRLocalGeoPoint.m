//
//  PRLocalGeoPoint.m
//  Pulsar
//
//  Created by fantom on 21.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRLocalGeoPoint.h"

@implementation PRLocalGeoPoint

- (instancetype)initWithLatitude:(float)latitude longitude:(float)longitude title:(NSString *)title
{
    self = [super init];
    if (self) {
        _latitude = latitude;
        _longitude = longitude;
        _title = title;
    }
    return self;
}

- (instancetype)initWithRemoteGeoPoint:(PRRemoteGeoPoint *)geoPoint
{
    return [self initWithLatitude:geoPoint.latitude longitude:geoPoint.longitude title:geoPoint.title];
}

- (id)copy
{
    return [[PRLocalGeoPoint alloc] initWithLatitude:self.latitude longitude:self.longitude title:self.title];
}

@end
