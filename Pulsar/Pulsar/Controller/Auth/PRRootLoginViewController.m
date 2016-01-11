//
//  PRRootLoginViewController.m
//  Pulsar
//
//  Created by fantom on 24.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRRootLoginViewController.h"
#import "PRAlertHelper.h"

@interface PRRootLoginViewController ()

@property (weak, nonatomic) IBOutlet UIButton *approvalButton;

@end

@implementation PRRootLoginViewController

#pragma mark - LifeCycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self enableApprovalButton:NO animated:NO];
}

#pragma mark - Public

- (void)enableApprovalButton:(BOOL)enable animated:(BOOL)animated
{
    if (self.approvalButton.enabled != enable) {
        self.approvalButton.enabled = enable;
        if (animated) {
            [UIView animateWithDuration:0.2 animations:^{
                self.approvalButton.alpha = enable ? 1 : 0.5;
                [self.approvalButton setNeedsLayout];
            }];
        } else {
            self.approvalButton.alpha = enable ? 1 : 0.5;
        }
    }
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
