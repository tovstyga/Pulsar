//
//  PRRootViewController.m
//  Pulsar
//
//  Created by fantom on 22.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRConfigurator.h"
#import "PRRootViewController.h"
#import "PRAlertHelper.h"

@interface PRRootViewController ()

@end

@implementation PRRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [[PRConfigurator sharedInstance] configureViewController:segue.destinationViewController sourceViewController:segue.sourceViewController];
}

- (void)showAlertWithMessage:(NSString *)message
{
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertWithMessage:message];
        });
    } else {
        [PRAlertHelper showAlertWithMessage:message inViewController:self];
    }
}


@end
