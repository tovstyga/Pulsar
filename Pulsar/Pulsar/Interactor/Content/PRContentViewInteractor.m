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
#import "PRArticleCollection.h"

@implementation PRContentViewInteractor{
    NSMutableArray *_hotArticles;
    NSMutableArray *_newArticles;
    PRArticleCollection *_topArticles;
    NSMutableArray *_favoriteArticles;
    NSMutableArray *_createdArticles;
    
    BOOL _isDataAvailable;
    
    BOOL _canMoreHot;
    BOOL _canMoreNew;
}

@synthesize activeFeed = _activeFeed;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _hotArticles = [NSMutableArray new];
        _newArticles = [NSMutableArray new];
        _topArticles = [[PRArticleCollection alloc] init];
        _favoriteArticles = [NSMutableArray new];
        _createdArticles = [NSMutableArray new];
    }
    return self;
}

- (BOOL)isLogined
{
    return self.dataProvider.currentUser;
}

- (void)logoutWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion
{
    __weak typeof(self) wSelf = self;
    [self.dataProvider logoutWithCompletion:^(NSError *error) {
        if (completion) {
            if (error) {
                completion(NO, [wSelf.errorDescriptor descriptionForError:error]);
            } else {
                _hotArticles = [NSMutableArray new];
                _newArticles = [NSMutableArray new];
                _topArticles = [[PRArticleCollection alloc] init];
                _favoriteArticles = [NSMutableArray new];
                _createdArticles = [NSMutableArray new];
                completion(YES, nil);
            }
        }
    }];
}

- (void)thumbnailForMedia:(Media *)media completion:(void(^)(UIImage *image, NSError *error))completion
{
    if (!media.thumbnailURL && completion) {
        completion(nil, nil);
    } else {
        [self.dataProvider loadThumbnailForMedia:media completion:^(UIImage *image, NSError *error) {
            if (!error) {
                if (completion) {
                    completion(image, error);
                }
            } else {
                if (completion) {
                    completion(nil, error);
                }
            }
        }];
    }
}

- (void)reloadDataWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion
{
    __weak typeof(self) wSelf = self;
    switch (self.activeFeed) {
        case PRFeedTypeTop:
        {
            [self.dataProvider refreshTopArticlesWithCompletion:^(PRArticleCollection *articles, NSError *error) {
                if (!error) {
                    _topArticles = articles;
                    [self changeDataAvailable];
                    if (completion) {
                        completion(YES, nil);
                    }
                } else if (completion) {
                    if (articles) {
                        _topArticles = articles;
                        [self changeDataAvailable];
                        completion(YES, [wSelf.errorDescriptor descriptionForError:error]);
                    } else {
                        completion(NO, [wSelf.errorDescriptor descriptionForError:error]);
                    }
                }
            }];
            break;
        }
        case PRFeedTypeCreated:
        {
            [self.dataProvider allMyArticles:^(NSArray *articles, NSError *error) {
                if (!error) {
                    _createdArticles = [[NSMutableArray alloc] initWithArray:articles];
                    [self changeDataAvailable];
                    if (completion) {
                        completion(YES, nil);
                    }
                } else if (completion) {
                    if (articles) {
                        _createdArticles = [[NSMutableArray alloc] initWithArray:articles];
                        [self changeDataAvailable];
                        completion(YES, [wSelf.errorDescriptor descriptionForError:error]);
                    } else {
                        completion(NO, [wSelf.errorDescriptor descriptionForError:error]);
                    }                }
            }];
            break;
        }
        case PRFeedTypeFavorites:
        {
            [self.dataProvider favoriteArticles:^(NSArray *articles, NSError *error) {
                if (!error) {
                    _favoriteArticles = [[NSMutableArray alloc] initWithArray:articles];
                    [self changeDataAvailable];
                    if (completion) {
                        completion(YES, nil);
                    }
                } else if (completion) {
                    if (articles) {
                        _favoriteArticles = [[NSMutableArray alloc] initWithArray:articles];
                        [self changeDataAvailable];
                        completion(YES, [wSelf.errorDescriptor descriptionForError:error]);
                    } else {
                        completion(NO, [wSelf.errorDescriptor descriptionForError:error]);
                    }
                }
            }];
            break;
        }
        case PRFeedTypeHot:
        {
            [self.dataProvider refreshHotArticlesWithCompletion:^(NSArray *articles, NSError *error) {
                if (!error) {
                    _hotArticles = [[NSMutableArray alloc] initWithArray:articles];
                    _canMoreHot = [articles count];
                    [self changeDataAvailable];
                    if (completion) {
                        completion(YES, nil);
                    }
                } else if (completion) {
                    if (articles) {
                        _hotArticles = [[NSMutableArray alloc] initWithArray:articles];
                        _canMoreHot = [articles count];
                        [self changeDataAvailable];
                        completion(YES, [wSelf.errorDescriptor descriptionForError:error]);
                    } else {
                        completion(NO, [wSelf.errorDescriptor descriptionForError:error]);
                    }
                }
            }];
            break;
        }
        case PRFeedTypeNew:
        {
            [self.dataProvider refreshNewArticlesWithCompletion:^(NSArray *articles, NSError *error) {
                if (!error) {
                    _newArticles = [[NSMutableArray alloc] initWithArray:articles];
                    _canMoreNew = [articles count];
                    [self changeDataAvailable];
                    if (completion) {
                        completion(YES, nil);
                    }
                } else if (completion) {
                    if (articles) {
                        _newArticles = [[NSMutableArray alloc] initWithArray:articles];
                        _canMoreNew = [articles count];
                        [self changeDataAvailable];
                        completion(YES, [wSelf.errorDescriptor descriptionForError:error]);
                    } else {
                        completion(NO, [wSelf.errorDescriptor descriptionForError:error]);
                    }
                }

            }];
            break;
        }
        default:
            if (completion) {
                completion(YES, nil);
            }
            break;
    }
}

- (void)loadNewDataWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion
{
    __weak typeof(self) wSelf = self;
    switch (self.activeFeed) {
        case PRFeedTypeTop:
        {
            [self reloadDataWithCompletion:completion];
            break;
        }
        case PRFeedTypeCreated:
        {
            [self reloadDataWithCompletion:completion];
            break;
        }
        case PRFeedTypeFavorites:
        {
            [self reloadDataWithCompletion:completion];
            break;
        }
        case PRFeedTypeHot:
        {
            [self.dataProvider loadNextHotArticlesWithCompletion:^(NSArray *articles, NSError *error) {
                if (!error) {
                    [_hotArticles addObjectsFromArray:articles];
                    _canMoreHot = [articles count];
                    [self changeDataAvailable];
                    if (completion) {
                        completion(YES, nil);
                    }
                } else if (completion) {
                    completion(NO, [wSelf.errorDescriptor descriptionForError:error]);
                }
            }];
            break;
        }
        case PRFeedTypeNew:
        {
            [self.dataProvider loadNextNewArticlesWithCompletion:^(NSArray *articles, NSError *error) {
                if (!error) {
                    [_newArticles addObjectsFromArray:articles];
                    _canMoreNew = [articles count];
                    [self changeDataAvailable];
                    if (completion) {
                        completion(YES, nil);
                    }
                } else if (completion) {
                    completion(NO, [wSelf.errorDescriptor descriptionForError:error]);
                }
            }];
            break;
        }
        default:
            if (completion) {
                completion(YES, nil);
            }
            break;
    }
}

- (void)setActiveFeed:(PRFeedType)feedType
{
    _activeFeed = feedType;
    [self changeDataAvailable];
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    switch (self.activeFeed) {
        case PRFeedTypeCreated:
            return [_createdArticles count];
        case PRFeedTypeFavorites:
            return [_favoriteArticles count];
        case PRFeedTypeHot:
            return [_hotArticles count];
        case PRFeedTypeNew:
            return [_newArticles count];
        case PRFeedTypeTop:
            return [[_topArticles fetchResultForKey:section] count];
        default:
            return 0;
    }
}

- (Article *)articleAtIndex:(NSInteger)index inSection:(NSInteger)section
{
    NSArray *template = nil;
    switch (self.activeFeed) {
        case PRFeedTypeCreated:
            template = _createdArticles;
            break;
        case PRFeedTypeFavorites:
            template = _favoriteArticles;
            break;
        case PRFeedTypeHot:
            template = _hotArticles;
            break;
        case PRFeedTypeNew:
            template = _newArticles;
            break;
        case PRFeedTypeTop:
            template = [_topArticles fetchResultForKey:section];
            break;
        default:
            break;
    }
    
    if (index >= 0 && index < [template count]) {
        return template[index];
    }
    return nil;
}

- (NSInteger)numberOfSections
{
    if (self.activeFeed == PRFeedTypeTop) {
        return 5;
    }
    return 1;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    if (self.activeFeed == PRFeedTypeTop) {
        return [self titleForSection:section];
    }
    return nil;
}

- (NSString *)titleForSection:(PRArticleFetch)fetch
{
    switch (fetch) {
        case PRArticleFetchHour:
            return @"In an hour";
        case PRArticleFetchDay:
            return @"In an day";
        case PRArticleFetchWeek:
            return @"In an week";
        case PRArticleFetchMonth:
            return @"In an month";
        case PRArticleFetchYear:
            return @"In an year";
        default:
            return @"";
    }
}

- (BOOL)isDataAvailable
{
    return _isDataAvailable;
}

- (void)changeDataAvailable
{
    if (self.activeFeed == PRFeedTypeTop) {
        _isDataAvailable = NO;
        for (int i = 0; i < [self numberOfSections]; i++) {
            if ([self numberOfItemsInSection:i]) {
                _isDataAvailable = YES;
                break;
            }
        }
    } else {
        _isDataAvailable = [self numberOfItemsInSection:0];
    }
}

- (BOOL)canLoadMore
{
    switch (self.activeFeed) {
        case PRFeedTypeHot:
            return _canMoreHot;
        case PRFeedTypeNew:
            return _canMoreNew;
        default:
            return NO;
    }
}

- (void)likeArticle:(Article *)article completion:(void(^)(NSString *errorMessage))completion
{
    __weak typeof(self) wSelf = self;
    [self.dataProvider likeArticle:article success:^(NSError *error) {
        if (completion) {
            if (error) {
                completion([wSelf.errorDescriptor descriptionForError:error]);
            } else {
                completion(nil);
            }
        }
    }];
}

- (void)dislikeArticle:(Article *)article completion:(void(^)(NSString *errorMessage))completion
{
    __weak typeof(self) wSelf = self;
    [self.dataProvider dislikeArticle:article success:^(NSError *error) {
        if (completion) {
            if (error) {
                completion([wSelf.errorDescriptor descriptionForError:error]);
            } else {
                completion(nil);
            }
        }
    }];
}

- (void)addArticleToFavorite:(Article *)article
{
     [self.dataProvider addArticleToFavorite:article success:nil];
}

@end
