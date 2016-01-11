//
//  PRScreenLock.m
//  Pulsar
//
//  Created by fantom on 11.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRScreenLock.h"
#import "PRLockActivity.h"

@implementation PRScreenLock{
    PRLockActivity *lockActivity;
}

static PRScreenLock *sharedInstance;

- (instancetype)init
{
    if (sharedInstance) {
        return sharedInstance;
    } else {
        self = [super init];
        if (self) {
            lockActivity = [[PRLockActivity alloc] init];
        }
        return self;
    }
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[PRScreenLock alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Public

- (void)lockView:(UIView *)view animated:(BOOL)animated
{
    if (!view) return;
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self lockView:view animated:animated];
        });
    } else {
        [lockActivity.view setBounds:view.bounds];
        [lockActivity.view setFrame:view.frame];
        [lockActivity.view setAlpha:0.f];
        [view addSubview:lockActivity.view];
        if (animated) {
            [UIView animateWithDuration:0.3f animations:^{
                [lockActivity.view setAlpha:1.f];
            }];
        } else {
            [lockActivity.view setAlpha:1.f];
        }
    }
}

- (void)unlockAnimated:(BOOL)animated
{
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self unlockAnimated:animated];
        });
    } else {
        if (animated) {
            [UIView animateWithDuration:0.3f animations:^{
                [lockActivity.view setAlpha:0.f];
            } completion:^(BOOL finished) {
                [lockActivity.view removeFromSuperview];
            }];
        } else {
            [lockActivity.view setAlpha:0.f];
            [lockActivity.view removeFromSuperview];
        }
    }
}

- (void)lockView:(UIView *)view
{
    [self lockView:view animated:YES];
}

- (void)unlock
{
    [self unlockAnimated:YES];
}

@end
