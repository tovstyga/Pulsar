//
//  PRNetworkDataProvider.m
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRNetworkDataProvider.h"
#import "PRReachability.h"
#import "PRConstants.h"
#import "PRJsonCompatable.h"

#import "PRRemoteRegistrationResponse.h"
#import "PRRemoteLoginResponse.h"
#import "PRRemoteError.h"
#import "PRTokenValidationResponse.h"

#import "PRRemotePointer.h"
#import "PRRemoteQuery.h"
#import "PRRemoteBatchRequestObject.h"
#import "PRRemoteArray.h"

@interface PRNetworkDataProvider()

@property (strong, nonatomic, readonly) PRReachability *reachability;

@end

@implementation PRNetworkDataProvider{
    NSString *_sessionToken;
    NSURL *_baseURL;
}

@synthesize currentUser = _currentUser;

typedef NS_ENUM(NSUInteger, PRRequestType) {
    PRRequestTypeLogin,
    PRRequestTypeLogout,
    PRRequestTypeRegistration,
    PRRequestTypeResetPassword,
    PRRequestTypeSessionValidation,
    PRRequestTypeAllCategories,
    PRRequestTypeCategoriesForUser,
    PRRequestTypeCategoryRelation,
    PRRequestTypeBatch,
    PRREquestTypeUserGeoPoints,
    PRRequestTypeUpload,
    PRRequestTypePublishArticle,
    PRRequestTypeNewMedia,
    PRRequestTypeLoadData,
    PRRequestTypeArticle,
    PRRequestTypeLoadMedia,
    PRRequestTypeArticlesForUser,
    PRRequestTypeFavoriteAction,
    PRRequestTypeArticleWithQuery
};

//constants
//HTTP methods

static NSString * const kHTTPMethodGET = @"GET";
static NSString * const kHTTPMethodHEAD = @"HEAD";
static NSString * const kHTTPMethodPOST = @"POST";
static NSString * const kHTTPMethodPUT = @"PUT";
static NSString * const kHTTPMethodDELETE = @"DELETE";
static NSString * const kHTTPMethodTRACE = @"TRACE";
static NSString * const kHTTPMethodOPTIONS = @"OPTIONS";
static NSString * const kHTTPMethodCONNECT = @"CONNECT";
static NSString * const kHTTPMethodPATCH = @"PATCH";

//header keys

static NSString * const kHeaderParseApplicationIdKey = @"X-Parse-Application-Id";
static NSString * const kHeaderParseRestApiKey = @"X-Parse-REST-API-Key";
static NSString * const kHeaderParseRevocableSessionKey = @"X-Parse-Revocable-Session";
static NSString * const kHeaderParseSessionTokenKey = @"X-Parse-Session-Token";
static NSString * const kHeaderContentTypeKey = @"Content-Type";

//HTTP path parameters

static NSString * const kPathParamUsernameKay = @"username";
static NSString * const kPathParamPasswordKey = @"password";
static NSString * const kPathParamIncludeKey = @"include";
static NSString * const kPathParamOrder = @"order";
static NSString * const kPathParamLimit = @"limit";
static NSString * const kPathParamSkip = @"skip";

//content types

static NSString * const kContentTypeApplicationJSON = @"application/json";
static NSString * const kContentTypeImagePng = @"image/png";

//ids

static NSString * const kParseApplicationId = @"HbQ3zhjz45cliycC3EoBxKWM4qf9LH7F6dpatiP8";
static NSString * const kParseRestApiKey = @"NePEmzWEYQJ1jfAGOruWhLqyahlNrdLzWspgGMxe";
static NSString * const kParseRevocableSession = @"1";

static NSString * const kArticleIncludeFields = @"author,image,tag";
static NSString * const kNewOrder = @"-createdAt";
static NSString * const kHotOrder = @"-rating";
static NSString * const kTopOrder = @"-rating";

static PRNetworkDataProvider *sharedInstance;

- (instancetype)init
{
    if (sharedInstance) {
        return sharedInstance;
    } else {
        self = [super init];
        if (self) {
            _reachability = [[PRReachability alloc] init];
            NSString *url = [NSString stringWithFormat:@"%@/%ld", kPRParseServer, (long)kPRParseAPIVersion];
            _baseURL = [NSURL URLWithString:url];
        }
        return self;
    }
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[PRNetworkDataProvider alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Account

- (void)requestRegistration:(id<PRJsonCompatable>)registrationRequest
                    success:(PRNetworkSuccessBlock)success
                    failure:(PRNetworkFailureBlock)failure
{
    
    if ([self isNetworkAvailable:failure]) {
        NSMutableURLRequest *request = [self requestForType:PRRequestTypeRegistration];
        NSData *body = [NSJSONSerialization dataWithJSONObject:[registrationRequest toJSONCompatable] options:NSJSONWritingPrettyPrinted error:nil];
        [request setHTTPBody:body];
        
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                PRRemoteRegistrationResponse *sessionInfo = [[PRRemoteRegistrationResponse alloc] initWithJSON:json];
                _sessionToken = sessionInfo.sessionToken;
                if (success) success(data, response);
            }
        }];
    }
}

- (void)requestLoginUser:(NSString *)userName
                password:(NSString *)password
                 success:(PRNetworkSuccessBlock)success
                 failure:(PRNetworkFailureBlock)failure
{
    
    if ([self isNetworkAvailable:failure]) {
         NSDictionary *params = @{kPathParamUsernameKay : userName, kPathParamPasswordKey : password};
        [self performRequest:[self requestForType:PRRequestTypeLogin params:params] completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                PRRemoteLoginResponse *sessionInfo = [[PRRemoteLoginResponse alloc] initWithJSON:json];
                _sessionToken = sessionInfo.sessionToken;
                _currentUser = sessionInfo.objectId;
                if (success) success(data, response);
            }
        }];
    }
}

- (void)requestLogoutWithSuccess:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if (!_sessionToken && success) {
        success(nil, nil);
        return;
    }
    
    if ([self isNetworkAvailable:failure]) {
        [self performRequest:[self requestForType:PRRequestTypeLogout] completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                _sessionToken = nil;
                _currentUser = nil;
                if (success) success(data, response);
            }
        }];
    }
}

- (void)requestResetPassword:(id<PRJsonCompatable>)resetRequest success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        NSMutableURLRequest *request = [self requestForType:PRRequestTypeResetPassword];
        NSData *body = [NSJSONSerialization dataWithJSONObject:[resetRequest toJSONCompatable] options:NSJSONWritingPrettyPrinted error:nil];
        [request setHTTPBody:body];
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else if (success) {
                success(data, response);
            }
        }];
    }
}

- (void)validateSessionToken:(NSString *)token success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        NSMutableURLRequest *request = [self requestForType:PRRequestTypeSessionValidation];
        [request setValue:token forHTTPHeaderField:kHeaderParseSessionTokenKey];
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                PRTokenValidationResponse *validationResponse = [[PRTokenValidationResponse alloc] initWithJSON:json];
                _sessionToken = validationResponse.sessionToken;
                _currentUser = validationResponse.objectId;
                if (success) success(data, response);
            }
        }];
        
    }
}

#pragma mark - Categories

- (void)requestCategoriesWithSuccess:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        [self performRequest:[self requestForType:PRRequestTypeAllCategories] completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
}

- (void)requestCategoriesForCurrentUserWithSuccess:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if (![self isNetworkAvailable:failure]) {
        return;
    }
    
    void(^processingBlock)() = ^(){
        [self performRequest:[self requestForType:PRRequestTypeCategoriesForUser] completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    };
    
    if (_currentUser) {
        processingBlock();
    } else {
        [self validateSessionToken:_sessionToken success:^(NSData *data, NSURLResponse *response) {
            processingBlock();
        } failure:^(NSError *error) {
            failure(error);
        }];
    }
}

- (void)requestAddCategoriesWithIdsForCurrentUser:(NSArray *)ids success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        if ([ids count] > 1) {
            [self requestUpdateUserCategoriesForAdd:ids remove:nil success:success failure:failure];
        } else {
            NSMutableURLRequest *request = [self requestForType:PRRequestTypeCategoryRelation];
            request.URL = [request.URL URLByAppendingPathComponent:[ids firstObject]];
            NSDictionary *body = [self queryAddUserCaregory];
            NSData *json = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:nil];
            [request setHTTPBody:json];
            [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error && failure) {
                    failure(error);
                } else {
                    if (success) success(data, response);
                }
            }];
        }
    }
}

- (void)requestRemoveCategoriesWithIdsForCurrentUser:(NSArray *)ids success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        if ([ids count] > 1) {
            [self requestUpdateUserCategoriesForAdd:nil remove:ids success:success failure:failure];
        } else {
            NSMutableURLRequest *request = [self requestForType:PRRequestTypeCategoryRelation];
            request.URL = [request.URL URLByAppendingPathComponent:[ids firstObject]];
            NSDictionary *body = [self queryRemoveUserCaregory];
            NSData *json = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:nil];
            [request setHTTPBody:json];
            [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error && failure) {
                    failure(error);
                } else {
                    if (success) success(data, response);
                }
            }];
        }
    }
}

- (void)requestUpdateUserCategoriesForAdd:(NSArray *)addIds
                                   remove:(NSArray *)removeIds
                                  success:(PRNetworkSuccessBlock)success
                                  failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        NSMutableURLRequest *request = [self requestForType:PRRequestTypeBatch];
        NSDictionary *body = [self batchQueryForAddCategories:addIds removeCategories:removeIds];
        NSData *json = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:nil];
        [request setHTTPBody:json];
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
}

#pragma mark - Geopoints

- (void)requesGeoPointsWithSuccess:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        NSMutableURLRequest *request = [self requestForType:PRRequestTypeSessionValidation];
        [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
}

- (void)requestAddGeopoints:(NSArray *)geopoints success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    PRRemoteArray *array = [[PRRemoteArray alloc] initWithField:@"locations" action:PRRemoteArrayActionAddUnique objects:geopoints];
    [self requestToUserGeoPointsWith:[array toJSONCompatable] success:success failure:failure];
}

- (void)requestRemoveGeopoints:(NSArray *)geopoints success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    PRRemoteArray *array = [[PRRemoteArray alloc] initWithField:@"locations" action:PRRemoteArrayActionRemove objects:geopoints];
    [self requestToUserGeoPointsWith:[array toJSONCompatable] success:success failure:failure];
}

- (void)requestToUserGeoPointsWith:(NSDictionary *)body success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        NSMutableURLRequest *request = [self requestForType:PRREquestTypeUserGeoPoints];
        NSData *data = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:nil];
        [request setHTTPBody:data];
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
}

#pragma mark - Publishing

- (void)uploadData:(NSData *)data fileName:(NSString *)fileName success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        NSMutableURLRequest *request = [self requestForType:PRRequestTypeUpload];
        request.URL = [request.URL URLByAppendingPathComponent:fileName];
        [request setHTTPBody:data];
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
}

- (void)requestPublishArticle:(id<PRJsonCompatable>)article success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        NSMutableURLRequest *request = [self requestForType:PRRequestTypePublishArticle];
        NSData *body = [NSJSONSerialization dataWithJSONObject:[article toJSONCompatable] options:NSJSONWritingPrettyPrinted error:nil];
        [request setHTTPBody:body];
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
}

- (void)requestNewMedia:(id<PRJsonCompatable>)media success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        NSMutableURLRequest *request = [self requestForType:PRRequestTypeNewMedia];
        NSData *body = [NSJSONSerialization dataWithJSONObject:[media toJSONCompatable] options:NSJSONWritingPrettyPrinted error:nil];
        [request setHTTPBody:body];
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
}

#pragma mark - Articles

- (void)loadDataFromURL:(NSURL *)url success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        NSMutableURLRequest *request = [self requestForType:PRRequestTypeLoadData];
        request.URL = url;
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
}

- (void)requestMediaForArticleWithId:(NSString *)articleId success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        NSMutableURLRequest *request = [self requestForType:PRRequestTypeLoadMedia];
        NSData *data = [NSJSONSerialization dataWithJSONObject:[self queryMediaForArticle:articleId] options:NSJSONWritingPrettyPrinted error:nil];
        [request setHTTPBody:data];
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
}

- (void)requestHotArticlesWithCategoriesIds:(NSArray *)categoriesIds
                               minRating:(NSInteger)minRating
                                    from:(int)lastIndex
                                    step:(int)step
                               locations:(CLLocationCoordinate2D)location
                                 success:(PRNetworkSuccessBlock)success
                                 failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:[self queryHotArticlesWithCategories:categoriesIds rating:minRating sortDescriptor:kHotOrder location:location]];
        if (step) {
            if (lastIndex >= 0) {
                [params setObject:@(lastIndex) forKey:kPathParamSkip];
            }
            [params setObject:@(step) forKey:kPathParamLimit];
        }
        
        NSMutableURLRequest *request = [self requestForType:PRRequestTypeArticleWithQuery];
        NSData *body = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
        [request setHTTPBody:body];
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }

}

- (void)requestNewArticlesWithCategoriesIds:(NSArray *)categoriesIds
                                lastDate:(NSDate *)date
                                    form:(int)lastIndex
                                    step:(int)step
                               locations:(CLLocationCoordinate2D)location
                                 success:(PRNetworkSuccessBlock)success
                                 failure:(PRNetworkFailureBlock)failure
{
    [self requestArticlesWithCategories:categoriesIds lastDate:date from:lastIndex step:step location:location sortDescriptor:kNewOrder success:success failure:failure];
}

- (void)requestTopArticlesWithCategoriesIds:(NSArray *)categoriesIds
                              beforeDate:(NSDate *)date
                               locations:(CLLocationCoordinate2D)location
                                 success:(PRNetworkSuccessBlock)success
                                 failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        NSMutableURLRequest *request = [self requestForType:PRRequestTypeArticleWithQuery];
        NSData *body = [NSJSONSerialization dataWithJSONObject:[self queryTopArticlesWithCategories:categoriesIds beforeDate:date sortDescriptor:kTopOrder location:location] options:NSJSONWritingPrettyPrinted error:nil];
        [request setHTTPBody:body];
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
}

- (void)requestAllMyArticlesWithSuccess:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        [self performRequest:[self requestForType:PRRequestTypeArticlesForUser] completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
}

- (void)requestFavoriteArticlesWithSuccess:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        NSMutableURLRequest *request = [self requestForType:PRRequestTypeFavoriteAction];
        [request setHTTPMethod:kHTTPMethodPOST];
        NSData *body = [NSJSONSerialization dataWithJSONObject:[self queryFetchFavorites] options:NSJSONWritingPrettyPrinted error:nil];
        [request setHTTPBody:body];
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
}

- (void)requestAddArticleToFavorite:(NSString *)articleId success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        [self performRequest:[self favoriteActionRequestWith:[self queryAddToFavorite] articleId:articleId] completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
}

- (void)requestRemoveArticleFromFavorite:(NSString *)articleId success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        [self performRequest:[self favoriteActionRequestWith:[self queryremoveFormFavorite] articleId:articleId] completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
}

- (void)requestLikeArticle:(NSString *)articleId success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        NSMutableURLRequest *request = [self requestForType:PRRequestTypeBatch];
        NSData *body = [NSJSONSerialization dataWithJSONObject:[self queryLikeArticle:articleId] options:NSJSONWritingPrettyPrinted error:nil];
        [request setHTTPBody:body];
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
}

- (void)requestDislikeArticle:(NSString *)articleId success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        NSMutableURLRequest *request = [self requestForType:PRRequestTypeBatch];
        NSData *body = [NSJSONSerialization dataWithJSONObject:[self queryDislikeArticle:articleId] options:NSJSONWritingPrettyPrinted error:nil];
        [request setHTTPBody:body];
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
}

#pragma mark - Internal

- (void)requestArticlesWithCategories:(NSArray *)categories
                             lastDate:(NSDate *)date
                                 from:(int)lastIndex
                                 step:(int)step
                             location:(CLLocationCoordinate2D)location
                       sortDescriptor:(NSString *)sortDescriptor
                              success:(PRNetworkSuccessBlock)success
                              failure:(PRNetworkFailureBlock)failure
{
    if ([self isNetworkAvailable:failure]) {
        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:[self queryNewArticlesWithCategories:categories date:date sortDescriptor:sortDescriptor location:location]];
        [params setObject:kArticleIncludeFields forKey:kPathParamIncludeKey];
        if (step) {
            if (lastIndex >= 0) {
                [params setObject:@(lastIndex) forKey:kPathParamSkip];
            }
            [params setObject:@(step) forKey:kPathParamLimit];
        }
        
        NSMutableURLRequest *request = [self requestForType:PRRequestTypeArticleWithQuery];
        NSData *body = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
        [request setHTTPBody:body];
        [self performRequest:request completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error && failure) {
                failure(error);
            } else {
                if (success) success(data, response);
            }
        }];
    }
    
}

- (NSMutableURLRequest *)favoriteActionRequestWith:(NSDictionary *)body articleId:(NSString *)articleId
{
    NSMutableURLRequest *request = [self requestForType:PRRequestTypeFavoriteAction];
    request.URL = [request.URL URLByAppendingPathComponent:articleId];
    NSData *data = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPBody:data];
    return request;
}

- (void)performRequest:(NSURLRequest *)request completion:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completion
{
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error) {
            completion(data, response, error);
        } else if (data) {
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            PRRemoteError *remoteError = [[PRRemoteError alloc] initWithJSON:json];
            if (remoteError.errorCode) {
                NSError *newError = [NSError errorWithDomain:@"com.parse" code:remoteError.errorCode userInfo:@ {NSLocalizedDescriptionKey : remoteError.errorDescription }];
                completion(data, response, newError);
            } else {
                completion(data, response, error);
            }
        }
    }] resume];
}

- (NSMutableURLRequest *)requestForType:(PRRequestType)requestType
{
    return [self requestForType:requestType params:nil];
}

- (NSMutableURLRequest *)requestForType:(PRRequestType)requestType params:(NSDictionary *)params
{
    NSMutableURLRequest *request = [self baseRequest];
    switch (requestType) {
        case PRRequestTypeAllCategories:
            request.URL = [_baseURL URLByAppendingPathComponent:@"classes/Tag"];
            [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
            [request setHTTPMethod:kHTTPMethodGET];
            return request;
        case PRRequestTypeCategoriesForUser: {
            NSData *body = [NSJSONSerialization dataWithJSONObject:[self queryUserCategories] options:NSJSONWritingPrettyPrinted error:nil];
            request.URL = [_baseURL URLByAppendingPathComponent:@"classes/Tag"];
            [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
            [request setValue:kHeaderContentTypeKey forHTTPHeaderField:kContentTypeApplicationJSON];
            [request setHTTPMethod:kHTTPMethodPOST];
            [request setHTTPBody:body];
            return request;
        }
        case PRRequestTypeLogin:
            request.URL = [self appendParams:params forURL:[_baseURL URLByAppendingPathComponent:@"login"]];
            [request setHTTPMethod:kHTTPMethodGET];
            return request;
        case PRRequestTypeLogout:
            request.URL = [_baseURL URLByAppendingPathComponent:@"logout"];
            [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
            [request setHTTPMethod:kHTTPMethodPOST];
            return request;
        case PRRequestTypeRegistration:
            request.URL = [_baseURL URLByAppendingPathComponent:@"users"];
            [request setValue:kHeaderContentTypeKey forHTTPHeaderField:kContentTypeApplicationJSON];
            [request setHTTPMethod:kHTTPMethodPOST];
            return request;
        case PRRequestTypeResetPassword:
            request.URL = [_baseURL URLByAppendingPathComponent:@"requestPasswordReset"];
            [request setValue:kHeaderContentTypeKey forHTTPHeaderField:kContentTypeApplicationJSON];
            [request setHTTPMethod:kHTTPMethodPOST];
            return request;
        case PRRequestTypeSessionValidation:
            request.URL = [_baseURL URLByAppendingPathComponent:@"users/me"];
            [request setHTTPMethod:kHTTPMethodGET];
            return request;
        case PRRequestTypeCategoryRelation:
            request.URL = [_baseURL URLByAppendingPathComponent:@"classes/Tag"];
            [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
            [request setValue:kHeaderContentTypeKey forHTTPHeaderField:kContentTypeApplicationJSON];
            [request setHTTPMethod:kHTTPMethodPUT];
            return request;
        case PRRequestTypeBatch:
            request.URL = [_baseURL URLByAppendingPathComponent:@"batch"];
            [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
            [request setValue:kHeaderContentTypeKey forHTTPHeaderField:kContentTypeApplicationJSON];
            [request setHTTPMethod:kHTTPMethodPOST];
            return request;
        case PRREquestTypeUserGeoPoints:
            request.URL = [_baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"users/%@", _currentUser]];
            [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
            [request setValue:kHeaderContentTypeKey forHTTPHeaderField:kContentTypeApplicationJSON];
            [request setHTTPMethod:kHTTPMethodPUT];
            return request;
        case PRRequestTypeUpload:
            request.URL = [_baseURL URLByAppendingPathComponent:@"files"];
            [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
            [request setValue:kHeaderContentTypeKey forHTTPHeaderField:kContentTypeImagePng];
            [request setHTTPMethod:kHTTPMethodPOST];
            return request;
        case PRRequestTypeNewMedia:
            request.URL = [_baseURL URLByAppendingPathComponent:@"classes/Media"];
            [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
            [request setValue:kHeaderContentTypeKey forHTTPHeaderField:kContentTypeApplicationJSON];
            [request setHTTPMethod:kHTTPMethodPOST];
            return request;
        case PRRequestTypePublishArticle:
            request.URL = [_baseURL URLByAppendingPathComponent:@"classes/Article"];
            [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
            [request setValue:kHeaderContentTypeKey forHTTPHeaderField:kContentTypeApplicationJSON];
            [request setHTTPMethod:kHTTPMethodPOST];
            return request;
        case PRRequestTypeArticle:
            request.URL = [self appendParams:params forURL:[_baseURL URLByAppendingPathComponent:@"classes/Article"]];
            [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
            [request setHTTPMethod:kHTTPMethodGET];
            return request;
        case PRRequestTypeLoadData:
            [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
            [request setHTTPMethod:kHTTPMethodGET];
            return request;
        case PRRequestTypeLoadMedia:
        {
            request.URL = [_baseURL URLByAppendingPathComponent:@"classes/Media"];
            [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
            [request setValue:kHeaderContentTypeKey forHTTPHeaderField:kContentTypeApplicationJSON];
            [request setHTTPMethod:kHTTPMethodPOST];
            return request;
        }
        case PRRequestTypeArticlesForUser:
        {
            request.URL = [_baseURL URLByAppendingPathComponent:@"classes/Article"];
            [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
            [request setHTTPMethod:kHTTPMethodPOST];
            [request setValue:kHeaderContentTypeKey forHTTPHeaderField:kContentTypeApplicationJSON];
            NSData *body = [NSJSONSerialization dataWithJSONObject:[self queryArticlesForUser] options:NSJSONWritingPrettyPrinted error:nil];
            [request setHTTPBody:body];
            return request;
        }
        case PRRequestTypeFavoriteAction:
        {
            request.URL = [_baseURL URLByAppendingPathComponent:@"classes/Article"];
            [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
            [request setHTTPMethod:kHTTPMethodPUT];
            [request setValue:kHeaderContentTypeKey forHTTPHeaderField:kContentTypeApplicationJSON];
            return request;
        }
        case PRRequestTypeArticleWithQuery:
            request.URL = [_baseURL URLByAppendingPathComponent:@"classes/Article"];
            [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
            [request setHTTPMethod:kHTTPMethodPUT];
            [request setValue:kHeaderContentTypeKey forHTTPHeaderField:kContentTypeApplicationJSON];
            return request;
        default:
            return nil;
    }
}

- (NSMutableURLRequest *)baseRequest
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    [request setValue:kParseApplicationId forHTTPHeaderField:kHeaderParseApplicationIdKey];
    [request setValue:kParseRestApiKey forHTTPHeaderField:kHeaderParseRestApiKey];
    
    return request;
}

- (BOOL)isNetworkAvailable:(PRNetworkFailureBlock)requesrFailureBlock
{
    if (![self.reachability isNetworkAvailable] && requesrFailureBlock) {
        NSError *error = [NSError errorWithDomain:@"com.pulsar.network" code:999 userInfo:@{NSLocalizedDescriptionKey : @"Cheack internet connection."}];
        requesrFailureBlock(error);
        return NO;
    }
    return YES;
}

- (NSURL *)appendParams:(NSDictionary *)params forURL:(NSURL *)url
{
    NSMutableString *source = [[NSMutableString alloc] init];
    if (params.count) {
        [source appendString:@"?"];
        for (NSString *key in params.allKeys) {
            NSString *tmp = [NSString stringWithFormat:@"%@=%@&", key, [params objectForKey:key]];
            [source appendString:tmp];
        }
        [source deleteCharactersInRange:NSMakeRange(source.length - 1, 1)];
    } else {
        return url;
    }
    
    NSString *urlString = [url.absoluteString stringByAppendingString:source];
    return [NSURL URLWithString:urlString];
}

- (PRRemotePointer *)pointerToCurrentUser
{
    return [[PRRemotePointer alloc] initWithClass:@"_User" remoteObjectId:_currentUser];
}

#pragma mark - Queries

- (NSDictionary *)queryTopArticlesWithCategories:(NSArray *)filterCategories beforeDate:(NSDate *)date sortDescriptor:(NSString *)sort location:(CLLocationCoordinate2D)location
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:kParseDateFormat];
    return @{@"_method" : @"GET", kPathParamIncludeKey : kArticleIncludeFields, kPathParamOrder : sort, @"where" : @{@"tag" : [self conditionsForCategories:filterCategories], @"createdAt" : @{@"$gte" : [formatter stringFromDate:date], @"$lte" : [formatter stringFromDate:[NSDate date]]}, @"location" : [self conditionForLocation:location]}};
}

- (NSDictionary *)queryHotArticlesWithCategories:(NSArray *)filterCategories rating:(NSInteger)rating sortDescriptor:(NSString *)sort location:(CLLocationCoordinate2D)location
{
    return @{@"_method" : @"GET", kPathParamIncludeKey : kArticleIncludeFields, kPathParamOrder : sort, @"where" : @{@"tag" : [self conditionsForCategories:filterCategories], @"rating" : @{@"$lte" : @(rating)}, @"location" : [self conditionForLocation:location]}};
}

- (NSDictionary *)queryNewArticlesWithCategories:(NSArray *)filterCategories date:(NSDate *)date sortDescriptor:(NSString *)sort location:(CLLocationCoordinate2D)location
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:kParseDateFormat];
    return @{@"_method" : @"GET", kPathParamIncludeKey : kArticleIncludeFields, kPathParamOrder : sort, @"where" : @{@"tag" : [self conditionsForCategories:filterCategories], @"createdAt" : @{@"$lte" : [formatter stringFromDate:date]}, @"location" : [self conditionForLocation:location]}};
}

- (NSDictionary *)conditionsForCategories:(NSArray *)filterCategories
{
    return @{@"$in" : [self categoriesToPointers:filterCategories]};
}

- (NSDictionary *)conditionForLocation:(CLLocationCoordinate2D)location
{
    return @{@"$nearSphere" : @{ @"__type" : @"GeoPoint", @"latitude" : @(location.latitude), @"longitude":@(location.longitude)},@"$maxDistanceInKilometers": @(100.0)};
}

- (NSArray *)categoriesToPointers:(NSArray *)categories
{
    NSMutableArray *categoryPointers = [NSMutableArray new];
    for (NSString *catId in categories) {
        [categoryPointers addObject:[[[PRRemotePointer alloc] initWithClass:@"Tag" remoteObjectId:catId] toJSONCompatable]];
    }
    return categoryPointers;
}

- (NSDictionary *)queryFetchFavorites
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:[[PRRemoteQuery sharedInstance] fetchFavoritesForUser:[self pointerToCurrentUser]]];
    [result setObject:kArticleIncludeFields forKey:kPathParamIncludeKey];
    return result;
}

- (NSDictionary *)queryAddToFavorite
{
    return [[PRRemoteQuery sharedInstance] addRelationField:@"favorite" objects:@[[self pointerToCurrentUser]]];
}

- (NSDictionary *)queryremoveFormFavorite
{
    return [[PRRemoteQuery sharedInstance] removeRelationField:@"favorite" objects:@[[self pointerToCurrentUser]]];
}

- (NSDictionary *)queryArticlesForUser
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:[[PRRemoteQuery sharedInstance] articlesForUser:[self pointerToCurrentUser]]];
    [result setObject:kArticleIncludeFields forKey:kPathParamIncludeKey];
    return result;
}

- (NSDictionary *)queryUserCategories
{
    return [[PRRemoteQuery sharedInstance] categoriesQueryForUser:[self pointerToCurrentUser]];
}

- (NSDictionary *)queryAddUserCaregory
{
    return [[PRRemoteQuery sharedInstance] addRelationField:@"users" objects:@[[self pointerToCurrentUser]]];
}

- (NSDictionary *)queryRemoveUserCaregory
{
    return [[PRRemoteQuery sharedInstance] removeRelationField:@"users" objects:@[[self pointerToCurrentUser]]];
}

- (NSDictionary *)batchQueryForAddCategories:(NSArray *)addCategories removeCategories:(NSArray *)removeCategories
{
    NSMutableArray *batchObjects = [NSMutableArray new];
    
    for (NSString *identifier in addCategories) {
        NSString *targetObject = [NSString stringWithFormat:@"Tag/%@", identifier];
        PRRemoteBatchRequestObject *object = [[PRRemoteBatchRequestObject alloc] initWithMethod:kHTTPMethodPUT targetClass:targetObject body:[self queryAddUserCaregory]];
        [batchObjects addObject:object];
    }
    
    for (NSString *identifier in removeCategories) {
        NSString *targetObject = [NSString stringWithFormat:@"Tag/%@", identifier];
        PRRemoteBatchRequestObject *object = [[PRRemoteBatchRequestObject alloc] initWithMethod:kHTTPMethodPUT targetClass:targetObject body:[self queryRemoveUserCaregory]];
        [batchObjects addObject:object];
    }
    
    return [[PRRemoteQuery sharedInstance] batchQueryWithObjects:batchObjects];
}

- (NSDictionary *)queryLikeArticle:(NSString *)articleId
{
    NSMutableArray *batchObjects = [NSMutableArray new];
    NSString *targetObject = [NSString stringWithFormat:@"Article/%@", articleId];
    
    PRRemoteArray *remove = [[PRRemoteArray alloc] initWithField:@"dislikes" action:PRRemoteArrayActionRemove objects:@[self.currentUser]];
    PRRemoteArray *add = [[PRRemoteArray alloc] initWithField:@"likes" action:PRRemoteArrayActionAddUnique objects:@[self.currentUser]];
    
    [batchObjects addObject:[[PRRemoteBatchRequestObject alloc] initWithMethod:kHTTPMethodPUT targetClass:targetObject body:[add toJSONCompatable]]];
    [batchObjects addObject:[[PRRemoteBatchRequestObject alloc] initWithMethod:kHTTPMethodPUT targetClass:targetObject body:[remove toJSONCompatable]]];
    
    NSDictionary *incrementQuery = [[PRRemoteQuery sharedInstance] incrementField:@"rating"];
    [batchObjects addObject:[[PRRemoteBatchRequestObject alloc] initWithMethod:kHTTPMethodPUT targetClass:targetObject body:incrementQuery]];
    
    return [[PRRemoteQuery sharedInstance] batchQueryWithObjects:batchObjects];
}

- (NSDictionary *)queryDislikeArticle:(NSString *)articleId
{
    NSMutableArray *batchObjects = [NSMutableArray new];
    NSString *targetObject = [NSString stringWithFormat:@"Article/%@", articleId];
    
    PRRemoteArray *remove = remove = [[PRRemoteArray alloc] initWithField:@"likes" action:PRRemoteArrayActionRemove objects:@[self.currentUser]];
   
    PRRemoteArray *add = [[PRRemoteArray alloc] initWithField:@"dislikes" action:PRRemoteArrayActionAddUnique objects:@[self.currentUser]];
    [batchObjects addObject:[[PRRemoteBatchRequestObject alloc] initWithMethod:kHTTPMethodPUT targetClass:targetObject body:[add toJSONCompatable]]];
    [batchObjects addObject:[[PRRemoteBatchRequestObject alloc] initWithMethod:kHTTPMethodPUT targetClass:targetObject body:[remove toJSONCompatable]]];
    
    NSDictionary *decrementQuery = [[PRRemoteQuery sharedInstance] decrementField:@"rating"];
    [batchObjects addObject:[[PRRemoteBatchRequestObject alloc] initWithMethod:kHTTPMethodPUT targetClass:targetObject body:decrementQuery]];
    
    return [[PRRemoteQuery sharedInstance] batchQueryWithObjects:batchObjects];
}

- (NSDictionary *)queryMediaForArticle:(NSString *)identifier
{
    PRRemotePointer *pointer = [[PRRemotePointer alloc] initWithClass:@"Article" remoteObjectId:identifier];
    return [[PRRemoteQuery sharedInstance] mediaForArticle:pointer];
}

@end
