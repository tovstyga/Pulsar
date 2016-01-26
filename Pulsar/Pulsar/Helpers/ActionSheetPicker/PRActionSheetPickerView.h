//
//  PRActionSheetPickerView.h
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PRActionSheetPickerViewDelegate <UIPickerViewDelegate>

@optional

- (void)didSelectCancelButton;
- (void)didSelectAcceptButton;

@end

@protocol PRActionSheetPickerViewDataSource <UIPickerViewDataSource>

@optional

- (NSString *)titleForCancelButton;
- (NSString *)titleForAcceptButton;
- (NSString *)titleForActionSheet;

- (NSInteger)selectedItem;

@end

@interface PRActionSheetPickerView : UIViewController

@property (weak, nonatomic) id<PRActionSheetPickerViewDataSource> dataSource;
@property (weak, nonatomic) id<PRActionSheetPickerViewDelegate> delegate;

- (void)showActionSheetAnimated:(BOOL)animated;
- (void)hideActionSheetAnimated:(BOOL)animated;

@end
