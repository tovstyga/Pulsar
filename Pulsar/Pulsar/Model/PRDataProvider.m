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

#import "PRRemoteResults.h"
#import "PRRemoteCategory.h"
#import "PRLocalGeoPoint.h"
#import "PRRemoteGeoPoint.h"

@interface PRDataProvider()

@property (strong, nonatomic) NSString *networkSessionKey;
@property (copy, nonatomic) NSArray *templateGeoPoints;

@end

@implementation PRDataProvider

@synthesize networkSessionKey = _networkSessionKey;

static PRDataProvider *sharedInstance;

- (instancetype)init
{
    if (sharedInstance) {
        return sharedInstance;
    } else {
        [PRNetworkDataProvider sharedInstance];
        return [super init];
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

#pragma mark - session and autрorization

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
#warning update database
    for (PRRemoteCategory *category in results) {
        [localResults addObject:[[PRLocalCategory alloc] initWithRemoteCategory:category]];
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

@end
