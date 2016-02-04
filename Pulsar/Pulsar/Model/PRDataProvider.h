//
//  PRDataProvider.h
//  Pulsar
//
//  Created by fantom on 04.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRLocalNewArticle.h"
#import "PRArticleCollection.h"

//core data

#import "User+CoreDataProperties.h"
#import "InterestCategory+CoreDataProperties.h"
#import "GeoPoint+CoreDataProperties.h"
#import "Article+CoreDataProperties.h"
#import "Media+CoreDataProperties.h"

@interface PRDataProvider : NSObject

@property (strong, nonatomic, readonly) User *currentUser;
@property (strong, nonatomic, readonly) NSArray<InterestCategory *> *allCategories;

+ (instancetype)sharedInstance;

- (void)registrateUser:(NSString *)userName
              password:(NSString *)password
                 email:(NSString *)email
            completion:(void(^)(NSError *error))completion;

- (void)loginUser:(NSString *)userName password:(NSString *)password completion:(void(^)(NSError *error))completion;

- (void)sendNewPasswordOnEmail:(NSString *)email completion:(void(^)(NSError *error))completion;

- (void)logoutWithCompletion:(void(^)(NSError *error))completion;

- (void)resumeSession:(void(^)(BOOL success))completion;

- (void)loadThumbnailForMedia:(Media *)media completion:(void(^)(UIImage *image, NSError *error))completion;

- (void)loadContentForMedia:(Media *)media completion:(void(^)(UIImage *image, NSError *error))completion;

//categories

- (void)allCategories:(void(^)(NSArray *categories, NSError *error))completion;

- (void)categoriesForCurrentUser:(void(^)(NSArray *categories, NSError *error))completion;

- (void)addCategoryForCurrentUser:(InterestCategory *)category completion:(void(^)(NSError *error))completion;

- (void)addCategoriesForCurrentUser:(NSArray *)categories completion:(void(^)(NSError *error))completion;

- (void)removeCategoryForCurrentUser:(InterestCategory *)category completion:(void(^)(NSError *error))completion;

- (void)removeCategoriesForCurrentUser:(NSArray *)categories completion:(void(^)(NSError *error))completion;

- (void)userCategoryAdd:(NSArray *)addCategories remove:(NSArray *)removeCategories completion:(void(^)(NSError *error))completion;

//geo points

- (void)addGeoPoint:(PRLocalGeoPoint *)geoPoint completion:(void(^)(NSError *error))completion;

- (void)addGeoPoints:(NSArray *)geoPoints completion:(void(^)(NSError *error))completion;

- (void)removeGeoPoint:(PRLocalGeoPoint *)geoPoint completion:(void(^)(NSError *error))completion;

- (void)removeGeoPoints:(NSArray *)geoPoints completion:(void(^)(NSError *error))completion;

- (void)allGeopoints:(void(^)(NSArray *geopoints, NSError *error))completion;

//articles

- (void)publishNewArticle:(PRLocalNewArticle *)localArticle completion:(void(^)(NSError *error))completion;

- (void)loadMediaForArticle:(Article *)localArticle completion:(void(^)(NSArray<Media *> *mediaArray, NSError *error))completion;

- (void)allMyArticles:(void(^)(NSArray *articles, NSError *error))completion;

- (void)favoriteArticles:(void(^)(NSArray *articles, NSError *error))completion;

- (void)addArticleToFavorite:(Article *)article success:(void(^)(NSError *error))completion;

- (void)remoteArticleFromFavorite:(Article *)article success:(void(^)(NSError *error))completion;

- (void)likeArticle:(Article *)article success:(void(^)(NSError *error))completion;

- (void)dislikeArticle:(Article *)article success:(void(^)(NSError *error))completion;

//articles part request

- (void)refreshHotArticlesWithCompletion:(void(^)(NSArray *articles, NSError *error))completion;

- (void)loadNextHotArticlesWithCompletion:(void(^)(NSArray *articles, NSError *error))completion;

- (void)refreshNewArticlesWithCompletion:(void(^)(NSArray *articles, NSError *error))completion;

- (void)loadNextNewArticlesWithCompletion:(void(^)(NSArray *articles, NSError *error))completion;

- (void)refreshTopArticlesWithCompletion:(void(^)(PRArticleCollection *articles, NSError *error))completion;

@end
