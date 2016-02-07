//
//  PRLocationManager.h
//  Pulsar
//
//  Created by fantom on 23.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

static NSString * const kLocationChangedNotification = @"current_location_changed_notification";

@interface PRLocationManager : NSObject<CLLocationManagerDelegate>

@property (strong, nonatomic, readonly) CLLocation *currentLocation;
@property (nonatomic) CLLocationCoordinate2D selectedCoordinate;

+ (instancetype)sharedInstance;

- (void)startLocations;

- (void)stopLocations;

@end
