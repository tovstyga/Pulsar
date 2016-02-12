//
//  PRLaunchScreenViewController.m
//  Pulsar
//
//  Created by fantom on 05.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRLaunchScreenViewController.h"
#import "PRContentViewController.h"
#import "PRDataProvider.h"

@implementation PRLaunchScreenViewController

static NSString * const kToContentSegueIdentifier = @"launch_to_content_segue";

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    [PRDataProvider sharedInstance];
    return [super initWithCoder:aDecoder];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[PRDataProvider sharedInstance] resumeSession:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [strongSelf performSegueWithIdentifier:kToContentSegueIdentifier sender:strongSelf];
                }
            });
        }];
    });
}

@end
