//
//  PRNetworkDataProvider.h
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRJsonCompatable.h"

typedef void(^PRNetworkSuccessBlock)(NSData *data, NSURLResponse *response);
typedef void(^PRNetworkFailureBlock)(NSError *error);

@interface PRNetworkDataProvider : NSObject

+ (instancetype)sharedInstance;

- (void)requestRegistration:(id<PRJsonCompatable>)registrationRequest success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestLoginUser:(NSString *)userName password:(NSString *)password success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestLogoutWithSuccess:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestResetPassword:(id<PRJsonCompatable>)resetRequest success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)validateSessionToken:(NSString *)token success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

@end
