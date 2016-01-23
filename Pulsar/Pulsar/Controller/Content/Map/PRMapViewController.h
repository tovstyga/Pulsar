//
//  PRMapViewController.h
//  Pulsar
//
//  Created by fantom on 21.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRootViewController.h"
#import "PRMapViewInteractorProtocol.h"
#import <MapKit/MapKit.h>

@interface PRMapViewController : PRRootViewController<MKMapViewDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) id<PRMapViewInteractorProtocol> interactor;

@end
