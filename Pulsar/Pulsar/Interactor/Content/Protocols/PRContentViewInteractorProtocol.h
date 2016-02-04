//
//  PRContentViewInteractorProtocol.h
//  Pulsar
//
//  Created by fantom on 12.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "Article.h"

typedef NS_ENUM(NSUInteger, PRFeedType) {
    PRFeedTypeNew,
    PRFeedTypeHot,
    PRFeedTypeTop,
    PRFeedTypeCreated,
    PRFeedTypeFavorites
};

@protocol PRContentViewInteractorProtocol <NSObject>

@property (nonatomic) PRFeedType activeFeed;

- (void)logoutWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion;

- (void)reloadDataWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion;

- (void)loadNewDataWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion;

- (NSInteger)numberOfSections;

- (NSInteger)numberOfItemsInSection:(NSInteger)section;

- (Article *)articleAtIndex:(NSInteger)index inSection:(NSInteger)section;

- (NSString *)titleForHeaderInSection:(NSInteger)section;

- (BOOL)isDataAvailable;

- (BOOL)canLoadMore;

@end