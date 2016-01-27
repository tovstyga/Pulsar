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
#import "PRLocalNewArticle.h"
#import "PRLocalGeoPoint.h"
#import "PRLocationManager.h"

@implementation PRCreationViewInteractor {
    NSArray *_categories;
}

- (void)publishNewArticleWithTitle:(NSString *)title
                        annotation:(NSString *)annotation
                              text:(NSString *)text
                          gategory:(NSString *)category
                             image:(UIImage *)image
                            images:(NSArray<UIImage *> *)images
                        completion:(void (^)(BOOL, NSString *))completion
{
    __block PRLocalNewArticle *article = [[PRLocalNewArticle alloc] init];
    article.title = title;
    article.annotation = annotation;
    article.text = text;
    [_categories enumerateObjectsUsingBlock:^(PRLocalCategory *_category, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([_category.title isEqualToString:category]) {
            article.category = _categories[idx];
            *stop = YES;
        }
    }];
    article.image = image;
    article.images = images;
    PRLocalGeoPoint *currentLocation = [[PRLocalGeoPoint alloc] initWithLatitude:[PRLocationManager sharedInstance].currentLocation.coordinate.latitude longitude:[PRLocationManager sharedInstance].currentLocation.coordinate.longitude title:nil];
    article.location = currentLocation;
    [[PRDataProvider sharedInstance] publishNewArticle:article completion:^(NSError *error) {
        if (error) {
            if (completion) {
                completion(NO, [PRErrorDescriptor descriptionForError:error]);
            }
        } else {
            if (completion) {
                completion(YES, nil);
            }
        }
    }];
    
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
