//
//  PRActionSheetPickerView.m
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRActionSheetPickerView.h"

@interface PRActionSheetPickerView() <UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *shadowView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toTopConstraint;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *acceptButton;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@end

@implementation PRActionSheetPickerView {
    float _openedConstraintConstant;
    float _closedConstraintConstant;
}

- (void)viewDidLoad
{
     self.pickerView.dataSource = self.dataSource;
     self.pickerView.delegate = self.delegate;
}

- (void)viewWillAppear:(BOOL)animated{
    _openedConstraintConstant = self.view.frame.size.height - self.contentView.frame.size.height;
    _closedConstraintConstant = self.view.frame.size.height;
    [self.toTopConstraint setConstant:self.shadowView.frame.size.height];
    [self.view setNeedsLayout];
}

#pragma mark - Accessors

- (void)setDataSource:(id<PRActionSheetPickerViewDataSource>)dataSource
{
    _dataSource = dataSource;
    self.pickerView.dataSource = dataSource;
}

-  (void)setDelegate:(id<PRActionSheetPickerViewDelegate>)delegate
{
    _delegate = delegate;
    self.pickerView.delegate = delegate;
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 0;
}

#pragma mark - Actions

- (IBAction)cancelAction:(UIBarButtonItem *)sender
{
    if ([self.delegate respondsToSelector:@selector(didSelectCancelButton)]) {
        [self.delegate didSelectCancelButton];
    } else {
        [self hideActionSheetAnimated:YES];
    }
}

- (IBAction)acceptAction:(UIBarButtonItem *)sender
{
    if ([self.delegate respondsToSelector:@selector(didSelectAcceptButton)]) {
        [self.delegate didSelectAcceptButton];
    } else {
        [self hideActionSheetAnimated:YES];
    }
}

- (IBAction)tapOnShadowView:(UITapGestureRecognizer *)sender
{
    [self cancelAction:nil];
}

#pragma mark - Public

- (void)showActionSheetAnimated:(BOOL)animated
{
    if ([self.dataSource respondsToSelector:@selector(titleForActionSheet)]) {
        self.navigationBar.topItem.title = [self.dataSource titleForActionSheet];
    }
    
    if ([self.dataSource respondsToSelector:@selector(titleForCancelButton)]) {
        self.cancelButton.title = [self.dataSource titleForCancelButton];
    }
    
    if ([self.dataSource respondsToSelector:@selector(titleForAcceptButton)]) {
        self.acceptButton.title = [self.dataSource titleForAcceptButton];
    }
    
    [self.pickerView reloadAllComponents];
    
    if ([self.dataSource respondsToSelector:@selector(selectedItem)]) {
        [self.pickerView selectRow:[self.dataSource selectedItem] inComponent:0 animated:YES];
    }
    
    self.toTopConstraint.constant = _openedConstraintConstant;
    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            self.shadowView.alpha = 1;
            [self.view layoutIfNeeded];
        }];
    } else {
        self.shadowView.alpha = 1;
    }
}

- (void)hideActionSheetAnimated:(BOOL)animated
{
    self.toTopConstraint.constant = _closedConstraintConstant;
    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            self.shadowView.alpha = 0;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self.view removeFromSuperview];
        }];
    } else {
        self.shadowView.alpha = 1;
        [self.view removeFromSuperview];
    }
}

@end
