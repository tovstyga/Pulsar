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
#import "PRLocalArticle.h"
#import "PRConstants.h"

#import "PRLocalDataStore.h"

#define HOUR 60*60
#define DAY HOUR*24
#define WEEK DAY*7
#define MONTH DAY*30
#define YEAR DAY * 365

@interface PRDataProvider()

@property (strong, nonatomic) NSString *networkSessionKey;
@property (copy, nonatomic) NSArray *templateGeoPoints;
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
@dynamic userIdentifier;

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

- (NSString *)userIdentifier
{
    return [[PRNetworkDataProvider sharedInstance] currentUser];
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
        [self createIfNeedsUserWithId:sessionInfo.objectId email:sessionInfo.email name:sessionInfo.userName];
        if (completion) {
            completion(nil);
        }
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
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        PRTokenValidationResponse *validationResponse = [[PRTokenValidationResponse alloc] initWithJSON:json];
        [self createIfNeedsUserWithId:validationResponse.objectId email:validationResponse.email name:validationResponse.userName];
        if (completion) {
            completion(YES);
        }
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
            completion(nil, error);
        }
    }];
}

- (void)categoriesForCurrentUser:(void(^)(NSArray *categories, NSError *error))completion
{
    [[PRNetworkDataProvider sharedInstance] requestCategoriesForCurrentUserWithSuccess:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion([self localCategoriesFromResponseData:data], nil);
        }
    } failure:^(NSError *error) {
        completion(nil, error);
    }];
}

- (void)addCategoryForCurrentUser:(PRLocalCategory *)category completion:(void(^)(NSError *error))completion
{
    [self addCategoriesForCurrentUser:@[category.identifier] completion:completion];
}

- (void)addCategoriesForCurrentUser:(NSArray *)categories completion:(void(^)(NSError *error))completion
{
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

- (void)removeCategoryForCurrentUser:(PRLocalCategory *)category completion:(void(^)(NSError *error))completion
{
    [self removeCategoriesForCurrentUser:@[category.identifier] completion:completion];
}

- (void)removeCategoriesForCurrentUser:(NSArray *)categories completion:(void(^)(NSError *error))completion
{
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
    if (self.templateGeoPoints && completion) {
        completion(self.templateGeoPoints, nil);
        return;
    }
    
    [[PRNetworkDataProvider sharedInstance] requesGeoPointsWithSuccess:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion([self localGeoPointsFromResponseData:data], nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

- (void)publishNewArticle:(PRLocalNewArticle *)localArticle completion:(void(^)(NSError *error))completion
{
    __block PRRemotePublishedArticle *remoteArticle = [[PRRemotePublishedArticle alloc] init];
    remoteArticle.title = localArticle.title;
    remoteArticle.annotation = localArticle.annotation;
    remoteArticle.text = localArticle.text;
    remoteArticle.author = [[PRRemotePointer alloc] initWithClass:kUserClassName remoteObjectId:[PRNetworkDataProvider sharedInstance].currentUser];
    remoteArticle.category = [[PRRemotePointer alloc] initWithClass:kCategoryClassName remoteObjectId:localArticle.category.identifier];
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

- (void)loadDataFromUrl:(NSURL *)url completion:(void (^)(NSData *, NSError *))completion
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

- (void)loadMediaForArticle:(PRLocalArticle *)localArticle completion:(void(^)(NSArray<PRLocalMedia *> *mediaArray, NSError *error))completion
{
    [[PRNetworkDataProvider sharedInstance] requestMediaForArticleWithId:localArticle.objectId success:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion([self localMediaFromResponseData:data], nil);
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
            completion([self localArticlesFromResponseData:data], nil);
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
            completion([self localArticlesFromResponseData:data], nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

- (void)addArticleToFavorite:(PRLocalArticle *)article success:(void(^)(NSError *error))completion
{
    [[PRNetworkDataProvider sharedInstance] requestAddArticleToFavorite:article.objectId success:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)remoteArticleFromFavorite:(PRLocalArticle *)article success:(void(^)(NSError *error))completion
{
    [[PRNetworkDataProvider sharedInstance] requestRemoveArticleFromFavorite:article.objectId success:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)likeArticle:(PRLocalArticle *)article success:(void(^)(NSError *error))completion
{
    [[PRNetworkDataProvider sharedInstance] requestLikeArticle:article success:^(NSData *data, NSURLResponse *response) {
        if (completion) {
            completion(nil);
        }
    } failure:^(NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)dislikeArticle:(PRLocalArticle *)article success:(void(^)(NSError *error))completion
{
    [[PRNetworkDataProvider sharedInstance] requestDislikeArticle:article success:^(NSData *data, NSURLResponse *response) {
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
    [[PRNetworkDataProvider sharedInstance] requestHotArticlesWithCategories:self.templateSelectedCategories minRating:NSIntegerMax from:_hotArticleCount step:kFetchLimith locations:self.templateGeoPoints success:^(NSData *data, NSURLResponse *response) {
        NSArray *articles = [self localArticlesFromResponseData:data];
        _hotArticleCount +=[articles count];
        _minRatingArticle = [(PRLocalArticle *)[articles lastObject] rating];
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
    [[PRNetworkDataProvider sharedInstance] requestNewArticlesWithCategories:self.templateSelectedCategories lastDate:_newArticleRequestTime form:_newArticlesCount step:kFetchLimith locations:self.templateGeoPoints success:^(NSData *data, NSURLResponse *response) {
        NSArray *articles = [self localArticlesFromResponseData:data];
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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInteger gmtCorrection = [[NSTimeZone localTimeZone] secondsFromGMT];
        NSDate *now = [NSDate date];
        NSArray *categoriest = self.templateSelectedCategories;
        NSArray *geoPoints = self.templateGeoPoints;
        __block PRArticleCollection *articleCollection = [[PRArticleCollection alloc] init];
        dispatch_group_t fetchGroup = dispatch_group_create();
        dispatch_group_enter(fetchGroup);
        [[PRNetworkDataProvider sharedInstance] requestTopArticlesWithCategories:categoriest beforeDate:[now dateByAddingTimeInterval:-HOUR -gmtCorrection] locations:geoPoints success:^(NSData *data, NSURLResponse *response) {
            [articleCollection setFetchResult:[self localArticlesFromResponseData:data] forKey:PRArticleFetchHour];
            
            [[PRNetworkDataProvider sharedInstance] requestTopArticlesWithCategories:categoriest beforeDate:[now dateByAddingTimeInterval:-DAY -gmtCorrection] locations:geoPoints success:^(NSData *data, NSURLResponse *response) {
                [articleCollection setFetchResult:[self localArticlesFromResponseData:data] forKey:PRArticleFetchDay];
                
                [[PRNetworkDataProvider sharedInstance] requestTopArticlesWithCategories:categoriest beforeDate:[now dateByAddingTimeInterval:-WEEK -gmtCorrection] locations:geoPoints success:^(NSData *data, NSURLResponse *response) {
                    [articleCollection setFetchResult:[self localArticlesFromResponseData:data] forKey:PRArticleFetchWeek];
                    
                    [[PRNetworkDataProvider sharedInstance] requestTopArticlesWithCategories:categoriest beforeDate:[now dateByAddingTimeInterval:-MONTH -gmtCorrection] locations:geoPoints success:^(NSData *data, NSURLResponse *response) {
                        [articleCollection setFetchResult:[self localArticlesFromResponseData:data] forKey:PRArticleFetchMonth];
                        
                        [[PRNetworkDataProvider sharedInstance] requestTopArticlesWithCategories:categoriest beforeDate:[now dateByAddingTimeInterval:-YEAR -gmtCorrection] locations:geoPoints success:^(NSData *data, NSURLResponse *response) {
                            
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
    id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSArray *source = [(NSDictionary *)json objectForKey:@"locations"];
    NSMutableArray *remoteGeoPoints = [NSMutableArray new];
    for (id object in source) {
        [remoteGeoPoints addObject:[[PRRemoteGeoPoint alloc] initWithJSON:object]];
    }
    NSMutableArray *localResults = [[NSMutableArray alloc] initWithCapacity:remoteGeoPoints.count];
    for (PRRemoteGeoPoint *point in remoteGeoPoints) {
        [localResults addObject:[[PRLocalGeoPoint alloc] initWithRemoteGeoPoint:point]];
    }
    self.templateGeoPoints = localResults;
    return localResults;
}

- (NSArray *)localCategoriesFromResponseData:(NSData *)data
{
    id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSArray *results = [PRRemoteResults resultsWithData:json contentType:[PRRemoteCategory class]];
    NSMutableArray *localResults = [[NSMutableArray alloc] initWithCapacity:[results count]];
    for (PRRemoteCategory *category in results) {
        [localResults addObject:[[PRLocalCategory alloc] initWithRemoteCategory:category]];
    }
    return localResults;
}

- (NSArray *)localArticlesFromResponseData:(NSData *)data
{
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSArray *results = [PRRemoteResults resultsWithData:json contentType:[PRRemoteArticle class]];
    NSMutableArray *localResults = [[NSMutableArray alloc] initWithCapacity:[results count]];
    for (PRRemoteArticle *article in results) {
        [localResults addObject:[[PRLocalArticle alloc] initWithRemoteArticle:article]];
    }
    return localResults;
}

- (NSArray *)localMediaFromResponseData:(NSData *)data
{
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSArray *results = [PRRemoteResults resultsWithData:json contentType:[PRRemoteMedia class]];
    NSMutableArray *localResults = [[NSMutableArray alloc] initWithCapacity:[results count]];
    for (PRRemoteMedia *rMedia in results) {
        [localResults addObject:[[PRLocalMedia alloc] initWithRemoteMedia:rMedia]];
    }
    return localResults;
}

- (NSArray *)categoriesIdsFrom:(NSArray *)categories
{
    NSMutableArray *ids = [[NSMutableArray alloc] initWithCapacity:[categories count]];
    for (PRLocalCategory *category in categories) {
        [ids addObject:category.identifier];
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

- (BOOL)createIfNeedsUserWithId:(NSString *)identifier email:(NSString *)email name:(NSString *)name
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kCoreUserTable];
    [request setPredicate:[NSPredicate predicateWithFormat:@"remoteIdentifier == %@", identifier]];
    NSError *error = nil;
    NSArray *result = [[[PRLocalDataStore sharedInstance] backgroundContext] executeFetchRequest:request error:&error];
    if ([result count]) {
        return YES;
    }
    if (error) {
        return NO;
    } else {
        User *user = [NSEntityDescription insertNewObjectForEntityForName:kCoreUserTable inManagedObjectContext:[[PRLocalDataStore sharedInstance] backgroundContext]];
        user.remoteIdentifier = identifier;
        user.email = email;
        user.userName = name;
        [[PRLocalDataStore sharedInstance] saveBackgroundContext];
    }
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

@end
