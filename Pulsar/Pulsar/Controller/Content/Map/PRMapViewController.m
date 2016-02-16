//
//  PRMapViewController.m
//  Pulsar
//
//  Created by fantom on 21.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRMapViewController.h"
#import "PRMapAnnotation.h"
#import "PRAlertHelper.h"
#import "PRScreenLock.h"

@interface PRMapViewController()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) PRMapAnnotation *annotation;

@end

@implementation PRMapViewController{
    dispatch_once_t once;
}

@synthesize interactor;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self startLocations];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self applyMapViewMemoryFix];
}

#pragma mark - Actions

- (IBAction)closeAction:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveLocationAction:(UIBarButtonItem *)sender
{
    __weak typeof(self) wSelf = self;
    [PRAlertHelper showAlertInputDialogWithTitle:@"Approval." message:@"Please. Enter name for selected geopoint." rootViewController:self completion:^(BOOL accept, NSString *text) {
        if (accept) {
            if (![text length]) {
                [PRAlertHelper showAlertWithMessage:@"Name can't be empty." inViewController:self];
            } else {
                [[PRScreenLock sharedInstance] lockView:self.view animated:YES];
                [self.interactor addPointWithName:text longitude:self.annotation.coordinate.longitude latitude:self.annotation.coordinate.latitude completion:^(BOOL success, NSString *errorMessage) {
                    [[PRScreenLock sharedInstance] unlockAnimated:YES];
                    __strong typeof(wSelf) sSelf = wSelf;
                    if (sSelf) {
                        if (!success) {
                            [sSelf showAlertWithMessage:errorMessage];
                        } else {
                            [sSelf closeAction:nil];
                        }
                    }
                }];
            }
        }
    }];
}

#pragma mark - CLLocationManager

- (CLLocationManager *)locationManager
{
    
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
    return _locationManager;
}

- (void)startLocations
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager startUpdatingLocation];
    } else {
        [self.locationManager requestWhenInUseAuthorization];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    dispatch_once(&once, ^{
        CLLocation *currentLocation = [locations lastObject];
        
        self.annotation = [[PRMapAnnotation alloc] init];
        [self.annotation setCoordinate:[currentLocation coordinate]];
        [self.mapView addAnnotation:self.annotation];
        
        MKCoordinateRegion region;
        region.center.latitude = currentLocation.coordinate.latitude;
        region.center.longitude = currentLocation.coordinate.longitude;
        region.span.latitudeDelta = 0.001;
        region.span.longitudeDelta = 0.001;
        [self.mapView setRegion:region animated:YES];
    });
    
    [self.locationManager stopUpdatingLocation];
}


#pragma mark - MapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[PRMapAnnotation class]]) {
        MKPinAnnotationView *pin = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"pin"];
        if (pin == nil) {
            pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"];
        } else {
            pin.annotation = annotation;
        }
        pin.animatesDrop = YES;
        pin.draggable = YES;
        return pin;
    } else {
        return nil;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState
   fromOldState:(MKAnnotationViewDragState)oldState
{
    if (newState == MKAnnotationViewDragStateEnding)
    {
        CLLocationCoordinate2D droppedAt = view.annotation.coordinate;
        [view.annotation setCoordinate:droppedAt];
    }
}

- (void)applyMapViewMemoryFix{
    
    switch (self.mapView.mapType) {
        case MKMapTypeHybrid:
        {
            self.mapView.mapType = MKMapTypeStandard;
        }
            
            break;
        case MKMapTypeStandard:
        {
            self.mapView.mapType = MKMapTypeHybrid;
        }
            
            break;
        default:
            break;
    }
    [self.mapView removeAnnotation:self.annotation];
    self.annotation = nil;
    self.mapView.showsUserLocation = NO;
    self.mapView.delegate = nil;
    [self.mapView removeFromSuperview];
    self.mapView = nil;
}

@end
