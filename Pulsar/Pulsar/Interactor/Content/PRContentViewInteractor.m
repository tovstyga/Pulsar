//
//  PRContentViewInteractor.m
//  Pulsar
//
//  Created by fantom on 12.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRContentViewInteractor.h"
#import "PRDataProvider.h"
#import "PRErrorDescriptor.h"

@implementation PRContentViewInteractor{
    NSArray *_articles;
}

@synthesize activeFeed = _activeFeed;

- (void)logoutWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion
{
    [[PRDataProvider sharedInstance] logoutWithCompletion:^(NSError *error) {
        if (completion) {
            if (error) {
                completion(NO, [PRErrorDescriptor descriptionForError:error]);
            } else {
                completion(YES, nil);
            }
        }
    }];
}

- (void)reloadDataWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion
{
    [[PRDataProvider sharedInstance] articlesWithCompletion:^(NSArray *actilles, NSError *error) {
        if (!error) {
            _articles = actilles;
            if (completion) {
                completion(YES, nil);
            }
        } else {
            if (completion) {
                completion(NO, [PRErrorDescriptor descriptionForError:error]);
            }
        }
    }];
}

- (void)loadNewDataForFeed:(PRFeedType)feedType WithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion
{
    if (completion) {
        completion(YES, nil);
    }
}

- (void)setActiveFeed:(PRFeedType)feedType
{

}

- (NSInteger)numberOfItemsInFeed:(PRFeedType)type
{
    return [_articles count];
}

- (PRLocalArticle *)articleForFeed:(PRFeedType)type atIndex:(NSInteger)index
{
    if (index >= 0 && index < [_articles count]) {
        return _articles[index];
    }
    return nil;
}

@end
