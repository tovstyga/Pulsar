//
//  PRConfigurator.h
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PRConfigurator : NSObject

+ (instancetype)sharedInstance;

- (void)configureViewController:(UIViewController *)viewController sourceViewController:(UIViewController *)sourceViewController;

@end
