//
//  PRDataProvider.m
//  Pulsar
//
//  Created by fantom on 04.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRDataProvider.h"
#import "PRNetworkDataProvider.h"
#import "PRRemoteRegistrationRequest.h"
#import "PRRemoteResetPasswordRequest.h"
#import "PRRemoteLoginResponse.h"
#import "PRRemoteRegistrationResponse.h"
#import "PRTokenValidationResponse.h"

#import "PRRemoteResults.h"
#import "PRRemoteCategory.h"
#import "PRLocalGeoPoint.h"
#import "PRRemoteGeoPoint.h"
#import "PRRemotePublishedArticle.h"
#import "PRRemotePointer.h"
#import "PRUploadMediaOperation.h"
#import "PRConstants.h"
#import "PRLocationManager.h"

#import "PRLocalDataStoreManager.h"
#import "PRLocalDataStore.h"

#define HOUR 60*60
#define DAY HOUR*24
#define WEEK DAY*7
#define MONTH DAY*30
#define YEAR DAY * 365

@interface PRDataProvider()

@property (strong, nonatomic) NSString *networkSessionKey;
@property (strong, atomic) NSOperationQueue *uploadQueue;
@property (strong, atomic) NSOperationQueue *downloadQueue;

@property (strong, atomic) PRLocalDataStoreManager *storeManager;

@end

@implementation PRDataProvider{
    NSDate *_newArticleRequestTime;
    NSInteger _minRatingArticle;
    
    int _newArticlesCount;
    int _hotArticleCount;
}

@synthesize networkSessionKey = _networkSessionKey;
@synthesize currentUser = _currentUser;
@synthesize allCategories = _allCategories;

static PRDataProvider *sharedInstance;

static int const kFetchLimith = 10;

static NSString * const kObjectIdentifierKey = @"objectId";
static NSString * const kUserClassName = @"_User";
static NSString * const kArticleClassName = @"Article";
static NSString * const kCategoryClassName = @"Tag";
static NSString * const kMediaClassName = @"Media";

- (instancetype)init
{
    if (sharedInstance) {
        return sharedInstance;
    } else {
        self = [super init];
        if (self) {
            [PRNetworkDataProvider sharedInstance];
            
            self.uploadQueue = [[NSOperationQueue alloc] init];
            self.uploadQueue.maxConcurrentOperationCount = 1;
            self.uploadQueue.name = @"upload data queue";
            
            self.downloadQueue = [[NSOperationQueue alloc] init];
            self.downloadQueue.maxConcurrentOperationCount = 1;
            self.downloadQueue.name = @"download data queue";
            
            self.storeManager = [[PRLocalDataStoreManager alloc] init];
            
            _minRatingArticle = NSIntegerMin;
            _newArticleRequestTime = [NSDate date];
            
        }
        return self;
    }
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[PRDataProvider alloc] init];
    });
    return sharedInstance;
}

#pragma mark - accessors

- (User *)currentUser
{
    if (_currentUser) {
        return _currentUser;
    } else {
        _currentUser = [self.storeManager loadUser];
        return _currentUser;
    }
}

#pragma mark - session and autorization

- (void)registrateUser:(NSString *)userName
              password:(NSString *)password
                 email:(NSString *)email
            completion:(void (^)(NSError *))completion
{
    PRRemoteRegistrationRequest *request = [[PRRemoteRegistrationRequest alloc] initWithUserName:userName password:password email:email];
    [[PRNetworkDataProvider sharedInstance] requestRegistration:request success:^(NSData *data, NSURLResponse *response) {
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        PRRemoteRegistrationResponse *sessionInfo = [[PRRemoteRegistrationResponse alloc] initWithJSON:json];
        self.networkSessionKey = sessionInfo.sessionToken;
        [self resumeSession:^(BOOL success) {
            if (completion) {
                completion(nil);
            }
        }]; //for loading user data
    } failure:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)loginUser:(NSString *)userName password:(NSString *)password completion:(void (^)(NSError *))completion
{
    [[PRNetworkDataProvider sharedInstance] requestLoginUser:userName password:password success:^(NSData *data, NSURLResponse *response) {
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        PRRemoteLoginResponse *sessionInfo = [[PRRemoteLoginResponse alloc] initWithJSON:json];
        self.networkSessionKey = sessionInfo.sessionToken;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.storeManager createIfNeedsUserWithId:sessionInfo.objectId email:sessionInfo.email name:sessionInfo.userName];
            if (completion) {
                completion(nil);
            }
        });
    } failure:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)sendNewPasswordOnEmail:(NSString *)email completion:(void (^)(NSError *))completion
{
    PRRemoteResetPasswordRequest *request = [[PRRemoteResetPasswordRequest alloc] initWithEmail:email];
    [[PRNetworkDataProvider sharedInstance] requestResetPassword:request success:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)logoutWithCompletion:(void (^)(NSError *))completion
{
    [[PRNetworkDataProvider sharedInstance] requestLogoutWithSuccess:^(NSData *data, NSURLResponse *response) {
        self.networkSessionKey = nil;
        _currentUser = nil;
        _allCategories = nil;
        dispatch_sync(dispatch_get_main_queue(), ^{
           [[[PRLocalDataStore sharedInstance] mainContext] reset]; 
        });
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)resumeSession:(void (^)(BOOL))completion
{
    _currentUser = nil;
    _allCategories = nil;
    [[PRNetworkDataProvider sharedInstance] validateSessionToken:self.networkSessionKey success:^(NSData *data, NSURLResponse *response) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            PRTokenValidationResponse *validationResponse = [[PRTokenValidationResponse alloc] initWithJSON:json];
            _currentUser = nil;
            _allCategories = nil;
            [self.storeManager createIfNeedsUserWithId:validationResponse.objectId email:validationResponse.email name:validationResponse.userName];
            if (completion) {
                completion(YES);
            }
        });
    } failure:^(NSError *error) {
        if (error.code != 999) {
           self.networkSessionKey = nil;
        }
        if (completion) {
            completion(NO);
        }
    }];
}

#pragma mark - Categories

- (void)allCategories:(void(^)(NSArray *categories, NSError *error))completion
{
    [[PRNetworkDataProvider sharedInstance] requestCategoriesWithSuccess:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion([self localCategoriesFromResponseData:data], nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion([self localCategoriesFromResponseData:nil], error);
        }
    }];
}

- (void)categoriesForCurrentUser:(void(^)(NSArray *categories, NSError *error))completion
{
    [[PRNetworkDataProvider sharedInstance] requestCategoriesForCurrentUserWithSuccess:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion([self localUserCategoriesFromResponseData:data], nil);
        }
    } failure:^(NSError *error) {
        completion([self localUserCategoriesFromResponseData:nil], error);
    }];
}

- (void)addCategoryForCurrentUser:(InterestCategory *)category completion:(void(^)(NSError *error))completion
{
    [self addCategoriesForCurrentUser:@[category] completion:completion];
}

- (void)addCategoriesForCurrentUser:(NSArray *)categories completion:(void(^)(NSError *error))completion
{
    [self.storeManager addUserCategories:categories remove:nil];
    [[PRNetworkDataProvider sharedInstance] requestAddCategoriesWithIdsForCurrentUser:[self categoriesIdsFrom:categories] success:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)removeCategoryForCurrentUser:(InterestCategory *)category completion:(void(^)(NSError *error))completion
{
    [self removeCategoriesForCurrentUser:@[category] completion:completion];
}

- (void)removeCategoriesForCurrentUser:(NSArray *)categories completion:(void(^)(NSError *error))completion
{
    [self.storeManager addUserCategories:nil remove:categories];
    [[PRNetworkDataProvider sharedInstance] requestRemoveCategoriesWithIdsForCurrentUser:[self categoriesIdsFrom:categories] success:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)userCategoryAdd:(NSArray *)addCategories remove:(NSArray *)removeCategories completion:(void(^)(NSError *error))completion
{
    [self.storeManager addUserCategories:addCategories remove:removeCategories];
    [[PRNetworkDataProvider sharedInstance] requestUpdateUserCategoriesForAdd:[self categoriesIdsFrom:addCategories] remove:[self categoriesIdsFrom:removeCategories] success:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

#pragma mark - GeoPoint

- (void)addGeoPoint:(PRLocalGeoPoint *)geoPoint completion:(void(^)(NSError *error))completion
{
    [self addGeoPoints:@[geoPoint] completion:completion];
}

- (void)addGeoPoints:(NSArray *)geoPoints completion:(void(^)(NSError *error))completion
{
    [[PRNetworkDataProvider sharedInstance] requestAddGeopoints:[self remoteGeoPointsFromLocal:geoPoints] success:^(NSData *data, NSURLResponse *response) {
        [self localGeoPointsFromResponseData:data];
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)removeGeoPoint:(PRLocalGeoPoint *)geoPoint completion:(void(^)(NSError *error))completion
{
    [self removeGeoPoints:@[geoPoint] completion:completion];
}

- (void)removeGeoPoints:(NSArray *)geoPoints completion:(void(^)(NSError *error))completion
{
    [[PRNetworkDataProvider sharedInstance] requestRemoveGeopoints:[self remoteGeoPointsFromLocal:geoPoints] success:^(NSData *data, NSURLResponse *response) {
        [self localGeoPointsFromResponseData:data];
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)allGeopoints:(void(^)(NSArray *geopoints, NSError *error))completion
{
    [[PRNetworkDataProvider sharedInstance] requesGeoPointsWithSuccess:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion([self localGeoPointsFromResponseData:data], nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion([self localGeoPointsFromResponseData:nil], error);
        }
    }];
}

#pragma mark - Articles

- (void)publishNewArticle:(PRLocalNewArticle *)localArticle completion:(void(^)(NSError *error))completion
{
    __block PRRemotePublishedArticle *remoteArticle = [[PRRemotePublishedArticle alloc] init];
    remoteArticle.title = localArticle.title;
    remoteArticle.annotation = localArticle.annotation;
    remoteArticle.text = localArticle.text;
    remoteArticle.author = [[PRRemotePointer alloc] initWithClass:kUserClassName remoteObjectId:[PRNetworkDataProvider sharedInstance].currentUser];
    remoteArticle.category = [[PRRemotePointer alloc] initWithClass:kCategoryClassName remoteObjectId:localArticle.category.remoteIdentifier];
    remoteArticle.location = [[PRRemoteGeoPoint alloc] initWithLocalGeoPoint:localArticle.location];
    void(^publishBlock)(PRRemotePointer *image) = ^(PRRemotePointer *image){
        if (image) {
            remoteArticle.image = image;
        }
        dispatch_group_t publishGroup = dispatch_group_create();
        dispatch_group_enter(publishGroup);
        [self.uploadQueue addOperationWithBlock:^{
            [[PRNetworkDataProvider sharedInstance] requestPublishArticle:remoteArticle success:^(NSData *data, NSURLResponse *response) {
                if (completion) {
                    completion(nil);
                }
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                PRRemotePointer *pointerToNewArticle = [[PRRemotePointer alloc] initWithClass:kArticleClassName remoteObjectId:[json objectForKey:kObjectIdentifierKey]];
                
                for (UIImage *image in localArticle.images) {
                    PRUploadMediaOperation *uploadOperation = [[PRUploadMediaOperation alloc] init];
                    uploadOperation.uploadImage = image;
                    uploadOperation.article = pointerToNewArticle;
                    [self.uploadQueue addOperation:uploadOperation];
                }
                localArticle.images = nil;
                dispatch_group_leave(publishGroup);
            } failure:^(NSError *error) {
                if (completion) {
                    completion(error);
                }
                dispatch_group_leave(publishGroup);
            }];
            dispatch_group_wait(publishGroup, DISPATCH_TIME_FOREVER);
        }];
    };
    
    if (localArticle.image) {
        PRUploadMediaOperation *uploadImageOperation = [[PRUploadMediaOperation alloc] init];
        uploadImageOperation.uploadImage = localArticle.image;
        uploadImageOperation.uploadCompletion = ^(NSString *identifier){
            if (identifier) {
                PRRemotePointer *imagePointer = [[PRRemotePointer alloc] initWithClass:kMediaClassName remoteObjectId:identifier];
                publishBlock(imagePointer);
            } else {
                publishBlock(nil);
            }
        };
        [self.uploadQueue addOperation:uploadImageOperation];
    } else {
        publishBlock(nil);
    }
}

- (void)loadThumbnailForMedia:(Media *)media completion:(void(^)(UIImage *image, NSError *error))completion
{
    [self loadDataFromUrl:[NSURL URLWithString:media.thumbnailURL] completion:^(NSData *data, NSError *error) {
        if (!error) {
            Media *bgMedia = [self.storeManager madiaForBGWithId:media.remoteIdentifier];
            bgMedia.thumbnail = data;
            [[PRLocalDataStore sharedInstance] saveBackgroundContext];
            if (completion) {
                completion([UIImage imageWithData:data], nil);
            }
        } else if (completion) {
            completion(nil, error);
        }
    }];
}
- (void)loadContentForMedia:(Media *)media completion:(void(^)(UIImage *image, NSError *error))completion
{
    [self loadDataFromUrl:[NSURL URLWithString:media.mediaURL] completion:^(NSData *data, NSError *error) {
        if (!error) {
            Media *bgMedia = [self.storeManager madiaForBGWithId:media.remoteIdentifier];
            bgMedia.image = data;
            [[PRLocalDataStore sharedInstance] saveBackgroundContext];
            if (completion) {
                completion([UIImage imageWithData:data], nil);
            }
        } else if (completion) {
            completion(nil, error);
        }
    }];
}

- (void)loadDataFromUrl:(NSURL *)url completion:(void (^)(NSData *data, NSError *error))completion
{
    [self.downloadQueue addOperationWithBlock:^{
        dispatch_group_t downloadGroup = dispatch_group_create();
        dispatch_group_enter(downloadGroup);
        [[PRNetworkDataProvider sharedInstance] loadDataFromURL:url success:^(NSData *data, NSURLResponse *response) {
            if (completion) {
                completion(data, nil);
            }
            dispatch_group_leave(downloadGroup);
        } failure:^(NSError *error) {
            if (completion) {
                completion(nil, error);
            }
            dispatch_group_leave(downloadGroup);
        }];
        dispatch_group_wait(downloadGroup, DISPATCH_TIME_FOREVER);
    }];
}

- (void)loadMediaForArticle:(Article *)localArticle completion:(void(^)(NSArray<Media *> *mediaArray, NSError *error))completion
{
    [[PRNetworkDataProvider sharedInstance] requestMediaForArticleWithId:localArticle.remoteIdentifier success:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion([self localMediaFromResponseData:data forArticleWithId:localArticle.remoteIdentifier], nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

- (void)allMyArticles:(void(^)(NSArray *articles, NSError *error))completion
{
    [[PRNetworkDataProvider sharedInstance] requestAllMyArticlesWithSuccess:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            NSArray *result = [[self localArticlesFromResponseData:data] sortedArrayUsingComparator:^NSComparisonResult(Article *obj1, Article *obj2) {
                return [obj2.createdDate compare:obj1.createdDate];
            }];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.storeManager updateUserArticles:result];
            });
            completion(result, nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            if (error.code == 999) { //rechability
                NSArray *result = [[self.currentUser.articles allObjects] sortedArrayUsingComparator:^NSComparisonResult(Article *obj1, Article *obj2) {
                    return [obj2.createdDate compare:obj1.createdDate];
                }];
                completion(result, error);
            } else {
                completion(nil, error);
            }
        }
    }];
}

- (void)favoriteArticles:(void(^)(NSArray *articles, NSError *error))completion
{
    [[PRNetworkDataProvider sharedInstance] requestFavoriteArticlesWithSuccess:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            NSArray *result = [[self localArticlesFromResponseData:data] sortedArrayUsingComparator:^NSComparisonResult(Article *obj1, Article *obj2) {
                return [obj2.createdDate compare:obj1.createdDate];
            }];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.storeManager updateUserFavorites:result];
            });
            completion(result, nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            if (error.code == 999) {
                NSArray *result = [[self.currentUser.favorite allObjects] sortedArrayUsingComparator:^NSComparisonResult(Article *obj1, Article *obj2) {
                    return [obj2.createdDate compare:obj1.createdDate];
                }];
                completion(result, error);
            } else {
                completion(nil, error);
            }
        }
    }];
}

- (void)addArticleToFavorite:(Article *)article success:(void(^)(NSError *error))completion
{
    [[PRNetworkDataProvider sharedInstance] requestAddArticleToFavorite:article.remoteIdentifier success:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)remoteArticleFromFavorite:(Article *)article success:(void(^)(NSError *error))completion
{
    [[PRNetworkDataProvider sharedInstance] requestRemoveArticleFromFavorite:article.remoteIdentifier success:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)likeArticle:(Article *)article success:(void(^)(NSError *error))completion
{
    article.canLike = @(NO);
    article.canDislike = @(YES);
    article.rating = @([article.rating integerValue] + 1);
    [[PRNetworkDataProvider sharedInstance] requestLikeArticle:article.remoteIdentifier success:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)dislikeArticle:(Article *)article success:(void(^)(NSError *error))completion
{
    article.canLike = @(YES);
    article.canDislike = @(NO);
    article.rating = @([article.rating integerValue] - 1);
    [[PRNetworkDataProvider sharedInstance] requestDislikeArticle:article.remoteIdentifier success:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)refreshHotArticlesWithCompletion:(void(^)(NSArray *articles, NSError *error))completion
{
    [self loadHotArticlesForced:YES completion:completion];
}

- (void)loadNextHotArticlesWithCompletion:(void(^)(NSArray *articles, NSError *error))completion
{
    [self loadHotArticlesForced:NO completion:completion];
}

- (void)loadHotArticlesForced:(BOOL)forced completion:(void(^)(NSArray *articles, NSError *error))completion
{
    if (forced) {
        _hotArticleCount = 0;
    }
    [[PRNetworkDataProvider sharedInstance] requestHotArticlesWithCategoriesIds:[self categoriesIdsFrom:[self.currentUser.interests allObjects]] minRating:NSIntegerMax from:_hotArticleCount step:kFetchLimith locations:[PRLocationManager sharedInstance].selectedCoordinate success:^(NSData *data, NSURLResponse *response) {
        NSArray *articles = [self localArticlesFromResponseData:data];
        _hotArticleCount +=[articles count];
        _minRatingArticle = [[(Article *)[articles lastObject] rating] integerValue];
        if (completion) {
            completion(articles ,nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            if (error.code == 999 && forced) {
                completion([self.storeManager loadLocalHotArticles], error);
            } else {
                completion(nil, error);
            }
        }
    }];
}

- (void)refreshNewArticlesWithCompletion:(void(^)(NSArray *articles, NSError *error))completion
{
    [self loadNewArticlesForced:YES completion:completion];
}

- (void)loadNextNewArticlesWithCompletion:(void(^)(NSArray *articles, NSError *error))completion
{
    [self loadNewArticlesForced:NO completion:completion];
}

- (void)loadNewArticlesForced:(BOOL)forced completion:(void(^)(NSArray *articles, NSError *error))completion
{
    if (forced) {
        _newArticleRequestTime = [NSDate date];
        _newArticlesCount = 0;
    }
    [[PRNetworkDataProvider sharedInstance] requestNewArticlesWithCategoriesIds:[self categoriesIdsFrom:[self.currentUser.interests allObjects]] lastDate:_newArticleRequestTime form:_newArticlesCount step:kFetchLimith locations:[PRLocationManager sharedInstance].selectedCoordinate success:^(NSData *data, NSURLResponse *response) {
        NSArray *articles = [[self localArticlesFromResponseData:data] sortedArrayUsingComparator:^NSComparisonResult(Article *obj1, Article *obj2) {
            return [obj2.createdDate compare:obj1.createdDate];
        }];
        _newArticlesCount += [articles count];
        if (completion) {
            completion(articles ,nil);
        }
    } failure:^(NSError *error) {
        if (error.code == 999 && forced) {
            completion([self.storeManager loadLocalNewArticles], error);
        } else {
            completion(nil, error);
        }
    }];
}

- (void)refreshTopArticlesWithCompletion:(void(^)(PRArticleCollection *articles, NSError *error))completion
{
    NSArray *categoriest = [self categoriesIdsFrom:[self.currentUser.interests allObjects]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInteger gmtCorrection = [[NSTimeZone localTimeZone] secondsFromGMT];
        NSDate *now = [NSDate date];
        CLLocationCoordinate2D geoPoint = [PRLocationManager sharedInstance].selectedCoordinate;
        __block PRArticleCollection *articleCollection = [[PRArticleCollection alloc] init];
        dispatch_group_t fetchGroup = dispatch_group_create();
        
        void(^errorBlock)(NSError *error) = ^(NSError *error) {
            if (completion) {
                if (error.code == 999) {
                    completion([self.storeManager loadLocalTopArticles], error);
                } else {
                    completion(nil, error);
                }
            }
            dispatch_group_leave(fetchGroup);
        };
        
        dispatch_group_enter(fetchGroup);
        [[PRNetworkDataProvider sharedInstance] requestTopArticlesWithCategoriesIds:categoriest beforeDate:[now dateByAddingTimeInterval:-HOUR -gmtCorrection] locations:geoPoint success:^(NSData *data, NSURLResponse *response) {
            [articleCollection setFetchResult:[self localArticlesFromResponseData:data] forKey:PRArticleFetchHour];
            
            [[PRNetworkDataProvider sharedInstance] requestTopArticlesWithCategoriesIds:categoriest beforeDate:[now dateByAddingTimeInterval:-DAY -gmtCorrection] locations:geoPoint success:^(NSData *data, NSURLResponse *response) {
                [articleCollection setFetchResult:[self localArticlesFromResponseData:data] forKey:PRArticleFetchDay];
                
                [[PRNetworkDataProvider sharedInstance] requestTopArticlesWithCategoriesIds:categoriest beforeDate:[now dateByAddingTimeInterval:-WEEK -gmtCorrection] locations:geoPoint success:^(NSData *data, NSURLResponse *response) {
                    [articleCollection setFetchResult:[self localArticlesFromResponseData:data] forKey:PRArticleFetchWeek];
                    
                    [[PRNetworkDataProvider sharedInstance] requestTopArticlesWithCategoriesIds:categoriest beforeDate:[now dateByAddingTimeInterval:-MONTH -gmtCorrection] locations:geoPoint success:^(NSData *data, NSURLResponse *response) {
                        [articleCollection setFetchResult:[self localArticlesFromResponseData:data] forKey:PRArticleFetchMonth];
                        
                        [[PRNetworkDataProvider sharedInstance] requestTopArticlesWithCategoriesIds:categoriest beforeDate:[now dateByAddingTimeInterval:-YEAR -gmtCorrection] locations:geoPoint success:^(NSData *data, NSURLResponse *response) {
                            
                            [articleCollection setFetchResult:[self localArticlesFromResponseData:data] forKey:PRArticleFetchYear];
                            if (completion) {
                                completion(articleCollection, nil);
                            }
                            dispatch_group_leave(fetchGroup);
                            
                        } failure:errorBlock];
                        
                    } failure:errorBlock];
                    
                } failure:errorBlock];
                
            } failure:errorBlock];
            
        } failure:errorBlock];
        
        dispatch_group_wait(fetchGroup, DISPATCH_TIME_FOREVER);
    });
}

#pragma mark - Internal

- (NSArray *)remoteGeoPointsFromLocal:(NSArray *)localGeoPoints
{
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[localGeoPoints count]];
    for (PRLocalGeoPoint *point in localGeoPoints) {
        [array addObject:[[PRRemoteGeoPoint alloc] initWithLocalGeoPoint:point]];
    }
    return array;
}

- (NSArray *)localGeoPointsFromResponseData:(NSData *)data
{
    if (data) {
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        NSArray *source = [(NSDictionary *)json objectForKey:@"locations"];
        NSMutableArray *remoteGeoPoints = [NSMutableArray new];
        for (id object in source) {
            [remoteGeoPoints addObject:[[PRRemoteGeoPoint alloc] initWithJSON:object]];
        }
    
        [self.storeManager updateUserGeoPoints:remoteGeoPoints];
    }
    
    __block NSSet *results = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        results = self.currentUser.locations;
    });
    
    NSMutableArray *localResults = [[NSMutableArray alloc] initWithCapacity:[results count]];
    for (GeoPoint *geoPoint in results) {
        PRLocalGeoPoint *lPoint = [[PRLocalGeoPoint alloc] initWithLatitude:[geoPoint.latitude floatValue] longitude:[geoPoint.longitude floatValue] title:geoPoint.title];
        [localResults addObject:lPoint];
    }
    return localResults;
}

- (NSArray *)localCategoriesFromResponseData:(NSData *)data
{
    NSArray *results = nil;
    if (data) {
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        results = [PRRemoteResults resultsWithData:json contentType:[PRRemoteCategory class]];
        [self.storeManager updateCategories:results];
    }
    __block NSArray *localResults = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        localResults = [self.storeManager allLocalCategoriesForMain];
    });
    _allCategories = localResults;
    return localResults;
}

- (NSArray *)localUserCategoriesFromResponseData:(NSData *)data
{
    NSArray *results = nil;
    if (data) {
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        results = [PRRemoteResults resultsWithData:json contentType:[PRRemoteCategory class]];
        [self.storeManager updateUserCategories:results];
    }
    __block NSSet *interests = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        interests = self.currentUser.interests;
    });
    return [interests allObjects];
}

- (NSArray *)localArticlesFromResponseData:(NSData *)data
{
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSArray *results = [PRRemoteResults resultsWithData:json contentType:[PRRemoteArticle class]];
    [self.storeManager updateArticles:results];
    
    NSMutableSet *ids = [NSMutableSet new];
    for (PRRemoteArticle *article in results) {
        [ids addObject:article.objectId];
    }
    
    __block NSArray *articles = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        articles = [[self.storeManager localArticlesWithIds:ids] sortedArrayUsingComparator:^NSComparisonResult(Article *obj1, Article *obj2) {
            return [obj2.rating compare:obj1.rating];
        }];
    });
    
    return articles;
}

- (NSArray *)localMediaFromResponseData:(NSData *)data forArticleWithId:(NSString *)articleId
{
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSArray *results = [PRRemoteResults resultsWithData:json contentType:[PRRemoteMedia class]];
    [self.storeManager updateMediaForArticleWithId:articleId newMedia:results];
    __block NSArray *localResults = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        localResults = [self.storeManager localMediaForArticleWithId:articleId];
    });
    return localResults;
}

- (NSArray *)categoriesIdsFrom:(NSArray *)categories
{
    NSMutableArray *ids = [[NSMutableArray alloc] initWithCapacity:[categories count]];
    for (InterestCategory *category in categories) {
        [ids addObject:category.remoteIdentifier];
    }
    return ids;
}

- (void)setNetworkSessionKey:(NSString *)networkSessionKey
{
    if (![_networkSessionKey isEqualToString:networkSessionKey]) {
        [[NSUserDefaults standardUserDefaults] setObject:networkSessionKey forKey:@"network_session_key"];
        _networkSessionKey = networkSessionKey;
    }
}

- (NSString *)networkSessionKey
{
    if (!_networkSessionKey) {
        _networkSessionKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"network_session_key"];
    }
    return _networkSessionKey;
}

@end
