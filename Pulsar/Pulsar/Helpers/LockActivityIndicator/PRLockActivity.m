//
//  PRLockActivity.m
//  Pulsar
//
//  Created by fantom on 24.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRLockActivity.h"

@implementation PRLockActivity{
    __weak IBOutlet UIView *activityIndicatorBackground;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    activityIndicatorBackground.layer.cornerRadius = 10;
}
- (IBAction)tap:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
