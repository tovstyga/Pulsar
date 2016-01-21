//
//  PRMenuViewInteractorProtocol.h
//  Pulsar
//
//  Created by fantom on 20.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRLocalCategory.h"

@protocol PRMenuViewInteractorProtocol <NSObject>

- (void)fetchDataWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion;

- (void)saveDataWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion;

- (NSUInteger)availableCategories;

- (PRLocalCategory *)categoryForIndex:(NSInteger)index;

- (NSUInteger)availableLocations;

- (id)locationForIndex:(NSInteger)index;

@end