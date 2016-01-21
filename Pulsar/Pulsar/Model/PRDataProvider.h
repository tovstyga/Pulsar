//
//  PRDataProvider.h
//  Pulsar
//
//  Created by fantom on 04.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRLocalCategory.h"

@interface PRDataProvider : NSObject

+ (instancetype)sharedInstance;

- (void)registrateUser:(NSString *)userName
              password:(NSString *)password
                 email:(NSString *)email
            completion:(void(^)(NSError *error))completion;

- (void)loginUser:(NSString *)userName password:(NSString *)password completion:(void(^)(NSError *error))completion;

- (void)sendNewPasswordOnEmail:(NSString *)email completion:(void(^)(NSError *error))completion;

- (void)logoutWithCompletion:(void(^)(NSError *error))completion;

- (void)resumeSession:(void(^)(BOOL success))completion;

//categories

- (void)allCategories:(void(^)(NSArray *categories, NSError *error))completion;

- (void)categoriesForCurrentUser:(void(^)(NSArray *categories, NSError *error))completion;

- (void)addCategoryForCurrentUser:(PRLocalCategory *)category completion:(void(^)(NSError *error))completion;

- (void)addCategoriesForCurrentUser:(NSArray *)categories completion:(void(^)(NSError *error))completion;

- (void)removeCategoryForCurrentUser:(PRLocalCategory *)category completion:(void(^)(NSError *error))completion;

- (void)removeCategoriesForCurrentUser:(NSArray *)categories completion:(void(^)(NSError *error))completion;

- (void)userCategoryAdd:(NSArray *)addCategories remove:(NSArray *)removeCategories completion:(void(^)(NSError *error))completion;

@end
