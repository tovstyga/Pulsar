//
//  PRDetailsViewController.h
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRootViewController.h"
#import "PRDetailsViewInteractorProtocol.h"
#import "PRLocalArticle.h"

@interface PRDetailsViewController : PRRootViewController<UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) id<PRDetailsViewInteractorProtocol> interactor;
@property (strong, nonatomic) PRLocalArticle *article;

@end
