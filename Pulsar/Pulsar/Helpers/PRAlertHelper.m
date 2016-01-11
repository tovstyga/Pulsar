//
//  PRAlertHelper.m
//  Pulsar
//
//  Created by fantom on 05.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PRAlertHelper.h"

@implementation PRAlertHelper

+ (void)showAlertWithMessage:(NSString *)message inViewController:(UIViewController *)parent
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Info" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alert addAction:action];
    [parent presentViewController:alert animated:YES completion:nil];
}

@end
