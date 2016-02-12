//
//  PRImagePresenter.m
//  Pulsar
//
//  Created by fantom on 29.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRImagePresenter.h"
#import "PRDataProvider.h"
#import "PRAlertHelper.h"

@interface PRImagePresenter ()

@property (weak, nonatomic) IBOutlet UIView *shadowView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation PRImagePresenter

- (void)presentFromParentViewController:(UIViewController *)parentViewController animated:(BOOL)flag completion:(void (^)(void))completion
{
    if (!self.delegate) {
        if (completion) {
            completion();
        }
        return;
    }
    self.view.frame = parentViewController.view.frame;
    [parentViewController.view addSubview:self.view];
    self.activityIndicator.hidden = NO;
    self.imageView.alpha = 0;
    if (flag) {
        [UIView animateWithDuration:0.5f animations:^{
            self.shadowView.alpha = 1;
        } completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    }
    [self.delegate loadImageWithCompletion:^(UIImage *image, NSString *errorMessage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image) {
                [self.imageView setImage:image];
                self.activityIndicator.hidden = YES;
                [UIView animateWithDuration:0.5f animations:^{
                    self.imageView.alpha = 1;
                }];
            } else {
                [PRAlertHelper showAlertWithMessage:errorMessage inViewController:self];
            }
        });
    }];
    if (!flag && completion) {
        completion();
    }
}

- (IBAction)closeAction:(UIButton *)sender
{
    self.activityIndicator.hidden = YES;
    [UIView animateWithDuration:0.5f animations:^{
        self.shadowView.alpha = 0;
        self.imageView.alpha = 0;
    } completion:^(BOOL finished) {
        self.imageView.image = nil;
        [self.view removeFromSuperview];
        if ([self.delegate respondsToSelector:@selector(imagePresenterDidClose)]) {
            [self.delegate imagePresenterDidClose];
        }
    }];
    
}

@end
