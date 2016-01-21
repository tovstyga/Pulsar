//
//  PRContentViewInteractorProtocol.h
//  Pulsar
//
//  Created by fantom on 12.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

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

- (void)loadNewDataForFeed:(PRFeedType)feedType WithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion;

@end