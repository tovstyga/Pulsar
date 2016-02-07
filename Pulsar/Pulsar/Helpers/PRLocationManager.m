//
//  PRLocationManager.m
//  Pulsar
//
//  Created by fantom on 23.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRLocationManager.h"

@implementation PRLocationManager {
    CLLocationManager *_locationManager;
}

static PRLocationManager *sharedInstance;

- (instancetype)init
{
    if (sharedInstance) {
        return sharedInstance;
    } else {
        self = [super init];
        if (self) {
            _locationManager = [[CLLocationManager alloc] init];
            _locationManager.delegate = self;
            _locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        }
        return self;
    }
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[PRLocationManager alloc] init];
    });
    return sharedInstance;
}

- (void)startLocations
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [_locationManager startUpdatingLocation];
    } else {
        [_locationManager requestWhenInUseAuthorization];
    }
}

- (void)stopLocations
{
    [_locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [_locationManager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    _currentLocation = [locations lastObject];
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationChangedNotification object:_currentLocation];
}

- (CLLocationCoordinate2D)selectedCoordinate
{
    if (_selectedCoordinate.longitude != 0) {
        return _selectedCoordinate;
    }
    return self.currentLocation.coordinate;
}

@end
