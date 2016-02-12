//
//  PRRegistrationViewController.m
//  Pulsar
//
//  Created by fantom on 22.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRRestoreAccountViewController.h"
#import "PRScreenLock.h"

@interface PRRestoreAccountViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

@end

@implementation PRRestoreAccountViewController

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.emailTextField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.emailTextField.text = nil;
}

#pragma mark - Actions

- (IBAction)sendPasswordAction:(UIButton *)sender
{
    __weak typeof(self) wSelf = self;
    [[PRScreenLock sharedInstance] lockView:self.view];
    [self.interactor restoreAccountForEmail:self.emailTextField.text completion:^(BOOL success, NSString *errorMessage) {
        [[PRScreenLock sharedInstance] unlock];
        if (wSelf) {
            __strong typeof(wSelf) sSelf = wSelf;
            if (success) {
                [sSelf cancelAction:sender];
            } else {
                [sSelf showAlertWithMessage:errorMessage];
            }
        }
    }];
}

- (IBAction)cancelAction:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    
    NSMutableString *newString = [NSMutableString stringWithString:self.emailTextField.text];
    [string length] ? [newString insertString:string atIndex:range.location] : [newString deleteCharactersInRange:range];
    if ([self.interactor validateEmail:newString]) {
        [self enableApprovalButton:YES animated:YES];
    } else {
        [self enableApprovalButton:NO animated:YES];
    }
    
    return YES;
}

- (IBAction)tapOnView:(UITapGestureRecognizer *)sender
{
    [self.emailTextField resignFirstResponder];
}
#pragma mark - Internal

@end
