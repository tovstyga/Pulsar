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

@interface PRDataProvider()

@property (strong, nonatomic) NSString *networkSessionKey;

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

#pragma mark - Internal

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
