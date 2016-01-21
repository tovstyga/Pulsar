//
//  PRContentViewController.h
//  Pulsar
//
//  Created by fantom on 12.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRootViewController.h"
#import "PRContentViewInteractorProtocol.h"
#import "PRContentViewDelegateProtocol.h"
#import "PRMenuInteractorDelegateProtocol.h"

@interface PRContentViewController : PRRootViewController<PRMenuInteractorDelegate>

@property (strong, nonatomic) id<PRContentViewInteractorProtocol> interactor;

@property (weak, nonatomic) id<PRContentViewDelegate> delegate;

@end
