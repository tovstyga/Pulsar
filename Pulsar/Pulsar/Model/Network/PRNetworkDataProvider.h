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

@property (strong, nonatomic, readonly) NSString *currentUser;

+ (instancetype)sharedInstance;

- (void)loadDataFromURL:(NSURL *)url success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestRegistration:(id<PRJsonCompatable>)registrationRequest success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestLoginUser:(NSString *)userName password:(NSString *)password success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestLogoutWithSuccess:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestResetPassword:(id<PRJsonCompatable>)resetRequest success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)validateSessionToken:(NSString *)token success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestCategoriesWithSuccess:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestCategoriesForCurrentUserWithSuccess:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestAddCategoriesWithIdsForCurrentUser:(NSArray *)ids success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestRemoveCategoriesWithIdsForCurrentUser:(NSArray *)ids success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestUpdateUserCategoriesForAdd:(NSArray *)addIds
                                   remove:(NSArray *)removeIds
                                  success:(PRNetworkSuccessBlock)success
                                  failure:(PRNetworkFailureBlock)failure;

- (void)requesGeoPointsWithSuccess:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestAddGeopoints:(NSArray *)geopoints success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestRemoveGeopoints:(NSArray *)geopoints success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)uploadData:(NSData *)data fileName:(NSString *)fileName success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestPublishArticle:(id<PRJsonCompatable>)article success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestNewMedia:(id<PRJsonCompatable>)media success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestArticlesWithSuccess:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;

- (void)requestMediaForArticleWithId:(NSString *)articleId success:(PRNetworkSuccessBlock)success failure:(PRNetworkFailureBlock)failure;


@end
