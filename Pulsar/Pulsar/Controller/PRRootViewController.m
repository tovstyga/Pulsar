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
#import "PRLocalDataStore.h"

@interface PRRootViewController ()

@end

@implementation PRRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyCustomBackground];
}

- (void)didReceiveMemoryWarning {
    
    [[[PRLocalDataStore sharedInstance] backgroundContext] performBlock:^{
        [[[PRLocalDataStore sharedInstance] backgroundContext] refreshAllObjects];
    }];
    
    [[[PRLocalDataStore sharedInstance] mainContext] performBlock:^{
        [[[PRLocalDataStore sharedInstance] mainContext] refreshAllObjects];
    }];
    
    [super didReceiveMemoryWarning];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(BOOL)prefersStatusBarHidden
{
    return NO;
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

- (void)applyCustomBackground
{
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"bg-world"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
}


@end
