//
//  PRCreationCollectionViewCell.m
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRCreationCollectionViewCell.h"

@implementation PRCreationCollectionViewCell

- (void)prepareForReuse
{
    self.imageView.image = nil;
    [super prepareForReuse];
}

@end
