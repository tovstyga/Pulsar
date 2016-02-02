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
    
    NSArray *_locations;
    NSMutableArray *_editableLocations;
    
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

- (void)fetchCategoriesWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion
{
    __weak typeof(self) wSelf = self;
    [_loadingQueue addOperationWithBlock:^{
        dispatch_group_t loadCategoryCroup = dispatch_group_create();
        dispatch_group_enter(loadCategoryCroup);
        [[PRDataProvider sharedInstance] allCategories:^(NSArray *categories, NSError *error) {
            if (!error) {
                __block NSArray *allCategories = categories;
                _categories = categories;
                [[PRDataProvider sharedInstance] categoriesForCurrentUser:^(NSArray *categories, NSError *error) {
                    if (!error) {
                        __strong typeof(wSelf) sSelf = wSelf;
                        if (sSelf) {
                            [sSelf generateDataSourceOfAllCategories:allCategories userCategories:categories];
                            dispatch_group_leave(loadCategoryCroup);
                        }
                        if (completion) {
                            completion(YES, nil);
                        }
                    } else if (completion) {
                        completion(NO, [PRErrorDescriptor descriptionForError:error]);
                        dispatch_group_leave(loadCategoryCroup);
                    }
                }];
            } else if (completion) {
                completion(NO, [PRErrorDescriptor descriptionForError:error]);
                dispatch_group_leave(loadCategoryCroup);
            }
        }];
        dispatch_group_wait(loadCategoryCroup, DISPATCH_TIME_FOREVER);
    }];
}

- (void)fetchGeoPointsWithCompletion:(void (^)(BOOL, NSString *))completion
{
    [_loadingQueue addOperationWithBlock:^{
        dispatch_group_t loadLocationGroup  = dispatch_group_create();
        dispatch_group_enter(loadLocationGroup);
        [[PRDataProvider sharedInstance] allGeopoints:^(NSArray *geopoints, NSError *error) {
            if (!error) {
                _locations = geopoints;
                _editableLocations = [[NSMutableArray alloc] initWithArray:geopoints];
                if (completion) {
                    completion(YES, nil);
                }
                dispatch_group_leave(loadLocationGroup);
            } else {
                if (completion) {
                    completion(NO, [PRErrorDescriptor descriptionForError:error]);
                }
                dispatch_group_leave(loadLocationGroup);
            }
        }];
        dispatch_group_wait(loadLocationGroup, DISPATCH_TIME_FOREVER);
    }];
}

- (void)saveDataWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion
{
    if ([self.delegate respondsToSelector:@selector(willUpdateUserSettings)]) {
        [self.delegate willUpdateUserSettings];
    }
    
    __weak typeof(self) wSelf = self;
    [_loadingQueue addOperationWithBlock:^{

        dispatch_group_t savingGroup = dispatch_group_create();
       
        __block NSMutableArray *locationsForRemove = [[NSMutableArray alloc] initWithArray:_locations];
        [locationsForRemove removeObjectsInArray:_editableLocations];
    
        NSMutableArray *categoriesForRemove = [NSMutableArray new];
        NSMutableArray *categoriesForAdd = [NSMutableArray new];
        
        NSMutableArray *templateCategoriesForDataProvider = [NSMutableArray new];
        
        for (int i = 0; i < [_categories count]; i++) {
            BOOL newCategorySelected = [(PRLocalCategory *)_categories[i] isSelected];
            if (newCategorySelected) {
                [templateCategoriesForDataProvider addObject:_categories[i]];
            }
            if ([_defaultState[i] boolValue] != newCategorySelected) {
                if ([_defaultState[i] boolValue] == YES && newCategorySelected == NO) {
                    [categoriesForRemove addObject:_categories[i]];
                } else {
                    [categoriesForAdd addObject:_categories[i]];
                }
            }
        }
    
        [PRDataProvider sharedInstance].templateSelectedCategories = templateCategoriesForDataProvider;
        
        __block NSError *executionError;
        
        if ([locationsForRemove count]) {
            dispatch_group_enter(savingGroup);
            [[PRDataProvider sharedInstance] removeGeoPoints:locationsForRemove completion:^(NSError *error) {
                executionError = error;
                dispatch_group_leave(savingGroup);
            }];
        }
    
        if ([categoriesForAdd  count] && [categoriesForRemove count]) {
            dispatch_group_enter(savingGroup);
            [[PRDataProvider sharedInstance] userCategoryAdd:categoriesForAdd remove:categoriesForRemove completion:^(NSError *error) {
                executionError = error;
                dispatch_group_leave(savingGroup);
            }];
        } else if ([categoriesForAdd count]) {
            dispatch_group_enter(savingGroup);
            [[PRDataProvider sharedInstance] addCategoriesForCurrentUser:categoriesForAdd completion:^(NSError *error) {
                executionError = error;
                dispatch_group_leave(savingGroup);
            }];
        } else if ([categoriesForRemove count]) {
            dispatch_group_enter(savingGroup);
            [[PRDataProvider sharedInstance] removeCategoriesForCurrentUser:categoriesForRemove completion:^(NSError *error) {
                executionError = error;
                dispatch_group_leave(savingGroup);
            }];
        }
        
        dispatch_group_wait(savingGroup, DISPATCH_TIME_FOREVER);
        
        __strong typeof(wSelf) sSelf = wSelf;
        if (sSelf) {
           
            _categories = [NSArray new];
            _defaultState = [NSArray new];
            _locations = [NSArray new];
            _editableLocations = [NSMutableArray new];
            
            if ([sSelf.delegate respondsToSelector:@selector(didUpdateUserSettings)]) {
                 [sSelf.delegate didUpdateUserSettings];
            }
            
            if (completion) {
                if (executionError) {
                    completion(NO, [PRErrorDescriptor descriptionForError:executionError]);
                } else {
                    completion(YES, nil);
                }
            }
        }
        
    }];
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
    return [_editableLocations count];
}

- (PRLocalGeoPoint *)locationForIndex:(NSInteger)index
{
    if (index > 0 && index <= [_editableLocations count]) {
        return _editableLocations[index - 1];
    }
    return nil;
}

- (void)removeLocationAtIndex:(NSInteger)index
{
    if (index > 0 && index <= [_editableLocations count]) {
        [_editableLocations removeObjectAtIndex:(index - 1)];
    }

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
