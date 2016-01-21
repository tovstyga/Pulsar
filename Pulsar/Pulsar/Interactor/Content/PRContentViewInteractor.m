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

@implementation PRContentViewInteractor

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
#warning implement reloading
    if (completion) {
        completion(YES, nil);
    }
}

- (void)loadNewDataForFeed:(PRFeedType)feedType WithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion
{
#warning implement loading
    if (completion) {
        completion(YES, nil);
    }
}

- (void)setActiveFeed:(PRFeedType)feedType
{

}

@end
