//
//  PRMenuViewInteractorProtocol.h
//  Pulsar
//
//  Created by fantom on 20.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "InterestCategory.h"
#import "PRLocalGeoPoint.h"

@protocol PRMenuViewInteractorProtocol <NSObject>

- (void)fetchCategoriesWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion;

- (void)fetchGeoPointsWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion;

- (void)saveDataWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion;

- (NSUInteger)availableCategories;

- (InterestCategory *)categoryForIndex:(NSInteger)index;

- (NSUInteger)availableLocations;

- (PRLocalGeoPoint *)locationForIndex:(NSInteger)index;

- (void)removeLocationAtIndex:(NSInteger)index;

@end