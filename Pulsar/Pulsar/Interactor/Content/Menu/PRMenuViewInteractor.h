//
//  PRMenuViewInteractor.h
//  Pulsar
//
//  Created by fantom on 20.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRootViewController.h"
#import "PRMenuViewInteractorProtocol.h"
#import "PRMenuInteractorDelegateProtocol.h"

@interface PRMenuViewInteractor : NSObject<PRMenuViewInteractorProtocol>

@property (weak, nonatomic) id<PRMenuInteractorDelegate> delegate;

@end
