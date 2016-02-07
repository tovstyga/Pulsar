//
//  PRMenuLocationCell.h
//  Pulsar
//
//  Created by fantom on 21.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PRLocalGeoPoint.h"

@interface PRMenuLocationCell : UITableViewCell

@property (strong, nonatomic) PRLocalGeoPoint *geoPoint;
@property (nonatomic) BOOL checked;

@end
