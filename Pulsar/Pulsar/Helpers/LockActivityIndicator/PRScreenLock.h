//
//  PRScreenLock.h
//  Pulsar
//
//  Created by fantom on 11.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PRScreenLock : NSObject

+ (instancetype)sharedInstance;

- (void)lockView:(UIView *)view;

- (void)lockView:(UIView *)view animated:(BOOL)animated;

- (void)unlock;

- (void)unlockAnimated:(BOOL)animated;

@end
