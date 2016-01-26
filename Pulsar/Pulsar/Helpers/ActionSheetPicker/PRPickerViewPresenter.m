//
//  PRPickerViewPresenter.m
//  Pulsar
//
//  Created by fantom on 26.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRPickerViewPresenter.h"

@interface PRPickerViewPresenter()

@property (nonatomic, copy) pickerCompletion completion;

@end

@implementation PRPickerViewPresenter {
    PRActionSheetPickerView *_pickerView;
    NSArray<NSString *> *_contentArray;
    NSInteger _selectedIndex;
}

static PRPickerViewPresenter *sharedInstance;

- (instancetype)init
{
    if (sharedInstance) {
        return sharedInstance;
    } else {
        self = [super init];
        if (self) {
            _pickerView = [[PRActionSheetPickerView alloc] init];
            _pickerView.delegate = self;
            _pickerView.dataSource = self;
        }
        return self;
    }
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[PRPickerViewPresenter alloc] init];
    });
    return sharedInstance;
}

- (void)presentActionSheetInView:(UIView *)view contentData:(NSArray<NSString *> *)content completion:(pickerCompletion)completion
{
    [self presentActionSheetInView:view contentData:content selectedItem:0 completion:completion];
}

- (void)presentActionSheetInView:(UIView *)view contentData:(NSArray<NSString *> *)content selectedItem:(NSInteger)index completion:(pickerCompletion)completion
{
    if (!view) return;
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentActionSheetInView:view contentData:content completion:completion];
        });
    } else {
        if (index < 0 || index > [content count]) {
            _selectedIndex = 0;
        } else {
            _selectedIndex = index;
        }
        self.completion = completion;
        _contentArray = content;
        _pickerView.view.frame = view.frame;
        _pickerView.view.bounds = view.bounds;
        [view addSubview:_pickerView.view];
        [_pickerView showActionSheetAnimated:YES];
    }
}

- (NSInteger)selectedItem
{
    return _selectedIndex;
}

- (NSString *)titleForActionSheet
{
    return @"Categories";
}

- (void)didSelectCancelButton
{
    if (self.completion) {
        self.completion(NO, _selectedIndex);
    }
    [_pickerView hideActionSheetAnimated:YES];
}

- (void)didSelectAcceptButton
{
    if (self.completion) {
        self.completion(YES, _selectedIndex);
    }
    [_pickerView hideActionSheetAnimated:YES];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [_contentArray count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return _contentArray[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    _selectedIndex = row;
}

@end
