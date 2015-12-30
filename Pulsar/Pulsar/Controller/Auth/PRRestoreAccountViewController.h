//
//  PRRegistrationViewController.h
//  Pulsar
//
//  Created by fantom on 22.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRRootLoginViewController.h"
#import "PRRestoreAccountViewInteractorProtocol.h"

@interface PRRestoreAccountViewController : PRRootLoginViewController

@property (strong, nonatomic) id<PRRestoreAccountViewInteractorProtocol> interactor;

@end
