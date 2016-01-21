//
//  PRMenuViewController.h
//  Pulsar
//
//  Created by fantom on 20.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRootViewController.h"
#import "PRMenuViewInteractorProtocol.h"
#import "PRContentViewDelegateProtocol.h"

@interface PRMenuViewController : PRRootViewController<PRContentViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) id<PRMenuViewInteractorProtocol> interactor;

@end
