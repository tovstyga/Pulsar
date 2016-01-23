//
//  PRAlertHelper.h
//  Pulsar
//
//  Created by fantom on 05.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PRAlertHelper : NSObject

+ (void)showAlertWithMessage:(NSString *)message inViewController:(UIViewController *)parent;

+ (void)showAlertInputDialogWithTitle:(NSString *)title
                              message:(NSString *)message
                   rootViewController:(UIViewController *)parent
                           completion:(void(^)(BOOL accept, NSString *text))completion;

@end
