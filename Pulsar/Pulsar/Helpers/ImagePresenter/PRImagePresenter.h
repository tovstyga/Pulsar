//
//  PRImagePresenter.h
//  Pulsar
//
//  Created by fantom on 29.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PRImagePresenterDataSource <NSObject>

@required

- (void)loadImageWithCompletion:(void(^)(UIImage *image, NSString *errorMessage))completion;

@optional

- (void)imagePresenterDidClose;

@end

@interface PRImagePresenter : UIViewController

@property (weak, nonatomic) id<PRImagePresenterDataSource> delegate;

- (void)presentFromParentViewController:(UIViewController *)parentViewController animated:(BOOL)flag completion:(void (^)(void))completion;

@end
