//
//  PRRootViewController.h
//  Pulsar
//
//  Created by fantom on 22.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PRRootInteractorProtocol.h"

@interface PRRootViewController : UIViewController

@property (strong, nonatomic) IBOutlet id<PRRootInteractorProtocol> interactor;

- (void)showAlertWithMessage:(NSString *)message;

@end
