//
//  PRLocalDataStoreManager.h
//  Pulsar
//
//  Created by fantom on 09.02.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "Media.h"
#import "PRArticleCollection.h"
#import "PRRemoteGeoPoint.h"
#import "PRRemoteCategory.h"
#import "PRRemoteArticle.h"

@interface PRLocalDataStoreManager : NSObject

- (User *)loadUser;

- (void)createIfNeedsUserWithId:(NSString *)identifier email:(NSString *)email name:(NSString *)name;

- (void)addUserCategories:(NSArray<InterestCategory *> *)addCategories remove:(NSArray<InterestCategory *> *)removeCategories;

- (Media *)madiaForBGWithId:(NSString *)identifier;

- (void)updateUserArticles:(NSArray<Article *> *)articles;

- (void)updateUserFavorites:(NSArray<Article *> *)articles;

- (NSArray<Article *> *)loadLocalHotArticles;

- (NSArray<Article *> *)loadLocalNewArticles;

- (PRArticleCollection *)loadLocalTopArticles;

- (void)updateUserGeoPoints:(NSArray<PRRemoteGeoPoint *> *)newPoints;

- (void)updateCategories:(NSArray<PRRemoteCategory *> *)categories;

- (NSArray<InterestCategory *> *)allLocalCategoriesForMain;

- (void)updateUserCategories:(NSArray<PRRemoteCategory *> *)categories;

- (void)updateArticles:(NSArray<PRRemoteArticle *> *)remoteArticle;

- (NSArray<Article *> *)localArticlesWithIds:(NSSet<NSString *> *)ids;

- (void)updateMediaForArticleWithId:(NSString *)remoteIdentifier newMedia:(NSArray<PRRemoteMedia *> *)remoteMedia;

- (NSArray<Media *> *)localMediaForArticleWithId:(NSString *)articleId;

@end
