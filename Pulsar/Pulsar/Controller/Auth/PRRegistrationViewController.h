//
//  PRRestoreAccountViewController.h
//  Pulsar
//
//  Created by fantom on 22.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRRootLoginViewController.h"
#import "RPRegistrationViewInteractorProtocol.h"

@interface PRRegistrationViewController : PRRootLoginViewController

@property (strong, nonatomic) id<RPRegistrationViewInteractorProtocol> interactor;

@end
