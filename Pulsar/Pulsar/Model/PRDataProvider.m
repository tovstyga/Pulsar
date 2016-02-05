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

static NSString * const kCoreUserTable = @"User";
static NSString * const kCoreGeoPointTable = @"GeoPoint";
static NSString * const kCoreInterestCategoryTable = @"InterestCategory";
static NSString * const kCoreMediaTable = @"Media";
static NSString * const kCoreArticleTable = @"Article";

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
        _currentUser = [self loadUser];
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
        [self resumeSession:nil]; //for loading user data
        if (completion) {
            completion(nil);
        }
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
            [self createIfNeedsUserWithId:sessionInfo.objectId email:sessionInfo.email name:sessionInfo.userName];
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
    [[PRNetworkDataProvider sharedInstance] validateSessionToken:self.networkSessionKey success:^(NSData *data, NSURLResponse *response) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            PRTokenValidationResponse *validationResponse = [[PRTokenValidationResponse alloc] initWithJSON:json];
            [self createIfNeedsUserWithId:validationResponse.objectId email:validationResponse.email name:validationResponse.userName];
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
    [self addUserCategories:categories remove:nil];
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
    [self addUserCategories:nil remove:categories];
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
    [self addUserCategories:addCategories remove:removeCategories];
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
            Media *bgMedia = [self madiaForBGWithId:media.remoteIdentifier];
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
            Media *bgMedia = [self madiaForBGWithId:media.remoteIdentifier];
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
            completion(result, nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(nil, error);
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
            completion(result, nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(nil, error);
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
    //нужно мержить результаты выборки с прошлыми результатами или фирмировтаь исключения при запросе
    [[PRNetworkDataProvider sharedInstance] requestHotArticlesWithCategoriesIds:[self categoriesIdsFrom:[self.currentUser.interests allObjects]] minRating:NSIntegerMax from:_hotArticleCount step:kFetchLimith locations:[self.currentUser.locations allObjects] success:^(NSData *data, NSURLResponse *response) {
        NSArray *articles = [self localArticlesFromResponseData:data];
        _hotArticleCount +=[articles count];
        _minRatingArticle = [[(Article *)[articles lastObject] rating] integerValue];
        if (completion) {
            completion(articles ,nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(nil, error);
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
    [[PRNetworkDataProvider sharedInstance] requestNewArticlesWithCategoriesIds:[self categoriesIdsFrom:[self.currentUser.interests allObjects]] lastDate:_newArticleRequestTime form:_newArticlesCount step:kFetchLimith locations:[self.currentUser.locations allObjects] success:^(NSData *data, NSURLResponse *response) {
        NSArray *articles = [[self localArticlesFromResponseData:data] sortedArrayUsingComparator:^NSComparisonResult(Article *obj1, Article *obj2) {
            return [obj2.createdDate compare:obj1.createdDate];
        }];
        _newArticlesCount += [articles count];
        if (completion) {
            completion(articles ,nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
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
        NSArray *geoPoints = [self.currentUser.locations allObjects];
        __block PRArticleCollection *articleCollection = [[PRArticleCollection alloc] init];
        dispatch_group_t fetchGroup = dispatch_group_create();
        dispatch_group_enter(fetchGroup);
        [[PRNetworkDataProvider sharedInstance] requestTopArticlesWithCategoriesIds:categoriest beforeDate:[now dateByAddingTimeInterval:-HOUR -gmtCorrection] locations:geoPoints success:^(NSData *data, NSURLResponse *response) {
            [articleCollection setFetchResult:[self localArticlesFromResponseData:data] forKey:PRArticleFetchHour];
            
            [[PRNetworkDataProvider sharedInstance] requestTopArticlesWithCategoriesIds:categoriest beforeDate:[now dateByAddingTimeInterval:-DAY -gmtCorrection] locations:geoPoints success:^(NSData *data, NSURLResponse *response) {
                [articleCollection setFetchResult:[self localArticlesFromResponseData:data] forKey:PRArticleFetchDay];
                
                [[PRNetworkDataProvider sharedInstance] requestTopArticlesWithCategoriesIds:categoriest beforeDate:[now dateByAddingTimeInterval:-WEEK -gmtCorrection] locations:geoPoints success:^(NSData *data, NSURLResponse *response) {
                    [articleCollection setFetchResult:[self localArticlesFromResponseData:data] forKey:PRArticleFetchWeek];
                    
                    [[PRNetworkDataProvider sharedInstance] requestTopArticlesWithCategoriesIds:categoriest beforeDate:[now dateByAddingTimeInterval:-MONTH -gmtCorrection] locations:geoPoints success:^(NSData *data, NSURLResponse *response) {
                        [articleCollection setFetchResult:[self localArticlesFromResponseData:data] forKey:PRArticleFetchMonth];
                        
                        [[PRNetworkDataProvider sharedInstance] requestTopArticlesWithCategoriesIds:categoriest beforeDate:[now dateByAddingTimeInterval:-YEAR -gmtCorrection] locations:geoPoints success:^(NSData *data, NSURLResponse *response) {
                            
                            [articleCollection setFetchResult:[self localArticlesFromResponseData:data] forKey:PRArticleFetchYear];
                            if (completion) {
                                completion(articleCollection, nil);
                            }
                            dispatch_group_leave(fetchGroup);
                            
                        } failure:^(NSError *error) {
                            if (completion) {
                                completion(nil, error);
                            }
                            dispatch_group_leave(fetchGroup);
                        }];
                        
                    } failure:^(NSError *error) {
                        if (completion) {
                            completion(nil, error);
                        }
                        dispatch_group_leave(fetchGroup);
                    }];
                    
                } failure:^(NSError *error) {
                    if (completion) {
                        completion(nil, error);
                    }
                    dispatch_group_leave(fetchGroup);
                }];
                
            } failure:^(NSError *error) {
                if (completion) {
                    completion(nil, error);
                }
                dispatch_group_leave(fetchGroup);
            }];
            
        } failure:^(NSError *error) {
            if (completion) {
                completion(nil, error);
            }
            dispatch_group_leave(fetchGroup);
        }];
        
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
    
        [self updateUserGeoPoints:remoteGeoPoints];
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
        [self updateCategories:results];
    }
    __block NSArray *localResults = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        localResults = [self allLocalCategoriesForMain];
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
        [self updateUserCategories:results];
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
    [self updateArticles:results];
    
    NSMutableSet *ids = [NSMutableSet new];
    for (PRRemoteArticle *article in results) {
        [ids addObject:article.objectId];
    }
    
    __block NSArray *articles = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        articles = [[self localArticlesWithIds:ids] sortedArrayUsingComparator:^NSComparisonResult(Article *obj1, Article *obj2) {
            return [obj2.rating compare:obj1.rating];
        }];
    });
    
    return articles;
}

- (NSArray *)localMediaFromResponseData:(NSData *)data forArticleWithId:(NSString *)articleId
{
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSArray *results = [PRRemoteResults resultsWithData:json contentType:[PRRemoteMedia class]];
    [self updateMediaForArticleWithId:articleId newMedia:results];
    __block NSArray *localResults = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        localResults = [self localMediaForArticleWithId:articleId];
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

#pragma mark - Core Data

- (void)preloading
{
    dispatch_group_t loadingGroup = dispatch_group_create();
    //update categories
    dispatch_group_enter(loadingGroup);
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

- (BOOL)createIfNeedsUserWithId:(NSString *)identifier email:(NSString *)email name:(NSString *)name
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreUserTable];
    [request setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier == %@", identifier]];
    NSError *error = nil;
    NSArray *result = [[[PRLocalDataStore sharedInstance] backgroundContext] executeFetchRequest:request error:&error];
    if ([result count]) {
        [self preloading];
        return YES;
    }
    
    User *user = [NSEntityDescription insertNewObjectForEntityForName:kCoreUserTable inManagedObjectContext:[[PRLocalDataStore sharedInstance] backgroundContext]];
    user.remoteIdentifier = identifier;
    user.email = email;
    user.userName = name;
    [[PRLocalDataStore sharedInstance] saveBackgroundContext];
    
    [self preloading];
    
    return YES;
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
    NSError *error;
    NSArray *fetchResult = [[[PRLocalDataStore sharedInstance] backgroundContext] executeFetchRequest:request error:&error];
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
    
    [[PRLocalDataStore sharedInstance] saveBackgroundContext];
    
}

- (NSArray<InterestCategory *> *)allLocalCategoriesForMain
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreInterestCategoryTable];
    NSError *error;
    return [[[PRLocalDataStore sharedInstance] mainContext] executeFetchRequest:request error:&error];
}

- (void)updateUserCategories:(NSArray<PRRemoteCategory *> *)categories
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreUserTable];
    [request setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier == %@", [PRNetworkDataProvider sharedInstance].currentUser]];
    NSError *error;
    User *user = [[[[PRLocalDataStore sharedInstance] backgroundContext] executeFetchRequest:request error:&error] firstObject];
    
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
        NSArray *add = [[[PRLocalDataStore sharedInstance] backgroundContext] executeFetchRequest:localCategoriesRequest error:nil];
        NSSet *forAdd = [[NSSet alloc] initWithArray:add];
        [user addInterests:forAdd];
    }
    
    [[PRLocalDataStore sharedInstance] saveBackgroundContext];
}

- (void)addUserCategories:(NSArray<InterestCategory *> *)addCategories remove:(NSArray<InterestCategory *> *)removeCategories
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreUserTable];
    [request setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier == %@", [PRNetworkDataProvider sharedInstance].currentUser]];
    NSError *error;
    User *user = [[[[PRLocalDataStore sharedInstance] mainContext] executeFetchRequest:request error:&error] firstObject];
    
    if (removeCategories) {
        NSSet *remove = [[NSSet alloc] initWithArray:removeCategories];
        [user removeInterests:remove];
    }
    
    if (addCategories) {
        NSSet *add = [[NSSet alloc] initWithArray:addCategories];
        [user addInterests:add];
    }
    
    [[PRLocalDataStore sharedInstance] saveMainContextAndWait:NO];
}

- (void)updateUserGeoPoints:(NSArray<PRRemoteGeoPoint *> *)newPoints
{
    NSManagedObjectContext *workContext = [[PRLocalDataStore sharedInstance] backgroundContext];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreUserTable];
    [request setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier == %@", [PRNetworkDataProvider sharedInstance].currentUser]];
    NSError *error;
    User *user = [[workContext executeFetchRequest:request error:&error] firstObject];
    
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
    NSArray *existsArticles = [[[PRLocalDataStore sharedInstance] backgroundContext] executeFetchRequest:request error:nil];
    
    for (Article *article in existsArticles) {
        for (PRRemoteArticle *rArticle in remoteArticle) {
            if ([article.remoteIdentifier isEqualToString:rArticle.objectId]) {
                [articlesForCreate removeObject:rArticle];
                [self updateArticle:article newData:rArticle];
            }
        }
    }
    
    for (PRRemoteArticle *article in articlesForCreate) {
        Article *newArticle = [NSEntityDescription insertNewObjectForEntityForName:kCoreArticleTable inManagedObjectContext:[[PRLocalDataStore sharedInstance] backgroundContext]];
        [self updateArticle:newArticle newData:article];
    }
    
    [[PRLocalDataStore sharedInstance] saveBackgroundContext];
}

- (void)updateArticle:(Article *)localArticle newData:(PRRemoteArticle *)remoteArticle
{
    localArticle.annotation = remoteArticle.annotation;
    localArticle.author = remoteArticle.author;
    
    localArticle.canLike = @(YES);
    for (NSString *likers in remoteArticle.likes) {
        if ([likers isEqualToString:self.currentUser.remoteIdentifier]) {
            localArticle.canLike = @(NO);
            break;
        }
    }
    
    localArticle.canDislike = @(YES);
    for (NSString *dislikers in remoteArticle.disLikes) {
        if ([dislikers isEqualToString:self.currentUser.remoteIdentifier]) {
            localArticle.canDislike = @(NO);
            break;
        }
    }
    
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
    Article *article = [[[[PRLocalDataStore sharedInstance] backgroundContext] executeFetchRequest:request error:nil] firstObject];
    
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

@end
