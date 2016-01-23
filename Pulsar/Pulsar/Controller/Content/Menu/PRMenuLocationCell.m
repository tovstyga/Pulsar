//
//  PRMenuLocationCell.m
//  Pulsar
//
//  Created by fantom on 21.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRMenuLocationCell.h"

@implementation PRMenuLocationCell

- (void)setGeoPoint:(PRLocalGeoPoint *)geoPoint
{
    _geoPoint = geoPoint;
    self.textLabel.text = geoPoint.title;
}

@end
