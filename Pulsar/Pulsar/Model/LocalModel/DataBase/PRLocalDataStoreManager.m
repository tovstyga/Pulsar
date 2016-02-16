//
//  PRLocalDataStoreManager.m
//  Pulsar
//
//  Created by fantom on 09.02.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRLocalDataStoreManager.h"
#import "User+CoreDataProperties.h"

#import "PRRemoteCategory.h"

#import "PRDataProvider.h"
#import "PRLocalDataStore.h"
#import "PRNetworkDataProvider.h"

#define HOUR 60*60
#define DAY HOUR*24
#define WEEK DAY*7
#define MONTH DAY*30
#define YEAR DAY * 365

#define CACHED_PERIOD DAY * 3

@interface PRLocalDataStoreManager()

@property (strong, nonatomic) NSDate *lastCleaningDate;

@end

@implementation PRLocalDataStoreManager

static NSString * const kCoreUserTable = @"User";
static NSString * const kCoreGeoPointTable = @"GeoPoint";
static NSString * const kCoreInterestCategoryTable = @"InterestCategory";
static NSString * const kCoreMediaTable = @"Media";
static NSString * const kCoreArticleTable = @"Article";

static NSString * const kArticleClassName = @"Article";

@synthesize lastCleaningDate = _lastCleaningDate;

- (void)preloading
{
    dispatch_group_t loadingGroup = dispatch_group_create();
    //update categories
    dispatch_group_enter(loadingGroup);
    [self clearOldArticles];
    [[PRDataProvider sharedInstance] allCategories:^(NSArray *categories, NSError *error) {
        [[PRDataProvider sharedInstance] categoriesForCurrentUser:^(NSArray *categories, NSError *error) {
            dispatch_group_leave(loadingGroup);
        }];
    }];
    
    //update geopoints
    dispatch_group_enter(loadingGroup);
    [[PRDataProvider sharedInstance] allGeopoints:^(NSArray *geopoints, NSError *error) {
        dispatch_group_leave(loadingGroup);
    }];
    
    dispatch_group_wait(loadingGroup, DISPATCH_TIME_FOREVER);
}

- (void)createIfNeedsUserWithId:(NSString *)identifier email:(NSString *)email name:(NSString *)name
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreUserTable];
    [request setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier == %@", identifier]];
    __block NSArray *result = nil;

    NSManagedObjectContext *privateContext = [[PRLocalDataStore sharedInstance] backgroundContext];
    [privateContext performBlockAndWait:^{
        result = [privateContext executeFetchRequest:request error:nil];
    }];
    
    if ([result count]) {
        [self preloading];
        return;
    }

    [privateContext performBlockAndWait:^{
        User *user = [NSEntityDescription insertNewObjectForEntityForName:kCoreUserTable inManagedObjectContext:[[PRLocalDataStore sharedInstance] backgroundContext]];
        user.remoteIdentifier = identifier;
        user.email = email;
        user.userName = name;
    }];
    
    [[PRLocalDataStore sharedInstance] saveBackgroundContext];
    
    [self preloading];
}

- (User *)loadUser
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreUserTable];
    [request setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier == %@", [PRNetworkDataProvider sharedInstance].currentUser]];
    NSError *error = nil;
    NSArray *result = [[[PRLocalDataStore sharedInstance] mainContext] executeFetchRequest:request error:&error];
    if (!error) {
        return [result firstObject];
    }
    return nil;
}

- (void)updateCategories:(NSArray<PRRemoteCategory *> *)categories
{
    NSManagedObjectContext *workContext = [[PRLocalDataStore sharedInstance] backgroundContext];
    
    NSMutableArray *categoriesForAdd = [[NSMutableArray alloc] initWithArray:categories];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreInterestCategoryTable];
    
    [workContext performBlockAndWait:^{
        NSArray *fetchResult = [[[PRLocalDataStore sharedInstance] backgroundContext] executeFetchRequest:request error:nil];
        NSMutableArray *categoriesForRemove = [[NSMutableArray alloc] initWithArray:fetchResult];
        for (InterestCategory *iCategory in fetchResult) {
            for (PRRemoteCategory *category in categories) {
                if ([iCategory.remoteIdentifier isEqualToString:category.objectId]) {
                    [categoriesForRemove removeObject:iCategory];
                    [categoriesForAdd removeObject:category];
                }
            }
        }
        
        for (PRRemoteCategory *category in categoriesForAdd) {
            InterestCategory *newCategory = [NSEntityDescription insertNewObjectForEntityForName:kCoreInterestCategoryTable inManagedObjectContext:workContext];
            newCategory.remoteIdentifier = category.objectId;
            newCategory.name = category.name;
        }
        
        for (InterestCategory *category in categoriesForRemove) {
            [workContext deleteObject:category];
        }
    }];
    
    [[PRLocalDataStore sharedInstance] saveBackgroundContext];
}

- (NSArray<InterestCategory *> *)allLocalCategoriesForMain
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreInterestCategoryTable];
    __block NSArray *result = nil;
    [[[PRLocalDataStore sharedInstance] mainContext] performBlockAndWait:^{
        result = [[[PRLocalDataStore sharedInstance] mainContext] executeFetchRequest:request error:nil];
    }];
    return result;
}

- (void)updateUserCategories:(NSArray<PRRemoteCategory *> *)categories
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreUserTable];
    [request setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier == %@", [PRNetworkDataProvider sharedInstance].currentUser]];
    
    NSManagedObjectContext *privateContext = [[PRLocalDataStore sharedInstance] backgroundContext];
    [privateContext performBlockAndWait:^{
        User *user = [[privateContext executeFetchRequest:request error:nil] firstObject];
        
        NSMutableArray *categoryForRemove = nil;
        if ([user.interests count]) {
            categoryForRemove = [[NSMutableArray alloc] initWithArray:[user.interests allObjects]];
        }
        
        NSMutableArray *categoriesForAdd = [[NSMutableArray alloc] initWithArray:categories];
        for (InterestCategory *iCategory in user.interests) {
            for (PRRemoteCategory *category in categories) {
                if ([iCategory.remoteIdentifier isEqualToString:category.objectId]) {
                    [categoriesForAdd removeObject:category];
                    [categoryForRemove removeObject:iCategory];
                }
            }
        }
        
        if ([categoryForRemove count]) {
            NSSet *remove = [[NSSet alloc] initWithArray:categoryForRemove];
            [user removeInterests:remove];
        }
        
        if ([categoriesForAdd count]) {
            NSMutableArray *ids = [[NSMutableArray alloc] initWithCapacity:[categoriesForAdd count]];
            for (PRRemoteCategory *category in categoriesForAdd) {
                [ids addObject:category.objectId];
            }
            NSFetchRequest *localCategoriesRequest = [NSFetchRequest fetchRequestWithEntityName:kCoreInterestCategoryTable];
            [localCategoriesRequest setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier IN %@", ids]];
            NSArray *add = [privateContext executeFetchRequest:localCategoriesRequest error:nil];
            NSSet *forAdd = [[NSSet alloc] initWithArray:add];
            [user addInterests:forAdd];
        }
    }];
    
    [[PRLocalDataStore sharedInstance] saveBackgroundContext];
}

- (void)addUserCategories:(NSArray<InterestCategory *> *)addCategories remove:(NSArray<InterestCategory *> *)removeCategories
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreUserTable];
    [request setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier == %@", [PRNetworkDataProvider sharedInstance].currentUser]];

    NSManagedObjectContext *mainContext = [[PRLocalDataStore sharedInstance] mainContext];
    [mainContext performBlock:^{
        User *user = [[mainContext executeFetchRequest:request error:nil] firstObject];
        
        if (removeCategories) {
            NSSet *remove = [[NSSet alloc] initWithArray:removeCategories];
            [user removeInterests:remove];
        }
        
        if (addCategories) {
            NSSet *add = [[NSSet alloc] initWithArray:addCategories];
            [user addInterests:add];
        }
        
        [[PRLocalDataStore sharedInstance] saveMainContextAndWait:NO];
    }];
}

- (void)updateUserGeoPoints:(NSArray<PRRemoteGeoPoint *> *)newPoints
{
    NSManagedObjectContext *workContext = [[PRLocalDataStore sharedInstance] backgroundContext];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreUserTable];
    [request setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier == %@", [PRNetworkDataProvider sharedInstance].currentUser]];
    
    [workContext performBlockAndWait:^{
        User *user = [[workContext executeFetchRequest:request error:nil] firstObject];
        
        NSMutableArray *pointsForRemove = nil;
        if ([user.locations count]) {
            pointsForRemove = [[NSMutableArray alloc] initWithArray:[user.locations allObjects]];
        }
        
        NSMutableArray *pointsForAdd = [[NSMutableArray alloc] initWithArray:newPoints];
        for (GeoPoint *geoPoint in user.locations) {
            for (PRRemoteGeoPoint *rPoint in newPoints) {
                if ([geoPoint.title isEqualToString:rPoint.title]) {
                    [pointsForAdd removeObject:rPoint];
                    [pointsForRemove removeObject:geoPoint];
                }
            }
        }
        
        if ([pointsForRemove count]) {
            NSSet *remove = [[NSSet alloc] initWithArray:pointsForRemove];
            [user removeLocations:remove];
        }
        
        if ([pointsForAdd count]) {
            NSMutableSet *newGeoPoints = [NSMutableSet new];
            for (PRRemoteGeoPoint *geoPoint in pointsForAdd) {
                GeoPoint *point = [NSEntityDescription insertNewObjectForEntityForName:kCoreGeoPointTable inManagedObjectContext:workContext];
                point.title = geoPoint.title;
                point.longitude = @(geoPoint.longitude);
                point.latitude = @(geoPoint.latitude);
                [newGeoPoints addObject:point];
            }
            [user addLocations:newGeoPoints];
        }
    }];
    
    [[PRLocalDataStore sharedInstance] saveBackgroundContext];
}

- (void)updateArticles:(NSArray<PRRemoteArticle *> *)remoteArticle
{
    NSMutableArray *articlesForCreate = [[NSMutableArray alloc] initWithArray:remoteArticle];
    NSMutableSet *ids = [NSMutableSet new];
    for (PRRemoteArticle *article in remoteArticle) {
        [ids addObject:article.objectId];
    }
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreArticleTable];
    [request setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier IN %@", ids]];
    NSManagedObjectContext *privateContext = [[PRLocalDataStore sharedInstance] backgroundContext];
    [privateContext performBlockAndWait:^{
        NSArray *existsArticles = [privateContext executeFetchRequest:request error:nil];
        
        for (Article *article in existsArticles) {
            for (PRRemoteArticle *rArticle in remoteArticle) {
                if ([article.remoteIdentifier isEqualToString:rArticle.objectId]) {
                    [articlesForCreate removeObject:rArticle];
                    [self updateArticle:article newData:rArticle];
                }
            }
        }
        
        for (PRRemoteArticle *article in articlesForCreate) {
            Article *newArticle = [NSEntityDescription insertNewObjectForEntityForName:kCoreArticleTable inManagedObjectContext:privateContext];
            [self updateArticle:newArticle newData:article];
        }
    }];
    
    [[PRLocalDataStore sharedInstance] saveBackgroundContext];
}

- (void)updateArticle:(Article *)localArticle newData:(PRRemoteArticle *)remoteArticle
{
    localArticle.annotation = remoteArticle.annotation;
    localArticle.author = remoteArticle.author;
    
    localArticle.canLike = @(YES);
    for (NSString *likers in remoteArticle.likes) {
        if ([likers isEqualToString:[PRDataProvider sharedInstance].currentUser.remoteIdentifier]) {
            localArticle.canLike = @(NO);
            break;
        }
    }
    
    localArticle.canDislike = @(YES);
    for (NSString *dislikers in remoteArticle.disLikes) {
        if ([dislikers isEqualToString:[PRDataProvider sharedInstance].currentUser.remoteIdentifier]) {
            localArticle.canDislike = @(NO);
            break;
        }
    }
    
    localArticle.updatedDate = [NSDate date];
    localArticle.createdDate = remoteArticle.createdAt;
    localArticle.rating = @(remoteArticle.rating);
    localArticle.remoteIdentifier = remoteArticle.objectId;
    localArticle.text = remoteArticle.text;
    localArticle.title = remoteArticle.title;
    
    if (![localArticle.category.remoteIdentifier isEqualToString:remoteArticle.category.objectId]) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreInterestCategoryTable];
        [request setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier == %@", remoteArticle.category.objectId]];
        InterestCategory *category = [[[[PRLocalDataStore sharedInstance] backgroundContext] executeFetchRequest:request error:nil] firstObject];
        localArticle.category = category;
    }
    
    if (remoteArticle.location.title && ![localArticle.location.title isEqualToString:remoteArticle.location.title]) {
        GeoPoint *geoPoint = [NSEntityDescription insertNewObjectForEntityForName:kCoreGeoPointTable inManagedObjectContext:[[PRLocalDataStore sharedInstance] backgroundContext]];
        geoPoint.title = remoteArticle.location.title;
        geoPoint.longitude = @(remoteArticle.location.longitude);
        geoPoint.latitude = @(remoteArticle.location.latitude);
        localArticle.location = geoPoint;
    }
    
    if (![localArticle.image.remoteIdentifier isEqualToString:remoteArticle.image.objectId]) {
        Media *media = [NSEntityDescription insertNewObjectForEntityForName:kCoreMediaTable inManagedObjectContext:[[PRLocalDataStore sharedInstance] backgroundContext]];
        media.remoteIdentifier = remoteArticle.image.objectId;
        media.contentType = remoteArticle.image.contentType;
        media.thumbnailURL = [remoteArticle.image.thumbnailFile.url absoluteString];
        media.mediaURL = [remoteArticle.image.mediaFile.url absoluteString];
        localArticle.image = media;
    }
}

- (void)updateMediaForArticleWithId:(NSString *)remoteIdentifier newMedia:(NSArray<PRRemoteMedia *> *)remoteMedia
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreArticleTable];
    [request setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier == %@", remoteIdentifier]];
    
    NSManagedObjectContext *privateContext = [[PRLocalDataStore sharedInstance] backgroundContext];
    
    [privateContext performBlockAndWait:^{
        Article *article = [[privateContext executeFetchRequest:request error:nil] firstObject];
        
        NSMutableArray *mediaForRemove = [[NSMutableArray alloc] initWithArray:[article.media allObjects]];
        NSMutableArray *mediaForAdd = [[NSMutableArray alloc] initWithArray:remoteMedia];
        
        for (Media *lMedia in article.media) {
            for (PRRemoteMedia *rMedia in remoteMedia) {
                if ([lMedia.remoteIdentifier isEqualToString:rMedia.objectId]) {
                    [mediaForRemove removeObject:lMedia];
                    [mediaForAdd removeObject:rMedia];
                }
            }
        }
        
        if ([mediaForRemove count]) {
            [article removeMedia:[NSSet setWithArray:mediaForRemove]];
        }
        
        for (PRRemoteMedia *media in mediaForAdd) {
            Media *newMedia = [NSEntityDescription insertNewObjectForEntityForName:kCoreMediaTable inManagedObjectContext:[[PRLocalDataStore sharedInstance] backgroundContext]];
            newMedia.thumbnailURL = [media.thumbnailFile.url absoluteString];
            newMedia.mediaURL = [media.mediaFile.url absoluteString];
            newMedia.contentType = media.contentType;
            newMedia.remoteIdentifier = media.objectId;
            [article addMediaObject:newMedia];
        }
    }];
    
    [[PRLocalDataStore sharedInstance] saveBackgroundContext];
}

- (NSArray<Article *> *)localArticlesWithIds:(NSSet<NSString *> *)ids
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreArticleTable];
    [request setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier IN %@", ids]];
    return [[[PRLocalDataStore sharedInstance] mainContext] executeFetchRequest:request error:nil];
}

- (NSArray<Media *> *)localMediaForArticleWithId:(NSString *)articleId
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kArticleClassName];
    [request setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier == %@", articleId]];
    Article *article = [[[[PRLocalDataStore sharedInstance] mainContext] executeFetchRequest:request error:nil] firstObject];
    return [article.media allObjects];
}

- (Media *)madiaForBGWithId:(NSString *)identifier
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreMediaTable];
    [request setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier == %@", identifier]];
    return [[[[PRLocalDataStore sharedInstance] backgroundContext] executeFetchRequest:request error:nil] firstObject];
}

- (void)updateUserArticles:(NSArray<Article *> *)articles
{
    NSSet *set = [NSSet setWithArray:articles];
    [[PRDataProvider sharedInstance].currentUser removeArticles:[PRDataProvider sharedInstance].currentUser.articles];
    [[PRDataProvider sharedInstance].currentUser setArticles:set];
    [[PRLocalDataStore sharedInstance] saveMainContextAndWait:NO];
}

- (void)updateUserFavorites:(NSArray<Article *> *)articles
{
    NSSet *set = [NSSet setWithArray:articles];
    [[PRDataProvider sharedInstance].currentUser removeFavorite:[PRDataProvider sharedInstance].currentUser.favorite];
    [[PRDataProvider sharedInstance].currentUser setFavorite:set];
    [[PRLocalDataStore sharedInstance] saveMainContextAndWait:NO];
}

- (NSArray<Article *> *)loadLocalHotArticles
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kArticleClassName];
    [request setPredicate:[self categoriesFiltrationPredicate]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"rating" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    return [[[PRLocalDataStore sharedInstance] mainContext] executeFetchRequest:request error:nil];
}

- (NSArray<Article *> *)loadLocalNewArticles
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kArticleClassName];
    [request setPredicate:[self categoriesFiltrationPredicate]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdDate" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    return [[[PRLocalDataStore sharedInstance] mainContext] executeFetchRequest:request error:nil];
}

- (PRArticleCollection *)loadLocalTopArticles
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kArticleClassName];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"rating" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
    
    PRArticleCollection *result = [[PRArticleCollection alloc] init];
    
    NSInteger gmtCorrection = [[NSTimeZone localTimeZone] secondsFromGMT];
    NSDate *now = [NSDate date];
    
    NSMutableArray *ids = [NSMutableArray new];
    for (InterestCategory *catecgory in [[PRDataProvider sharedInstance].currentUser.interests allObjects]) {
        [ids addObject:catecgory.remoteIdentifier];
    }
    
    NSArray *dates = @[[now dateByAddingTimeInterval:-HOUR -gmtCorrection], [now dateByAddingTimeInterval:-DAY -gmtCorrection], [now dateByAddingTimeInterval:-WEEK -gmtCorrection], [now dateByAddingTimeInterval:-MONTH -gmtCorrection], [now dateByAddingTimeInterval:-YEAR -gmtCorrection]];
    for (int i = 0; i < dates.count; i++) {
        [request setPredicate:[NSPredicate predicateWithFormat:@"createdDate >= %@ AND category.remoteIdentifier IN %@", dates[i], ids]];
        NSArray *array = [[[PRLocalDataStore sharedInstance] mainContext] executeFetchRequest:request error:nil];
        [result setFetchResult:array forKey:i];
    }
    
    return result;
}

- (NSPredicate *)categoriesFiltrationPredicate
{
    NSMutableArray *ids = [NSMutableArray new];
    for (InterestCategory *catecgory in [[PRDataProvider sharedInstance].currentUser.interests allObjects]) {
        [ids addObject:catecgory.remoteIdentifier];
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category.remoteIdentifier IN %@", ids];
    return predicate;
}

- (void)clearOldArticles
{
    if (self.lastCleaningDate && [PRDataProvider sharedInstance].currentUser) {
        NSMutableSet *protectedArticles = [[NSMutableSet alloc] init];
        [protectedArticles addObjectsFromArray:[[PRDataProvider sharedInstance].currentUser.favorite allObjects]];
        [protectedArticles addObjectsFromArray:[[PRDataProvider sharedInstance].currentUser.articles allObjects]];
        
        NSFetchRequest *oldObjectsRequest = [NSFetchRequest fetchRequestWithEntityName:kCoreArticleTable];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@) AND NOT (updatedDate >= %@)", [protectedArticles allObjects], [self.lastCleaningDate dateByAddingTimeInterval:-CACHED_PERIOD]];
        [oldObjectsRequest setPredicate:predicate];
        NSManagedObjectContext *privateContext = [[PRLocalDataStore sharedInstance] backgroundContext];
        [privateContext performBlockAndWait:^{
            NSArray *oldObjects = [privateContext executeFetchRequest:oldObjectsRequest error:nil];
            for (Article *article in oldObjects) {
                [privateContext deleteObject:article];
            }
        }];
        
        [[PRLocalDataStore sharedInstance] saveBackgroundContext];
    }
    self.lastCleaningDate = [NSDate date];
}

- (void)setLastCleaningDate:(NSDate *)lastCleaningDate
{
    if (![_lastCleaningDate isEqualToDate:lastCleaningDate]) {
        [[NSUserDefaults standardUserDefaults] setObject:lastCleaningDate forKey:@"last_cleaning_date"];
        _lastCleaningDate = lastCleaningDate;
    }
}

- (NSDate *)lastCleaningDate
{
    if (!_lastCleaningDate) {
        _lastCleaningDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"last_cleaning_date"];
    }
    return _lastCleaningDate;
}

@end
