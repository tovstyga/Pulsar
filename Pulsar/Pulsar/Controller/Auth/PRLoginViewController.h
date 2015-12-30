//
//  PRLoginViewController.h
//  Pulsar
//
//  Created by fantom on 22.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRRootLoginViewController.h"
#import "RPLoginViewInteractorProtocol.h"

@interface PRLoginViewController : PRRootLoginViewController

@property (strong, nonatomic) id<RPLoginViewInteractorProtocol> interactor;

@end
