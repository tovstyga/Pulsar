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

@interface PRNetworkDataProvider()

@property (strong, nonatomic, readonly) PRReachability *reachability;

@end

@implementation PRNetworkDataProvider{
    NSString *_sessionToken;
    NSString *_currentUser;
    NSURL *_baseURL;
}

typedef NS_ENUM(NSUInteger, PRRequestType) {
    PRRequestTypeLogin,
    PRRequestTypeLogout,
    PRRequestTypeRegistration,
    PRRequestTypeResetPassword,
    PRRequestTypeSessionValidation,
    PRRequestTypeAllCategories,
    PRRequestTypeCategoriesForUser,
    PRRequestTypeCategoryRelation,
    PRRequestTypeBatch
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

//content types

static NSString * const kContentTypeApplicationJSON = @"application/json";

//ids

static NSString * const kParseApplicationId = @"HbQ3zhjz45cliycC3EoBxKWM4qf9LH7F6dpatiP8";
static NSString * const kParseRestApiKey = @"NePEmzWEYQJ1jfAGOruWhLqyahlNrdLzWspgGMxe";
static NSString * const kParseRevocableSession = @"1";

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

#pragma mark - Public

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

#pragma mark - Internal

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

@end
