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

#import "InterestCategory.h"

@implementation PRMenuViewInteractor{
    NSArray *_categories;
    NSArray *_defaultState;
    
    NSArray *_locations;
    NSMutableArray *_editableLocations;
    
    NSOperationQueue *_loadingQueue;
    BOOL _rollbackChanges;
}

@synthesize delegate;

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
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf) {
            return;
        }
        dispatch_group_t loadCategoryCroup = dispatch_group_create();
        dispatch_group_enter(loadCategoryCroup);
        [sSelf.dataProvider allCategories:^(NSArray *categories, NSError *error) {
            __strong typeof(wSelf) sSelf = wSelf;
            if (categories && sSelf) {
                __block NSArray *allCategories = categories;
                _categories = categories;
                [sSelf.dataProvider categoriesForCurrentUser:^(NSArray *categories, NSError *error) {
                    if (categories) {
                        __strong typeof(wSelf) sSelf = wSelf;
                        if (sSelf) {
                            [sSelf generateDataSourceOfAllCategories:allCategories userCategories:categories];
                        }
                        if (completion) {
                            if (error) {
                                completion(YES, [sSelf.errorDescriptor descriptionForError:error]);
                            } else {
                                completion(YES, nil);
                            }
                        }
                        dispatch_group_leave(loadCategoryCroup);
                    } else {
                        if (completion) {
                            completion(NO, [wSelf.errorDescriptor descriptionForError:error]);
                        }
                        dispatch_group_leave(loadCategoryCroup);
                    }
                }];
            } else {
                if (completion) {
                    completion(NO, [wSelf.errorDescriptor descriptionForError:error]);
                }
                dispatch_group_leave(loadCategoryCroup);
            }
        }];
        dispatch_group_wait(loadCategoryCroup, DISPATCH_TIME_FOREVER);
    }];
}

- (void)fetchGeoPointsWithCompletion:(void (^)(BOOL, NSString *))completion
{
    __weak typeof(self) wSelf = self;
    [_loadingQueue addOperationWithBlock:^{
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf) {
            return;
        }
        dispatch_group_t loadLocationGroup  = dispatch_group_create();
        dispatch_group_enter(loadLocationGroup);
        [sSelf.dataProvider allGeopoints:^(NSArray *geopoints, NSError *error) {
            if (!error) {
                _locations = geopoints;
                _editableLocations = [[NSMutableArray alloc] initWithArray:geopoints];
                if (completion) {
                    completion(YES, nil);
                }
                dispatch_group_leave(loadLocationGroup);
            } else {
                if (geopoints) {
                    _locations = geopoints;
                    _editableLocations = [[NSMutableArray alloc] initWithArray:geopoints];
                }
                if (completion) {
                    completion(geopoints ? YES : NO, [wSelf.errorDescriptor descriptionForError:error]);
                }
                dispatch_group_leave(loadLocationGroup);
            }
        }];
        dispatch_group_wait(loadLocationGroup, DISPATCH_TIME_FOREVER);
    }];
}

- (void)saveDataWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion
{
    if (_rollbackChanges) {
        _categories = [NSArray new];
        _defaultState = [NSArray new];
        _locations = [NSArray new];
        _editableLocations = [NSMutableArray new];
        _rollbackChanges = NO;
    }
    
    if ([self.delegate respondsToSelector:@selector(willUpdateUserSettings)]) {
        [self.delegate willUpdateUserSettings];
    }
    
    __weak typeof(self) wSelf = self;
    PRDataProvider *dataProvider = self.dataProvider;
    [_loadingQueue addOperationWithBlock:^{

        dispatch_group_t savingGroup = dispatch_group_create();
       
        __block NSMutableArray *locationsForRemove = [[NSMutableArray alloc] initWithArray:_locations];
        [locationsForRemove removeObjectsInArray:_editableLocations];
    
        NSMutableArray *categoriesForRemove = [NSMutableArray new];
        NSMutableArray *categoriesForAdd = [NSMutableArray new];
        
        NSMutableArray *templateCategoriesForDataProvider = [NSMutableArray new];
        
        for (int i = 0; i < [_categories count]; i++) {
            BOOL newCategorySelected = [[(InterestCategory *)_categories[i] selected] boolValue];
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
        
        __block NSError *executionError;
        
        if ([locationsForRemove count]) {
            dispatch_group_enter(savingGroup);
            [dataProvider removeGeoPoints:locationsForRemove completion:^(NSError *error) {
                executionError = error;
                dispatch_group_leave(savingGroup);
            }];
        }
    
        if ([categoriesForAdd  count] && [categoriesForRemove count]) {
            dispatch_group_enter(savingGroup);
            [dataProvider userCategoryAdd:categoriesForAdd remove:categoriesForRemove completion:^(NSError *error) {
                executionError = error;
                dispatch_group_leave(savingGroup);
            }];
        } else if ([categoriesForAdd count]) {
            dispatch_group_enter(savingGroup);
            [dataProvider addCategoriesForCurrentUser:categoriesForAdd completion:^(NSError *error) {
                executionError = error;
                dispatch_group_leave(savingGroup);
            }];
        } else if ([categoriesForRemove count]) {
            dispatch_group_enter(savingGroup);
            [dataProvider removeCategoriesForCurrentUser:categoriesForRemove completion:^(NSError *error) {
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
                    completion(NO, [sSelf.errorDescriptor descriptionForError:executionError]);
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

- (InterestCategory *)categoryForIndex:(NSInteger)index
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
    if (index >= 0 && index < [_editableLocations count]) {
        return _editableLocations[index];
    }
    return nil;
}

- (void)removeLocationAtIndex:(NSInteger)index
{
    if (index > 0 && index <= [_editableLocations count]) {
        [_editableLocations removeObjectAtIndex:(index - 2)];
    }

}

- (void)logout
{
    _rollbackChanges = YES;
    [self.delegate logoutAction];
}

#pragma mark - Internal

- (void)generateDataSourceOfAllCategories:(NSArray *)allCategories userCategories:(NSArray *)userCategories
{
    _categories = [allCategories copy];
    [_categories enumerateObjectsUsingBlock:^(InterestCategory *category, NSUInteger idx, BOOL *stop) {
        category.selected = @(NO);
    }];
    NSMutableArray *states = [NSMutableArray new];
    for (InterestCategory *userCategory in userCategories) {
        [_categories enumerateObjectsUsingBlock:^(InterestCategory *categoty, NSUInteger idx, BOOL *stop) {
            if ([userCategory.remoteIdentifier isEqualToString:categoty.remoteIdentifier]) {
                [categoty setSelected:@(YES)];
                *stop = YES;
            }
        }];
    }
    
    [_categories enumerateObjectsUsingBlock:^(InterestCategory *categoty, NSUInteger idx, BOOL *stop) {
        [states addObject:@([categoty.selected boolValue])];
    }];
    _defaultState = states;
}

@end
