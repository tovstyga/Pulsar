//
//  PRPickerViewPresenter.h
//  Pulsar
//
//  Created by fantom on 26.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRActionSheetPickerView.h"

typedef void(^pickerCompletion)(BOOL accept, NSInteger lastSelectedIndex);

@interface PRPickerViewPresenter : NSObject<PRActionSheetPickerViewDataSource, PRActionSheetPickerViewDelegate>

+ (instancetype)sharedInstance;

- (void)presentActionSheetInView:(UIView *)view contentData:(NSArray<NSString *> *)content completion:(pickerCompletion)completion;

- (void)presentActionSheetInView:(UIView *)view contentData:(NSArray<NSString *> *)content selectedItem:(NSInteger)index completion:(pickerCompletion)completion;

@end
