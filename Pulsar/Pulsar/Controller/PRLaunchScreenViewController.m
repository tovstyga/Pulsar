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
#import "PRMacros.h"
#import "PRConstants.h"

@implementation PRLaunchScreenViewController

static NSString * const kToContentSegueIdentifier = @"launch_to_content_segue";

- (void)viewDidLoad
{
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
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 1);

    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                           shadow, NSShadowAttributeName,
                                                           [UIFont fontWithName:@"System" size:21.0], NSFontAttributeName, nil]];
    
    
    [[UINavigationBar appearance] setBarTintColor:UIColorFromRGBWithAlpha(kBarColor, 1)];
//    [[UINavigationBar appearance] setBarTintColor:[UIColor clearColor]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UITabBar appearance] setBarTintColor:UIColorFromRGBWithAlpha(kBarColor, 1)];
//    [[UITabBar appearance] setBarTintColor:[UIColor clearColor]];
    [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
    
}

@end
