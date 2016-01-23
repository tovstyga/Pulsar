//
//  PRRemoteGeoPoint.m
//  Pulsar
//
//  Created by fantom on 21.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemoteGeoPoint.h"

@implementation PRRemoteGeoPoint

static NSString * const kClassName = @"GeoPoint";
static NSString * const kLatitudeKey = @"latitude";
static NSString * const kLongitudeKey = @"longitude";
static NSString * const kTitleKey = @"title"; //custom field

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

- (instancetype)initWithLocalGeoPoint:(PRLocalGeoPoint *)geoPoint
{
    return [self initWithLatitude:geoPoint.latitude longitude:geoPoint.longitude title:geoPoint.title];
}

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
    self = [super init];
    if (self && [jsonCompatableOblect isKindOfClass:[NSDictionary class]]) {
        _latitude = [[(NSDictionary *)jsonCompatableOblect objectForKey:kLatitudeKey] floatValue];
        _longitude = [[(NSDictionary *)jsonCompatableOblect objectForKey:kLongitudeKey] floatValue];
        _title = [(NSDictionary *)jsonCompatableOblect objectForKey:kTitleKey];
    }
    return self;
}

- (id)toJSONCompatable
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithDictionary:@{@"__type" : kClassName, kLatitudeKey : @(self.latitude), kLongitudeKey : @(self.longitude)}];
    if (self.title) {
        [dictionary setValue:self.title forKey:kTitleKey];
    }
    return dictionary;
}


@end
