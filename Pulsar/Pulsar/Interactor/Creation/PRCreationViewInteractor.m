//
//  PRCreationViewInteractor.m
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRCreationViewInteractor.h"
#import "PRErrorDescriptor.h"
#import "PRDataProvider.h"
#import "PRLocalCategory.h"

@implementation PRCreationViewInteractor {
    NSArray *_categories;
}

- (void)loadCategoriesWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion
{
    [[PRDataProvider sharedInstance] allCategories:^(NSArray *categories, NSError *error) {
        if (error) {
            if (completion) {
                completion(NO, [PRErrorDescriptor descriptionForError:error]);
            }
        } else {
            _categories = categories;
            if (completion) {
                completion(YES, nil);
            }
        }
    }];
}

- (NSArray<NSString *> *)allAvailableCategoriesNames
{
    NSMutableArray *descriptions = [NSMutableArray new];
    [_categories enumerateObjectsUsingBlock:^(PRLocalCategory *category, NSUInteger idx, BOOL *stop) {
        [descriptions addObject:category.title];
    }];
    return descriptions;
}

@end
