//
//  PRLoginViewController.m
//  Pulsar
//
//  Created by fantom on 22.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRLoginViewController.h"
#import "PRLoginViewInteractor.h"
#import "PRAlertHelper.h"
#import "PRScreenLock.h"

@interface PRLoginViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *loginTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation PRLoginViewController

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.loginTextField.delegate = self;
    self.passwordTextField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.loginTextField.text = nil;
    self.passwordTextField.text = nil;
}

#pragma mark - Actions

- (IBAction)loginAction:(UIButton *)sender
{
    __weak typeof(self) wSelf = self;
    [[PRScreenLock sharedInstance] lockView:self.view];
    [self.interactor loginUser:self.loginTextField.text
                  withPassword:self.passwordTextField.text
                    completion:^(BOOL success, NSString *errorMessage) {
                        [[PRScreenLock sharedInstance] unlock];
                        if (wSelf) {
                            __strong typeof(wSelf) sSelf = wSelf;
                            if (success) {
#warning navigate to content view
                            } else {
                                [sSelf showAlertWithMessage:errorMessage];
                            }
                        }
                    }];
}

- (IBAction)tapOnView:(UITapGestureRecognizer *)sender
{
    [self.loginTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
}
#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    if (textField == self.loginTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else if ([self.loginTextField.text length] && [self.passwordTextField.text length]) {
        [self loginAction:nil];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (((textField == self.loginTextField) && [self.passwordTextField.text length] && [string length]) ||
        ((textField == self.passwordTextField) && [self.loginTextField.text length] && [string length])) {
        [self enableApprovalButton:YES animated:YES];
    } else if ((textField.text.length == 1) && (string.length == 0)) {
        [self enableApprovalButton:NO animated:YES];
    }
        
    return YES;
}

#pragma mark - Internal

@end
