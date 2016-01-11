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

@interface PRNetworkDataProvider()

@property (strong, nonatomic, readonly) PRReachability *reachability;

@end

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

//content types

static NSString * const kContentTypeApplicationJSON = @"application/json";

//ids

static NSString * const kParseApplicationId = @"HbQ3zhjz45cliycC3EoBxKWM4qf9LH7F6dpatiP8";
static NSString * const kParseRestApiKey = @"NePEmzWEYQJ1jfAGOruWhLqyahlNrdLzWspgGMxe";
static NSString * const kParseRevocableSession = @"1";

@implementation PRNetworkDataProvider{
    NSString *_sessionToken;
    NSURL *_baseURL;
}

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
    if (![self isNetworkAvailable:failure]) {
        return;
    }
    
    NSMutableURLRequest *request = [self baseRequest];
    request.URL = [_baseURL URLByAppendingPathComponent:@"users"];
    
    [request setValue:kHeaderContentTypeKey forHTTPHeaderField:kContentTypeApplicationJSON];
    
    [request setHTTPMethod:kHTTPMethodPOST];
    
    NSData *body = [NSJSONSerialization dataWithJSONObject:[registrationRequest toJSONCompatable] options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPBody:body];
    
   [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
       if (error && failure) {
           failure(error);
       } else if (success && data) {
           
           id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
           
           PRRemoteError *remoteError = [[PRRemoteError alloc] initWithJSON:json];
           if (remoteError.errorCode && failure) {
               NSError *newError = [NSError errorWithDomain:@"com.parse" code:remoteError.errorCode userInfo:@ {NSLocalizedDescriptionKey : remoteError.errorDescription }];
               failure(newError);
           } else {
           
               PRRemoteRegistrationResponse *sessionInfo = [[PRRemoteRegistrationResponse alloc] initWithJSON:json];
               _sessionToken = sessionInfo.sessionToken;
           
               success(data, response);
           }
       }
   }] resume];
}

- (void)requestLoginUser:(NSString *)userName
                password:(NSString *)password
                 success:(PRNetworkSuccessBlock)success
                 failure:(PRNetworkFailureBlock)failure
{
    if (![self isNetworkAvailable:failure]) {
        return;
    }
    
    NSMutableURLRequest *request = [self baseRequest];
    NSDictionary *params = @{kPathParamUsernameKay : userName, kPathParamPasswordKey : password};
    request.URL = [self appendParams:params forURL:[_baseURL URLByAppendingPathComponent:@"login"]];
    [request setHTTPMethod:kHTTPMethodGET];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error && failure) {
            failure(error);
        } else if (success && data) {
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            PRRemoteError *remoteError = [[PRRemoteError alloc] initWithJSON:json];
            
            if (remoteError.errorCode && failure) {
                NSError *newError = [NSError errorWithDomain:@"com.parse" code:remoteError.errorCode userInfo:@ {NSLocalizedDescriptionKey : remoteError.errorDescription }];
                failure(newError);
            } else {
                PRRemoteLoginResponse *sessionInfo = [[PRRemoteLoginResponse alloc] initWithJSON:json];
                _sessionToken = sessionInfo.sessionToken;
                
                success(data, response);
            }
        }
    }] resume];
}

- (void)requestLogoutWithSuccess:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if (![self isNetworkAvailable:failure]) {
        return;
    }
    
    if (!_sessionToken && success) {
        success(nil, nil);
        return;
    }
    
    NSMutableURLRequest *request = [self baseRequest];
    request.URL = [_baseURL URLByAppendingPathComponent:@"logout"];
    
    [request setValue:_sessionToken forHTTPHeaderField:kHeaderParseSessionTokenKey];
    
    [request setHTTPMethod:kHTTPMethodPOST];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error && failure) {
            failure(error);
        } else if (success && data) {
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            PRRemoteError *remoteError = [[PRRemoteError alloc] initWithJSON:json];
            
            if (remoteError.errorCode && failure) {
                NSError *newError = [NSError errorWithDomain:@"com.parse" code:remoteError.errorCode userInfo:@ {NSLocalizedDescriptionKey : remoteError.errorDescription }];
                failure(newError);
            } else {
                success(data, response);
            }
        }
        
    }] resume];
    
}

- (void)requestResetPassword:(id<PRJsonCompatable>)resetRequest success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if (![self isNetworkAvailable:failure]) {
        return;
    }
    
    NSMutableURLRequest *request = [self baseRequest];
    request.URL = [_baseURL URLByAppendingPathComponent:@"requestPasswordReset"];
    
    [request setValue:kHeaderContentTypeKey forHTTPHeaderField:kContentTypeApplicationJSON];
    
    [request setHTTPMethod:kHTTPMethodPOST];
    
    NSData *body = [NSJSONSerialization dataWithJSONObject:[resetRequest toJSONCompatable] options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPBody:body];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error && failure) {
            failure(error);
        } else if (success && data) {
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            PRRemoteError *remoteError = [[PRRemoteError alloc] initWithJSON:json];
            
            if (remoteError.errorCode && failure) {
                NSError *newError = [NSError errorWithDomain:@"com.parse" code:remoteError.errorCode userInfo:@ {NSLocalizedDescriptionKey : remoteError.errorDescription }];
                failure(newError);
            } else {
                success(data, response);
            }
        }
        
    }] resume];
    
}

- (void)validateSessionToken:(NSString *)token success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure
{
    if (![self isNetworkAvailable:failure]) {
        return;
    }
    
    NSMutableURLRequest *request = [self baseRequest];
    request.URL = [_baseURL URLByAppendingPathComponent:@"users/me"];
    [request setValue:token forHTTPHeaderField:kHeaderParseSessionTokenKey];
    [request setHTTPMethod:kHTTPMethodGET];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error && failure) {
            failure(error);
        } else if (success && data) {
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            PRRemoteError *remoteError = [[PRRemoteError alloc] initWithJSON:json];
            
            if (remoteError.errorCode && failure) {
                NSError *newError = [NSError errorWithDomain:@"com.parse" code:remoteError.errorCode userInfo:@ {NSLocalizedDescriptionKey : remoteError.errorDescription }];
                failure(newError);
            } else {
                PRTokenValidationResponse *validationResponse = [[PRTokenValidationResponse alloc] initWithJSON:json];
                _sessionToken = validationResponse.sessionToken;
                success(data, response);
            }
        }
        
    }] resume];
}

#pragma mark - Internal

- (NSMutableURLRequest *)baseRequest
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    [request setValue:kParseApplicationId forHTTPHeaderField:kHeaderParseApplicationIdKey];
    [request setValue:kParseRestApiKey forHTTPHeaderField:kHeaderParseRestApiKey];
//    [request setValue:kParseRevocableSession forHTTPHeaderField:kHeaderParseRevocableSessionKey];
    
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
    NSMutableString *source = [NSMutableString stringWithString:[url absoluteString]];
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
    return [NSURL URLWithString:source];
}

@end
