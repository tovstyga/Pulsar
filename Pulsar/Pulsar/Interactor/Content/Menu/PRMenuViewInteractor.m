//
//  PRMenuViewInteractor.m
//  Pulsar
//
//  Created by fantom on 20.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRMenuViewInteractor.h"
#import "PRDataProvider.h"
#import "PRErrorDescriptor.h"
#import "PRLocalCategory.h"

@implementation PRMenuViewInteractor{
    NSArray *_categories;
    NSArray *_defaultState;
    
    NSOperationQueue *_loadingQueue;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _loadingQueue = [[NSOperationQueue alloc] init];
        _loadingQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)fetchDataWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion
{
#warning synchrinization!!!
    __weak typeof(self) wSelf = self;
    
    if (_loadingQueue.operationCount) {
        [_loadingQueue cancelAllOperations];
        _categories = [NSArray new];
        _defaultState = [NSArray new];
    }
    
    [_loadingQueue addOperationWithBlock:^{
        [[PRDataProvider sharedInstance] allCategories:^(NSArray *categories, NSError *error) {
            if (!error) {
                __block NSArray *allCategories = categories;
                _categories = categories;
                [[PRDataProvider sharedInstance] categoriesForCurrentUser:^(NSArray *categories, NSError *error) {
                    if (!error) {
                        __strong typeof(wSelf) sSelf = wSelf;
                        if (sSelf) {
                            [sSelf generateDataSourceOfAllCategories:allCategories userCategories:categories];
                        }
                        if (completion) {
                            completion(YES, nil);
                        }
                    } else if (completion) {
                        completion(NO, [PRErrorDescriptor descriptionForError:error]);
                    }
                }];
            } else if (completion) {
                completion(NO, [PRErrorDescriptor descriptionForError:error]);
            }
        }];
    }];
}

- (void)saveDataWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion
{
    if ([self.delegate respondsToSelector:@selector(willUpdateUserSettings)]) {
        [self.delegate willUpdateUserSettings];
    }
    
    NSMutableArray *categoriesForRemove = [NSMutableArray new];
    NSMutableArray *categoriesForAdd = [NSMutableArray new];
    for (int i = 0; i < [_categories count]; i++) {
        BOOL newCategorySelected = [(PRLocalCategory *)_categories[i] isSelected];
        if ([_defaultState[i] boolValue] != newCategorySelected) {
            if ([_defaultState[i] boolValue] == YES && newCategorySelected == NO) {
                [categoriesForRemove addObject:_categories[i]];
            } else {
                [categoriesForAdd addObject:_categories[i]];
            }
        }
    }
    
    __weak typeof(self) wSelf = self;
    void(^finishedBlock)() = ^(NSError *error){
        __strong typeof(wSelf) sSelf = wSelf;
        if (sSelf) {
            if ([sSelf.delegate respondsToSelector:@selector(didUpdateUserSettings)]) {
                [sSelf.delegate didUpdateUserSettings];
            }
        }
        if (completion) {
            if (error) {
                completion(NO, [PRErrorDescriptor descriptionForError:error]);
            } else {
                completion(YES, nil);
            }
        }
    };
    
//    if (([categoriesForAdd count] || [categoriesForRemove count]) && [self.delegate respondsToSelector:@selector(willUpdateUserSettings)]) {
//        [self.delegate willUpdateUserSettings];
//    }
    
    if ([categoriesForAdd  count] && [categoriesForRemove count]) {
        [[PRDataProvider sharedInstance] userCategoryAdd:categoriesForAdd remove:categoriesForRemove completion:^(NSError *error) {
            finishedBlock(error);
        }];
    } else if ([categoriesForAdd count]) {
        [[PRDataProvider sharedInstance] addCategoriesForCurrentUser:categoriesForAdd completion:^(NSError *error) {
            finishedBlock(error);
        }];
    } else if ([categoriesForRemove count]) {
        [[PRDataProvider sharedInstance] removeCategoriesForCurrentUser:categoriesForRemove completion:^(NSError *error) {
            finishedBlock(error);
        }];
    }
    
    if (![categoriesForAdd count] && ![categoriesForRemove count] && [self.delegate respondsToSelector:@selector(didUpdateUserSettings)]) {
        [self.delegate didUpdateUserSettings];
    }
    
}

- (NSUInteger)availableCategories
{
    return [_categories count];
}

- (PRLocalCategory *)categoryForIndex:(NSInteger)index
{
    if (index >= 0 && index < [_categories count]) {
        return _categories[index];
    }
    return nil;
}

- (NSUInteger)availableLocations
{
    return 0;
}

- (id)locationForIndex:(NSInteger)index
{
    return nil;
}


#pragma mark - Internal

- (void)generateDataSourceOfAllCategories:(NSArray *)allCategories userCategories:(NSArray *)userCategories
{
    _categories = [allCategories copy];
    NSMutableArray *states = [NSMutableArray new];
    for (PRLocalCategory *userCategory in userCategories) {
        [_categories enumerateObjectsUsingBlock:^(PRLocalCategory *categoty, NSUInteger idx, BOOL *stop) {
            if ([userCategory.identifier isEqualToString:categoty.identifier]) {
                categoty.selected = YES;
                *stop = YES;
            }
        }];
    }
    
    [_categories enumerateObjectsUsingBlock:^(PRLocalCategory *categoty, NSUInteger idx, BOOL *stop) {
        [states addObject:@(categoty.selected)];
    }];
    _defaultState = states;
}

@end
