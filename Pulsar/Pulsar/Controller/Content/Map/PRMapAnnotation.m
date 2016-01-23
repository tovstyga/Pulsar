//
//  PRMapAnnotation.m
//  Pulsar
//
//  Created by fantom on 22.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRMapAnnotation.h"

@implementation PRMapAnnotation

@synthesize coordinate = _coordinate,
title = _title,
subtitle = _subtitle;

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    _coordinate = newCoordinate;
}

@end
