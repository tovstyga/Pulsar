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

- (void)setChecked:(BOOL)checked
{
    _checked = checked;
    self.accessoryType = checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (void)setSelected:(BOOL)selected
{
    self.checked = selected;
    [super setSelected:selected];
}

@end
