//
//  User+CoreDataProperties.h
//  Pulsar
//
//  Created by fantom on 01.02.16.
//  Copyright © 2016 TAB. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface User (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *email;
@property (nullable, nonatomic, retain) NSString *remoteIdentifier;
@property (nullable, nonatomic, retain) NSString *userName;
@property (nullable, nonatomic, retain) NSSet<Article *> *articles;
@property (nullable, nonatomic, retain) NSSet<Article *> *favorite;
@property (nullable, nonatomic, retain) NSSet<InterestCategory *> *interests;
@property (nullable, nonatomic, retain) NSSet<GeoPoint *> *locations;

@end

@interface User (CoreDataGeneratedAccessors)

- (void)addArticlesObject:(Article *)value;
- (void)removeArticlesObject:(Article *)value;
- (void)addArticles:(NSSet<Article *> *)values;
- (void)removeArticles:(NSSet<Article *> *)values;

- (void)addFavoriteObject:(Article *)value;
- (void)removeFavoriteObject:(Article *)value;
- (void)addFavorite:(NSSet<Article *> *)values;
- (void)removeFavorite:(NSSet<Article *> *)values;

- (void)addInterestsObject:(InterestCategory *)value;
- (void)removeInterestsObject:(InterestCategory *)value;
- (void)addInterests:(NSSet<InterestCategory *> *)values;
- (void)removeInterests:(NSSet<InterestCategory *> *)values;

- (void)addLocationsObject:(GeoPoint *)value;
- (void)removeLocationsObject:(GeoPoint *)value;
- (void)addLocations:(NSSet<GeoPoint *> *)values;
- (void)removeLocations:(NSSet<GeoPoint *> *)values;

@end

NS_ASSUME_NONNULL_END
