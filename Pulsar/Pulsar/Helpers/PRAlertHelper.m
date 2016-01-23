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

+ (void)showAlertInputDialogWithTitle:(NSString *)title
                              message:(NSString *)message
                   rootViewController:(UIViewController *)parent
                           completion:(void (^)(BOOL, NSString *))completion
{
    __block UITextField *inputTextField = nil;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        inputTextField = textField;
    }];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if (completion) {
            completion(YES, inputTextField.text);
        }
    }];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (completion) {
            completion(NO, nil);
        }
    }];
    
    [alert addAction:ok];
    [alert addAction:cancel];
    [parent presentViewController:alert animated:YES completion:nil];
}

@end
