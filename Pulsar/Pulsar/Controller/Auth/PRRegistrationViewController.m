//
//  PRRestoreAccountViewController.m
//  Pulsar
//
//  Created by fantom on 22.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRRegistrationViewController.h"
#import "PRMacros.h"
#import "PRConstants.h"
#import "PRScreenLock.h"

@interface PRRegistrationViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *loginTextField;
@property (weak, nonatomic) IBOutlet UITextField *mailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmTextField;

@property (weak, nonatomic) UITextField *activeTextField;

@property (nonatomic) CGFloat currentOffset;

@end

@implementation PRRegistrationViewController{
    UIColor *_greenColor;
    UIColor *_redColor;
    
    BOOL _registrationEnabled;
    BOOL _passwordConfirmed;
    BOOL _emailIsValid;
}

static NSString * const kToContentSegueIdentifier = @"registration_to_content_segue";
static int const kHeightFromKeyboard = 10;

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _greenColor = UIColorFromRGB(kHexGreenTextFieldColor);
    _redColor = UIColorFromRGB(kHexRedTextFieldColor);
    
    self.loginTextField.delegate = self;
    self.mailTextField.delegate = self;
    self.passwordTextField.delegate = self;
    self.confirmTextField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self registerForKeyboardNotifications];
    
    _passwordConfirmed = NO;
    _registrationEnabled = NO;
    _emailIsValid = NO;
    self.currentOffset = 0;
    
    for (UITextField *textField in @[self.loginTextField, self.mailTextField, self.passwordTextField, self.confirmTextField]) {
        textField.text = nil;
        [textField setBackgroundColor:_redColor];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Accessors

- (void)setCurrentOffset:(CGFloat)currentOffset
{
    if (currentOffset != _currentOffset) {
        [self moveViewTo:currentOffset];
        _currentOffset = currentOffset;
    }
}

#pragma mark - Actions

- (IBAction)cancelAction:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)registerAction:(UIButton *)sender
{
    __weak typeof(self) wSelf = self;
    [[PRScreenLock sharedInstance] lockView:self.view];
    [self.interactor registrateUser:self.loginTextField.text
                       withPassword:self.passwordTextField.text
                              email:self.mailTextField.text
                         completion:^(BOOL success, NSString *errorMessage) {
                             [[PRScreenLock sharedInstance] unlock];
                             if (wSelf) {
                                 __strong typeof(wSelf) sSelf = wSelf;
                                 if (success) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         [sSelf performSegueWithIdentifier:kToContentSegueIdentifier sender:sSelf];
                                     });
                                 } else {
                                     [sSelf showAlertWithMessage:errorMessage];
                                 }
                             }
                         }];
}

- (IBAction)tapOnViewAction:(UITapGestureRecognizer *)sender
{
    [self.passwordTextField resignFirstResponder];
    [self.loginTextField resignFirstResponder];
    [self.mailTextField resignFirstResponder];
    [self.confirmTextField resignFirstResponder];
}

#pragma mark - Events

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    if (self.activeTextField == self.passwordTextField || self.activeTextField == self.confirmTextField) {
        self.currentOffset = [self pointsToShowTextField:self.activeTextField behiedKeyboardWithHeight:kbSize.height];
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.confirmTextField || textField == self.passwordTextField) {
        self.currentOffset = 0;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    if (textField == self.loginTextField) {
        [self.mailTextField becomeFirstResponder];
    } else if (textField == self.mailTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else if (textField == self.passwordTextField) {
        [self.confirmTextField becomeFirstResponder];
    } else if (textField == self.confirmTextField) {
        if (_registrationEnabled) {
            [self registerAction:nil];
        }
    }
        
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSMutableString *newString = [NSMutableString stringWithString:textField.text];
    [string length] ? [newString insertString:string atIndex:range.location] : [newString deleteCharactersInRange:range];
    if ([string length]) {
        if (textField == self.loginTextField) {
            if (self.mailTextField.text.length && _passwordConfirmed && _emailIsValid) {
                [self enableRegistration:YES];
            }
            [textField setBackgroundColor:_greenColor];
        } else if (textField == self.mailTextField) {
            _emailIsValid = [self.interactor validateEmail:newString];
            if (_emailIsValid) {
                if (self.loginTextField.text.length && _passwordConfirmed) {
                    [self enableRegistration:YES];
                }
                [textField setBackgroundColor:_greenColor];
            }
        } else {
            [self passwordTextField:textField changedTo:newString];
            if (_passwordConfirmed && self.loginTextField.text.length && self.loginTextField.text.length && _emailIsValid) {
                [self enableRegistration:YES];
            }
        }
    } else if (textField == self.passwordTextField || textField == self.confirmTextField) {
        [self passwordTextField:textField changedTo:newString];
        [self enableRegistration:(_passwordConfirmed && _emailIsValid)];
    } else if (textField == self.mailTextField) {
        _emailIsValid = [self.interactor validateEmail:newString];
        if (!_emailIsValid) {
            [textField setBackgroundColor:_redColor];
            [self enableRegistration:NO];
        }
    } else if (textField.text.length == 1) {
        [self enableRegistration:NO];
        [textField setBackgroundColor:_redColor];
    }
    
    return YES;
}

#pragma mark - Internal

- (void)enableRegistration:(BOOL)enable;
{
    [self enableApprovalButton:enable animated:YES];
    _registrationEnabled = enable;
}

- (void)passwordTextField:(UITextField *)textField changedTo:(NSString *)newPassword
{
    _passwordConfirmed = NO;
    if ([newPassword length]) {
        if (textField == self.passwordTextField && [newPassword isEqualToString:self.confirmTextField.text]) {
            _passwordConfirmed = YES;
        } else if (textField == self.confirmTextField && [newPassword isEqualToString:self.passwordTextField.text]) {
            _passwordConfirmed = YES;
        }
    }
    
    [self.passwordTextField setBackgroundColor:_passwordConfirmed ? _greenColor : _redColor];
    [self.confirmTextField setBackgroundColor:_passwordConfirmed ? _greenColor : _redColor];
}

- (void)moveViewTo:(CGFloat)yPosition
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.35f];
    CGRect frame = self.view.frame;
    frame.origin.y = yPosition;
    [self.view setBounds:frame];
    [UIView commitAnimations];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
}

- (CGFloat)pointsToShowTextField:(UITextField *)textField behiedKeyboardWithHeight:(CGFloat)height
{
    if (textField.frame.origin.y + textField.frame.size.height + kHeightFromKeyboard > self.view.frame.size.height - height) {
        return height - (self.view.frame.size.height - (textField.frame.origin.y + textField.frame.size.height + kHeightFromKeyboard));
    }
    return 0;
}

@end
