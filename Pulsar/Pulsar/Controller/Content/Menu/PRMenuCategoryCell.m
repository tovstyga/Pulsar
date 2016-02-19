//
//  PRMenuCategoryCell.m
//  Pulsar
//
//  Created by fantom on 21.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRMenuCategoryCell.h"
#import "PRConstants.h"
#import "PRMacros.h"

@implementation PRMenuCategoryCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIGraphicsBeginImageContext(self.contentView.frame.size);
        [[UIImage imageNamed:@"bg-cell-article"] drawInRect:self.contentView.bounds];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [self setBackgroundColor:[UIColor colorWithPatternImage:image]];
        UIView *selectedBackgroundView = [[UIView alloc] init];
        [selectedBackgroundView setBackgroundColor:[UIColor colorWithPatternImage:image]];
        [self setSelectedBackgroundView:selectedBackgroundView];
        
        [self.textLabel setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (void)setCategory:(InterestCategory *)category
{
    _category = category;
    self.textLabel.text = category.name;
    [super setSelected:[category.selected boolValue]];
    [self updateAccessory];
}

- (void)updateAccessory
{
    self.accessoryType = [self.category.selected boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

@end
